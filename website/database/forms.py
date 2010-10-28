from django import forms
from django.forms.util import ErrorList
from django.utils.safestring import mark_safe

import chempy.constants as constants
from chempy.molecule import Molecule

################################################################################

TEMPERATURE_UNITS = (
    ('K', 'K'),
    ('C', u'\u00B0C'),
    ('F', u'\u00B0F'),
    ('R', u'\u00B0R'),
)

def convertTemperature(value, units):
    if units == 'K':   return value
    elif units == 'C': return value + 273.15
    elif units == 'F': return (value + 459.67) / 1.8
    elif units == 'R': return value / 1.8

PRESSURE_UNITS = (
    ('bar', 'bar'),
    ('atm', 'atm'),
    ('Pa', 'Pa'),
    ('psi', 'psi'),
    ('torr', 'torr'),
)

def convertPressure(value, units):
    if units == 'bar':    return value * 1.0e5
    elif units == 'atm':  return value * 101325.
    elif units == 'Pa':   return value
    elif units == 'psi':  return value * 6894.757
    elif units == 'torr': return value * 101325. / 760.0

ENERGY_UNITS = (
    ('kJ/mol', 'kJ/mol'),
    ('kcal/mol', 'kcal/mol'),
    ('J/mol', 'J/mol'),
    ('cal/mol', 'cal/mol'),
    ('cm^-1', 'cm^-1'),

)

def convertEnergy(value, units):
    if units == 'kJ/mol':     return value * 1000.
    elif units == 'kcal/mol': return value * 4184.
    elif units == 'J/mol':    return value
    elif units == 'cal/mol':  return value * 4.184
    elif units == 'cm^-1':    return value * constants.c * 100. * constants.h * constants.Na

HEAT_CAPACITY_UNITS = (
    ('J/mol*K', 'J/mol*K'),
    ('cal/mol*K', 'cal/mol*K'),
)

def convertHeatCapacity(value, units):
    if units == 'J/mol*K':     return value
    elif units == 'cal/mol*K': return value * 4.184

REFERENCE_TYPES = [
    ('',''),
    ('theoretical', 'Theoretical'),
    ('experimental', 'Experimental'),
    ('review', 'Review'),
]

THERMODATA_TYPES = [
    ('',''),
    ('group additivity', 'Group additivity'),
    ('wilhoit', 'Wilhoit polynomial'),
    ('nasa', 'NASA polynomial'),
]

################################################################################

class DivErrorList(ErrorList):
    def __unicode__(self):
        return self.as_divs()
    def as_divs(self):
        if not self: return u''
        return mark_safe(u'<label>&nbsp;</label>%s' % (''.join([u'<div class="error">%s</div>' % e for e in self])))
        #return u'<div class="errorlist">%s</div>' % ''.join([u'<div class="error">%s</div>' % e for e in self])

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
    
    def clean(self):
        """
        Custom form validation that requires access to multiple fields.
        """
        if self.data['dataFormat'] in ['group additivity', 'wilhoit']:
            # Make sure minimum temperature is below maximum temperature
            if 'Tmin' in self.cleaned_data and 'Tmax' in self.cleaned_data and self.cleaned_data['Tmin'] > self.cleaned_data['Tmax']:
                self._errors['Tmin'] = self.error_class([u'The minimum temperature is greater than the maximum temperature.'])
            
        return DataEntryForm.clean(self)
    
    def clean_species(self):
        """
        Custom validation for the species field to ensure that a valid adjacency 
        list has been provided.
        """
        try:
            molecule = Molecule()
            molecule.fromAdjacencyList(str(self.cleaned_data['species']))
        except Exception, e:
            import traceback
            traceback.print_exc(e)
            raise forms.ValidationError('Invalid adjacency list.')
        return str(self.cleaned_data['species'])
    
    def clean_Tmin(self):
        """
        Custom processing for the minimum temperature field; converts the value
        to have units of K.
        """
        return convertTemperature(self.cleaned_data['Tmin'], self.data['Tmin_units'])
    
    def clean_Tmax(self):
        """
        Custom processing for the maximum temperature field; converts the value
        to have units of K.
        """
        return convertTemperature(self.cleaned_data['Tmax'], self.data['Tmax_units'])
        
class ThermoDataForm(forms.Form):
    
    Tlist = forms.CharField(widget=forms.widgets.Textarea(attrs={'rows':8, 'cols':10}))
    T_units = forms.ChoiceField(choices=TEMPERATURE_UNITS)
    Cplist = forms.CharField(widget=forms.widgets.Textarea(attrs={'rows':8, 'cols':10}))
    Cp_units = forms.ChoiceField(choices=HEAT_CAPACITY_UNITS)
    
    H298 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    H298_units = forms.ChoiceField(choices=ENERGY_UNITS)
    S298 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    S298_units = forms.ChoiceField(choices=HEAT_CAPACITY_UNITS)
    
    def clean(self):
        """
        Custom form validation that requires access to multiple fields.
        """
        # Make sure we've given the same number of temperature points as heat capacity points
        if 'Tlist' in self.cleaned_data and 'Cplist' in self.cleaned_data and len(self.cleaned_data['Tlist']) != len(self.cleaned_data['Cplist']):
            self._errors['Cplist'] = self.error_class([u'Number of temperatures does not match number of heat capacities.'])
        return self.cleaned_data
    
    def clean_Tlist(self):
        """
        Manual processing and validation of the Tlist field. Converts to a list of
        floats, assuming the field contains one value per line.
        """
        try:
            Tlist = [float(T.strip()) for T in self.cleaned_data['Tlist'].split()]
            Tlist = [convertTemperature(T, self.data['T_units']) for T in Tlist]
        except ValueError:
            raise forms.ValidationError('One or more invalid entries in temperature list.')
        return Tlist
        
    def clean_Cplist(self):
        """
        Manual processing and validation of the Cplist field. Converts to a list of
        floats, assuming the field contains one value per line.
        """
        try:
            Cplist = [float(T.strip()) for T in self.cleaned_data['Cplist'].split()]
            Cplist = [convertHeatCapacity(Cp, self.data['Cp_units']) for Cp in Cplist]
        except ValueError:
            raise forms.ValidationError('One or more invalid entries in heat capacity list.')
        return Cplist
   
    def clean_H298(self):
        return convertEnergy(self.cleaned_data['H298'], self.data['H298_units'])
    
    def clean_S298(self):
        return convertHeatCapacity(self.cleaned_data['S298'], self.data['S298_units'])
    
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

    def clean_Cp0(self):
        return convertHeatCapacity(self.cleaned_data['Cp0'], self.data['Cp0_units'])
    
    def clean_CpInf(self):
        return convertHeatCapacity(self.cleaned_data['CpInf'], self.data['CpInf_units'])
    
    def clean_H0(self):
        return convertEnergy(self.cleaned_data['H0'], self.data['H0_units'])
    
    def clean_S0(self):
        return convertHeatCapacity(self.cleaned_data['S0'], self.data['S0_units'])
    
    def clean_B(self):
        return convertTemperature(self.cleaned_data['B'], self.data['B_units'])

class NASAForm(forms.Form):
    
    nasa_numPolys = forms.ChoiceField(choices=[('1','1'), ('2','2'), ('3','3')])

    nasa_am2_0 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_am1_0 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a0_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a1_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a2_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a3_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a4_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a5_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a6_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmin_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmax_0 = forms.FloatField(widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    
    nasa_am2_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_am1_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a0_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a1_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a2_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a3_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a4_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a5_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a6_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmin_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmax_1 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    
    nasa_am2_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_am1_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a0_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a1_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a2_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a3_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a4_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a5_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_a6_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmin_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    nasa_Tmax_2 = forms.FloatField(required=False, widget=forms.widgets.Input(attrs={'class': 'numberInput'}))
    
    nasa_Tmin_units = forms.ChoiceField(required=False, choices=TEMPERATURE_UNITS)
    nasa_Tmax_units = forms.ChoiceField(required=False, choices=TEMPERATURE_UNITS)
    
    def clean(self):
        """
        Custom form validation that requires access to multiple fields.
        """
        numPolys = self.cleaned_data['nasa_numPolys']
        if numPolys > 2:
            for field in ['nasa_a0_2', 'nasa_a1_2', 'nasa_a2_2', 'nasa_a3_2', 'nasa_a4_2', 'nasa_a5_2', 'nasa_a6_2', 'nasa_Tmin_2', 'nasa_Tmax_2']:
                if self.cleaned_data[field] is None:
                    self._errors[field] = self.error_class([u'This field is required.'])
        if numPolys > 1:
            for field in ['nasa_a0_1', 'nasa_a1_1', 'nasa_a2_1', 'nasa_a3_1', 'nasa_a4_1', 'nasa_a5_1', 'nasa_a6_1', 'nasa_Tmin_1', 'nasa_Tmax_1']:
                if self.cleaned_data[field] is None:
                    self._errors[field] = self.error_class([u'This field is required.'])
        if numPolys > 0:
            for field in ['nasa_a0_0', 'nasa_a1_0', 'nasa_a2_0', 'nasa_a3_0', 'nasa_a4_0', 'nasa_a5_0', 'nasa_a6_0', 'nasa_Tmin_0', 'nasa_Tmax_0']:
                if self.cleaned_data[field] is None:
                    self._errors[field] = self.error_class([u'This field is required.'])
        return self.cleaned_data
    
    def clean_nasa_numPolys(self):
        return int(self.data['nasa_numPolys'])
    
    def clean_nasa_am2_0(self):
        return self.cleaned_data['nasa_am2_0'] if self.cleaned_data['nasa_am2_0'] else 0.

    def clean_nasa_am1_0(self):
        return self.cleaned_data['nasa_am1_0'] if self.cleaned_data['nasa_am1_0'] else 0.
    
    def clean_nasa_am2_1(self):
        return self.cleaned_data['nasa_am2_1'] if self.cleaned_data['nasa_am2_1'] else 0.
    
    def clean_nasa_am1_1(self):
        return self.cleaned_data['nasa_am1_1'] if self.cleaned_data['nasa_am1_1'] else 0.
    
    def clean_nasa_am2_2(self):
        return self.cleaned_data['nasa_am2_2'] if self.cleaned_data['nasa_am2_2'] else 0.
    
    def clean_nasa_am1_2(self):
        return self.cleaned_data['nasa_am1_2'] if self.cleaned_data['nasa_am1_2'] else 0.
    
    def clean_nasa_Tmin_0(self):
        return convertTemperature(self.cleaned_data['nasa_Tmin_0'], self.data['nasa_Tmin_units'])
        
    def clean_nasa_Tmax_0(self):
        return convertTemperature(self.cleaned_data['nasa_Tmax_0'], self.data['nasa_Tmax_units'])
        
    def clean_nasa_Tmin_1(self):
        return convertTemperature(self.cleaned_data['nasa_Tmin_1'], self.data['nasa_Tmin_units'])
        
    def clean_nasa_Tmax_1(self):
        return convertTemperature(self.cleaned_data['nasa_Tmax_1'], self.data['nasa_Tmax_units'])
        
    def clean_nasa_Tmin_2(self):
        return convertTemperature(self.cleaned_data['nasa_Tmin_2'], self.data['nasa_Tmin_units'])
        
    def clean_nasa_Tmax_2(self):
        return convertTemperature(self.cleaned_data['nasa_Tmax_2'], self.data['nasa_Tmax_units'])
