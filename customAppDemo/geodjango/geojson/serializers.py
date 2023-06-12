from .models import Site, Occurrence, Metric, MetricType, AttributeCategory, AttributeChoice, OccurrenceAttributeOccurrence, SiteAttributeSite
from rest_framework_gis.serializers import GeoFeatureModelSerializer
from rest_framework import serializers


class AttributeCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = AttributeCategory
        fields = [
            'id',
            'name'
        ]


class AttributeChoiceSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField()
    category = serializers.SlugRelatedField(
        slug_field = 'name',
        read_only = True,
    )
    value = serializers.CharField(
        read_only = True,
    )

    class Meta:
        model = AttributeChoice
        fields = [
            'id',
            'category',
            'value'
        ]


class MetricTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = MetricType
        fields = [
            'id',
            'name'
        ]


class MetricSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(
        required=False,
        allow_null=True
    )
    type = serializers.SlugRelatedField(
        slug_field = 'name',
        queryset = MetricType.objects.all()
    )

    class Meta:
        model = Metric
        fields = [
            'id',
            'type',
            'auto_value',
            'confirmed_value',
            'unit_measurement'
        ]


class OccurrenceSerializer(GeoFeatureModelSerializer):
    metrics = MetricSerializer(
        many = True,
        required = False,
    )
    attributes = AttributeChoiceSerializer(
        many = True,
        required = False,
    )

    class Meta:
        model = Occurrence
        geo_field = 'bounding_polygon'
        fields = [
            'id',
            'designation',
            'acronym',
            'toponym',
            'owner',
            'altitude',
            'position',
            'added_by',
            'site',
            'metrics',
            'attributes',
            'status_occurrence',
            'algorithm_execution'
        ]

    def create(self, validated_data):
        metrics_data = validated_data.pop('metrics', [])
        attributes_data = validated_data.pop('attributes', [])
        occurrence = Occurrence.objects.create(**validated_data)
        
        for metric_data in metrics_data:
            print(f"Creating new metric using metric_data: {metric_data}\n")
            # create new metric with the given metric_data
            Metric.objects.create(occurrence=occurrence, **metric_data)
        
        for attribute_data in attributes_data:
            attr_id = attribute_data.get("id")  # id is a required field (AttributeChoiceSerializer)
            # check if the given attribute choice id corresponds to a valid attribute choice
            if AttributeChoice.objects.filter(id=attr_id).exists():
                print(f"Selecting new attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")
                # get the selected attribute choice
                attributechoice = AttributeChoice.objects.get(id=attr_id)
                # add the selected attribute choice to this occurrence 
                occurrence.attributes.add(attributechoice)
            else:
                print(f"Ignoring invalid attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")

        return occurrence
    
    def update(self, instance, validated_data):
        metrics_data = validated_data.pop("metrics", [])
        attributes_data = validated_data.pop('attributes', [])
        instance = super().update(instance, validated_data)

        print(attributes_data)

        # Update each child instance or Create new ones
        metric_ids_given = []
        for metric_data in metrics_data:
            # check if a metric id was given
            metric_id = metric_data.get("id")
            if metric_id:
                # check if the given metric id corresponds to a metric from this occurrence
                if (instance.metrics).filter(id=metric_id).exists():    
                    print(f"Updating metric with id={metric_id} using metric_data: {metric_data}\n")
                    # update existent metric with the given metric_data
                    metric = (instance.metrics).get(id=metric_data.get("id"))
                    metric_serializer = MetricSerializer(metric, data=metric_data, partial=True)
                    metric_serializer = metric_serializer.update(metric, metric_data)
                    # remember this id
                    metric_ids_given.append(metric_id)
                else:
                    print(f"Ignoring metric with invalid id={metric_id} and metric_data: {metric_data}\n")
                    continue
            else:
                print(f"Creating new metric using metric_data: {metric_data}\n")
                # create new metric with the given metric_data
                metric = Metric.objects.create(occurrence=instance, **metric_data)
                # remember this id
                metric_ids_given.append(metric.id)
        
        attr_ids_given = []
        for attribute_data in attributes_data:
            attr_id = attribute_data.get("id")  # id is a required field (AttributeChoiceSerializer)
            # check if the given id does not correspond to an attribute choice already related to this occurrence
            if not (instance.attributes).filter(id=attr_id).exists():
                # check if the given id corresponds to a valid attribute choice
                if AttributeChoice.objects.filter(id=attr_id).exists():
                    print(f"Selecting new attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")
                    # get the selected attribute choice
                    attributechoice = AttributeChoice.objects.get(id=attr_id)
                    # add the selected attribute choice to this occurrence 
                    instance.attributes.add(attributechoice)
                    # remember this id
                    attr_ids_given.append(attr_id)
                else:
                    print(f"Ignoring invalid attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")
                    continue
            else:
                print(f"Detected already selected attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")
                # remember this id
                attr_ids_given.append(attr_id)
            
        # Delete unmentioned existent metrics
        metric_ids_to_delete = [metric.id for metric in (instance.metrics).all() if metric.id not in metric_ids_given]

        print(f"Deleting metrics with ids={metric_ids_to_delete}\n")
        instance.metrics.filter(id__in=metric_ids_to_delete).delete()

        # Remove unmentioned attribute choices
        attr_ids_to_remove = []     # only used for verbose execution
        for attribute_choice in (instance.attributes).all():
            if attribute_choice.id not in attr_ids_given:
                instance.attributes.remove(attribute_choice)
                attr_ids_to_remove.append(attribute_choice.id)

        print(f"Removing attribute choices with ids={attr_ids_to_remove}\n")

        return instance


class SiteSerializer(GeoFeatureModelSerializer):
    attributes = AttributeChoiceSerializer(
        many = True,
        required = False,
    )
    
    class Meta:
        model = Site
        geo_field = 'surrounding_polygon'
        fields = [
            'id',
            'name',
            'national_site_code',
            'country_iso',
            'parish',
            'location',
            'added_by',
            'status_site',
            'attributes',
            'created_by_execution',
        ]
    
    def create(self, validated_data):
        attributes_data = validated_data.pop('attributes', [])
        site = Site.objects.create(**validated_data)
        
        for attribute_data in attributes_data:
            attr_id = attribute_data.get("id")  # id is a required field (AttributeChoiceSerializer)
            # check if the given attribute choice id corresponds to a valid attribute choice
            if AttributeChoice.objects.filter(id=attr_id).exists():
                # get the selected attribute choice
                attribute = AttributeChoice.objects.get(id=attr_id)
                # add the selected attribute choice to this site
                site.attributes.add(attribute)

        return site
    
    def update(self, instance, validated_data):
        attributes_data = validated_data.pop('attributes', [])
        instance = super().update(instance, validated_data)

        # Update each child instance or Create new ones
        attr_ids_given = []
        for attribute_data in attributes_data:
            attr_id = attribute_data.get("id")  # id is a required field (AttributeChoiceSerializer)
            # check if the given id does not correspond to an attribute choice already related to this occurrence
            if not (instance.attributes).filter(id=attr_id).exists():
                # check if the given id corresponds to a valid attribute choice
                if AttributeChoice.objects.filter(id=attr_id).exists():
                    print(f"Selecting new attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")

                    # get the selected attribute choice
                    attribute = AttributeChoice.objects.get(id=attr_id)
                    # add the selected attribute choice to this site
                    instance.attributes.add(attribute)
                    # remember this id
                    attr_ids_given.append(attr_id)
                else:
                    print(f"Ignoring invalid attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")
                    continue
            else:
                # remember this id
                attr_ids_given.append(attr_id)
                print(f"Detected already selected attribute choice with id={attr_id} in attribute_data: {attribute_data}\n")
        
        # Remove unmentioned attribute choices
        attr_ids_to_remove = []     # only used for verbose execution
        for attribute_choice in (instance.attributes).all():
            if attribute_choice.id not in attr_ids_given:
                instance.attributes.remove(attribute_choice)
                attr_ids_to_remove.append(attribute_choice.id)

        print(f"Removing attribute choices with ids={attr_ids_to_remove}\n")

        return instance
