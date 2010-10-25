from django import forms

################################################################################

TEMPERATURE_UNITS = (
    ('K', 'K'),
    ('C', u'\u00B0C'),
    ('F', u'\u00B0F'),
    ('R', u'\u00B0R'),
)

PRESSURE_UNITS = (
    ('bar', 'bar'),
    ('atm', 'atm'),
    ('Pa', 'Pa'),
    ('psi', 'psi'),
    ('torr', 'torr'),
)

REFERENCE_TYPES = [
    ('theoretical', 'Theoretical'),
    ('experimental', 'Experimental'),
    ('review', 'Review'),
]

THERMODATA_TYPES = [
    ('group additivity', 'Group additivity'),
    ('wilhoit', 'Wilhoit polynomial'),
    ('nasa', 'NASA polynomial'),
]

################################################################################

class DataEntryForm(forms.Form):
    """
    Base class for a form for adding a database entry, containing common fields
    to all databases.
    """
    
    reference = forms.CharField(widget=forms.widgets.Input(attrs={'class': 'lineInput'}))
    referenceType = forms.ChoiceField(choices=REFERENCE_TYPES)
    referenceLink = forms.CharField(widget=forms.widgets.Input(attrs={'class': 'lineInput'}))
    
    shortDesc = forms.CharField(widget=forms.widgets.Input(attrs={'class': 'lineInput'}))
    longDesc = forms.CharField(widget=forms.widgets.Textarea(attrs={'class': 'textInput'}))
    
class ThermoEntryForm(DataEntryForm):
    """
    Form for adding a thermodynamics entry to the database.
    """
    
    species = forms.CharField(widget=forms.widgets.Textarea(attrs={'rows':6, 'cols':30}))
    
    dataFormat = forms.ChoiceField(choices=THERMODATA_TYPES)
    
    Tmin = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    Tmin_units = forms.ChoiceField(choices=TEMPERATURE_UNITS)
    Tmax = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    Tmax_units = forms.ChoiceField(choices=TEMPERATURE_UNITS)
    
    
    
