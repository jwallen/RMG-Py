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

ENERGY_UNITS = (
    ('kJ/mol', 'kJ/mol'),
    ('kcal/mol', 'kcal/mol'),
    ('J/mol', 'J/mol'),
    ('cal/mol', 'cal/mol'),
    ('cm^-1', 'cm^-1'),

)

HEAT_CAPACITY_UNITS = (
    ('J/mol*K', 'J/mol*K'),
    ('cal/mol*K', 'cal/mol*K'),
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
    
class ThermoDataForm(forms.Form):
    
    Tlist = forms.CharField(widget=forms.widgets.Textarea(attrs={'rows':8, 'cols':10}))
    T_units = forms.ChoiceField(choices=TEMPERATURE_UNITS)
    Cplist = forms.CharField(widget=forms.widgets.Textarea(attrs={'rows':8, 'cols':10}))
    Cp_units = forms.ChoiceField(choices=HEAT_CAPACITY_UNITS)
    
    H298 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    H298_units = forms.ChoiceField(choices=ENERGY_UNITS)
    S298 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    S298_units = forms.ChoiceField(choices=HEAT_CAPACITY_UNITS)
    
class WilhoitForm(forms.Form):
    
    Cp0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    Cp0_units = forms.ChoiceField(choices=HEAT_CAPACITY_UNITS)
    CpInf = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    CpInf_units = forms.ChoiceField(choices=HEAT_CAPACITY_UNITS)

    a0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    a1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    a2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    a3 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    
    B = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    B_units = forms.ChoiceField(choices=TEMPERATURE_UNITS)
    
    H0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    H0_units = forms.ChoiceField(choices=ENERGY_UNITS)
    S0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    S0_units = forms.ChoiceField(choices=HEAT_CAPACITY_UNITS)

class NASAForm(forms.Form):
    
    nasa_numPolys = forms.ChoiceField(choices=[('1','1'), ('2','2'), ('3','3')])

    nasa_am2_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_am1_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a0_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a1_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a2_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a3_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a4_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a5_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a6_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmin_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmax_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    
    nasa_am2_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_am1_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a0_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a1_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a2_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a3_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a4_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a5_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a6_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmin_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmax_1 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    
    nasa_am2_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_am1_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a0_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a1_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a2_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a3_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a4_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a5_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a6_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmin_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmax_2 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    
    nasa_Tmin_units = forms.ChoiceField(choices=TEMPERATURE_UNITS)
    nasa_Tmax_units = forms.ChoiceField(choices=TEMPERATURE_UNITS)
    