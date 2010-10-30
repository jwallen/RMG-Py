from django.conf.urls.defaults import *
from django.conf import settings
import os

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Example:
    # (r'^website/', include('website.foo.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # (r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    (r'^admin/', include(admin.site.urls)),

    # Account management
    (r'^accounts/login/$', 'django.contrib.auth.views.login', {'template_name': 'login.html'}),
    (r'^accounts/logout/$', 'django.contrib.auth.views.logout', {'template_name': 'logout.html'}),

    # The RMG website homepage
    (r'^$', 'website.main.views.index'),

    # The RMG database homepage
    (r'^database/$', 'website.database.views.index'),
    
    # Adding entries to the various depositories
    (r'^database/thermo/depository/addEntry.html$', 'website.database.views.addThermoEntry'),
    (r'^database/kinetics/depository/addEntry.html$', 'website.database.views.addKineticsEntry'),
    (r'^database/states/depository/addEntry.html$', 'website.database.views.addStatesEntry'),
    
    # Viewing entries in various depositories
    (r'^database/thermo/depository/(\d)/$', 'website.database.views.viewThermoEntry'),
    
)

# When developing in Django we generally don't have a web server available to
# serve static media; this code enables serving of static media by Django
# DO NOT USE in a production environment!
if settings.DEBUG:
    urlpatterns += patterns('',
        (r'^media/(.*)$', 'django.views.static.serve',
            {'document_root': os.path.join(settings.PROJECT_PATH, 'media'),
             'show_indexes': True, }
        ),
    )
