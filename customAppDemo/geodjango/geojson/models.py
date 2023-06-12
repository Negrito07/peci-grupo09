# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.contrib.gis.db import models


class PeopleProfile(models.Model):
    password = models.CharField(max_length=128)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.BooleanField()
    username = models.CharField(unique=True, max_length=150)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=150)
    email = models.CharField(max_length=254)
    is_staff = models.BooleanField()
    is_active = models.BooleanField()
    date_joined = models.DateTimeField()
    organization = models.CharField(max_length=255, blank=True, null=True)
    profile = models.TextField(blank=True, null=True)
    position = models.CharField(max_length=255, blank=True, null=True)
    voice = models.CharField(max_length=255, blank=True, null=True)
    fax = models.CharField(max_length=255, blank=True, null=True)
    delivery = models.CharField(max_length=255, blank=True, null=True)
    city = models.CharField(max_length=255, blank=True, null=True)
    area = models.CharField(max_length=255, blank=True, null=True)
    zipcode = models.CharField(max_length=255, blank=True, null=True)
    country = models.CharField(max_length=3, blank=True, null=True)
    language = models.CharField(max_length=10)
    timezone = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'people_profile'


class AttributeCategory(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=254)

    class Meta:
        db_table = 'attribute_category'


class AttributeChoice(models.Model):
    id = models.IntegerField(primary_key=True)
    value = models.CharField(max_length=254)
    category = models.ForeignKey(AttributeCategory, related_name='category', on_delete=models.DO_NOTHING)

    class Meta:
        db_table = 'attribute_choice'


class AlgorithmExecution(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=254)
    executed_at = models.DateTimeField()
    status = models.CharField(max_length=1)
    aoi = models.PolygonField(blank=True, null=True)
    executed_by = models.ForeignKey('PeopleProfile', models.DO_NOTHING, blank=True, null=True)
    purpose = models.CharField(max_length=15)

    class Meta:
        db_table = 'algorithm_execution'


class Site(models.Model):
    id = models.AutoField(primary_key=True)
    surrounding_polygon = models.PolygonField(blank=True, null=True)
    name = models.CharField(max_length=254, blank=True, null=True)
    national_site_code = models.IntegerField(unique=True, blank=True, null=True)
    country_iso = models.CharField(max_length=2, blank=True, null=True)
    parish = models.CharField(max_length=254, blank=True, null=True)
    location = models.PointField(blank=True, null=True)
    added_by = models.ForeignKey('PeopleProfile', models.DO_NOTHING, blank=True, null=True)
    status_site = models.CharField(max_length=1, blank=True, null=True)
    created_by_execution = models.ForeignKey(AlgorithmExecution, models.DO_NOTHING, blank=True, null=True)
    # many-to-many relation field for django - not a field in the db table 
    attributes = models.ManyToManyField(AttributeChoice, through="SiteAttributeSite")

    class Meta:
        db_table = 'site'


class SiteAttributeSite(models.Model):
    id = models.AutoField(primary_key=True)
    site = models.ForeignKey(Site, on_delete=models.CASCADE, blank=True, null=True)
    attribute = models.ForeignKey(AttributeChoice, on_delete=models.CASCADE, blank=True, null=True)

    class Meta:
        db_table = 'site_attribute_site'
        unique_together = (('site', 'attribute'),)


class Occurrence(models.Model):
    id = models.AutoField(primary_key=True)
    designation = models.CharField(max_length=254, blank=True, null=True)
    acronym = models.CharField(max_length=254, blank=True, null=True)
    toponym = models.CharField(max_length=254, blank=True, null=True)
    owner = models.CharField(max_length=254, blank=True, null=True)
    altitude = models.IntegerField(blank=True, null=True)
    position = models.PointField(blank=True, null=True)
    bounding_polygon = models.PolygonField(blank=True, null=True)
    added_by = models.ForeignKey('PeopleProfile', models.DO_NOTHING, blank=True, null=True)
    site = models.ForeignKey(Site, related_name='occurrences', on_delete=models.DO_NOTHING, blank=True, null=True)
    status_occurrence = models.CharField(max_length=2, blank=True, null=True)
    algorithm_execution = models.ForeignKey(AlgorithmExecution, models.DO_NOTHING, blank=True, null=True)
    # many-to-many relation field for django - not a field in the db table 
    attributes = models.ManyToManyField(AttributeChoice, through="OccurrenceAttributeOccurrence")

    class Meta:
        db_table = 'occurrence'


class OccurrenceAttributeOccurrence(models.Model):
    id = models.AutoField(primary_key=True)
    occurrence = models.ForeignKey(Occurrence, on_delete=models.CASCADE)
    attributechoice = models.ForeignKey(AttributeChoice, on_delete=models.CASCADE)

    class Meta:
        db_table = 'occurrence_attribute_occurrence'
        unique_together = (('occurrence', 'attributechoice'),)


class MetricType(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=254, unique=True)

    class Meta:
        db_table = 'metric_type'


class Metric(models.Model):
    id = models.AutoField(primary_key=True)
    auto_value = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    confirmed_value = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    occurrence = models.ForeignKey(Occurrence, related_name='metrics', on_delete=models.CASCADE)
    type = models.ForeignKey(MetricType, related_name='type', on_delete=models.CASCADE)
    unit_measurement = models.CharField(max_length=50, blank=True, null=True)

    class Meta:
        db_table = 'metric'
    