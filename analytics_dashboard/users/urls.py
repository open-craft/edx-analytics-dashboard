# pylint: disable=no-value-for-parameter

from django.conf.urls import url, patterns

from users import views

urlpatterns = patterns(
    '',
    url(r'^(?P<username>[^/]+)/$', views.UserProfileView.as_view(), name='profile'),
)
