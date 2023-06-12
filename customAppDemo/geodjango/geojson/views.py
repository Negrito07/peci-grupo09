from django.shortcuts import render

# Create your views here.
from rest_framework import generics, mixins
from .models import Site, Occurrence, AttributeChoice, MetricType
from .serializers import SiteSerializer, OccurrenceSerializer, AttributeChoiceSerializer, MetricTypeSerializer

class SitesGeoJSON(generics.ListCreateAPIView):
    queryset = Site.objects.all()
    serializer_class = SiteSerializer

class SiteRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Site.objects.all()
    serializer_class = SiteSerializer

class OccurrencesGeoJSON(generics.ListCreateAPIView):
    queryset = Occurrence.objects.all()
    serializer_class = OccurrenceSerializer

    def get_queryset(self):
        return super().get_queryset().filter(site=self.kwargs['site'])

class OccurrenceRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Occurrence.objects.all()
    serializer_class = OccurrenceSerializer

class AttributeChoicesList(generics.ListAPIView):
    queryset = AttributeChoice.objects.all()
    serializer_class = AttributeChoiceSerializer

class MetricTypesList(generics.ListAPIView):
    queryset = MetricType.objects.all()
    serializer_class = MetricTypeSerializer

    

