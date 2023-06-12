from django.urls import path
from .views import *

urlpatterns = [
    path('sites', SitesGeoJSON.as_view(), name='sites'),
    path('site/<int:pk>', SiteRetrieveUpdateDelete.as_view()),
    path('occurrences/<int:site>', OccurrencesGeoJSON.as_view(), name='occurrences'),
    path('occurrence/<int:pk>', OccurrenceRetrieveUpdateDelete.as_view()),
    path('attributechoices', AttributeChoicesList.as_view(), name='attributechoices'),
    path('metrictypes', MetricTypesList.as_view(), name='metrictypes'),
]
