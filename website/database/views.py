import os.path
import datetime

from django.http import HttpResponseRedirect
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.contrib.auth.decorators import login_required

import settings
from forms import *

from chempy.thermo import ThermoGAModel, WilhoitModel, NASAPolynomial, NASAModel
from rmgdata.thermo import ThermoEntry, ThermoDatabase

################################################################################

thermoDatabase = ThermoDatabase(path=os.path.join(settings.DATABASE_PATH, 'thermo'))

################################################################################

def index(request):
    """
    The homepage for RMG database viewing and editing.
    """
    return render_to_response('database.html', {}, context_instance=RequestContext(request))

#@login_required
def addThermoEntry(request):
    """
    The homepage for RMG database viewing and editing.
    """
    if request.method == 'POST':
        form = ThermoEntryForm(request.POST, error_class=DivErrorList)
        thermoDataForm = ThermoDataForm(request.POST, error_class=DivErrorList)
        wilhoitForm = WilhoitForm(request.POST, error_class=DivErrorList)
        nasaForm = NASAForm(request.POST, error_class=DivErrorList)
        
        thermoData = None
        
        if form.is_valid():
            molecule = Molecule()
            molecule.fromAdjacencyList(form.cleaned_data['species'])
            Tmin = form.cleaned_data['Tmin']
            Tmax = form.cleaned_data['Tmax']
            reference = form.cleaned_data['reference']
            referenceLink = form.cleaned_data['referenceLink']
            referenceType = form.cleaned_data['referenceType']
            shortDesc = form.cleaned_data['shortDesc']
            longDesc = form.cleaned_data['longDesc']
            
            if form.data['dataFormat'] == 'group additivity' and thermoDataForm.is_valid():
                thermoData = ThermoGAModel(
                    Tdata = thermoDataForm.cleaned_data['Tlist'], 
                    Cpdata = thermoDataForm.cleaned_data['Cplist'], 
                    H298 = thermoDataForm.cleaned_data['H298'], 
                    S298 = thermoDataForm.cleaned_data['S298'], 
                    Tmin = Tmin, 
                    Tmax = Tmax,
                )
                    
            elif form.data['dataFormat'] == 'wilhoit' and wilhoitForm.is_valid():
                thermoData = WilhoitModel(
                    cp0 = wilhoitForm.cleaned_data['Cp0'], 
                    cpInf = wilhoitForm.cleaned_data['CpInf'], 
                    a0 = wilhoitForm.cleaned_data['a0'], 
                    a1 = wilhoitForm.cleaned_data['a1'], 
                    a2 = wilhoitForm.cleaned_data['a2'], 
                    a3 = wilhoitForm.cleaned_data['a3'], 
                    H0 = wilhoitForm.cleaned_data['H0'], 
                    S0 = wilhoitForm.cleaned_data['S0'], 
                    B = wilhoitForm.cleaned_data['B'],
                )
                thermoData.Tmin = Tmin
                thermoData.Tmax = Tmax
                
            elif form.data['dataFormat'] == 'nasa' and nasaForm.is_valid():
                numPolys = int(nasaForm.cleaned_data['nasa_numPolys'])
                thermoData = NASAModel(Tmin=Tmin, Tmax=Tmax)
                for i in range(3):
                    if i < numPolys:
                        poly = NASAPolynomial(
                            coeffs = [
                                nasaForm.cleaned_data['nasa_am2_%i' % i], 
                                nasaForm.cleaned_data['nasa_am1_%i' % i], 
                                nasaForm.cleaned_data['nasa_a0_%i' % i], 
                                nasaForm.cleaned_data['nasa_a1_%i' % i], 
                                nasaForm.cleaned_data['nasa_a2_%i' % i], 
                                nasaForm.cleaned_data['nasa_a3_%i' % i], 
                                nasaForm.cleaned_data['nasa_a4_%i' % i], 
                                nasaForm.cleaned_data['nasa_a5_%i' % i], 
                                nasaForm.cleaned_data['nasa_a6_%i' % i], 
                            ],
                            Tmin=nasaForm.cleaned_data['nasa_Tmin_%i' % i], 
                            Tmax=nasaForm.cleaned_data['nasa_Tmax_%i' % i],
                        )
                        thermoData.polynomials.append(poly)
        
            if thermoData is not None:
                thermoEntry = ThermoEntry(
                    molecule=form.cleaned_data['species'],
                    data=thermoData, 
                    reference=reference, 
                    referenceLink=referenceLink, 
                    referenceType=referenceType, 
                    shortDesc=shortDesc, 
                    longDesc=longDesc,
                    history=[(datetime.datetime.today(),'user','Added to database.')],
                )
                print repr(thermoData)
                
                thermoDatabase.depository.add(thermoEntry)
                thermoDatabase.depository.save(thermoEntry)
                
                print 'Form is valid!!!!'
        #       return HttpResponseRedirect('/database/')
    else:
        form = ThermoEntryForm(error_class=DivErrorList)
        thermoDataForm = ThermoDataForm(error_class=DivErrorList)
        wilhoitForm = WilhoitForm(error_class=DivErrorList)
        nasaForm = NASAForm(error_class=DivErrorList)
    
    return render_to_response('addThermoEntry.html', 
        {'form': form, 'thermoDataForm': thermoDataForm, 'wilhoitForm': wilhoitForm, 'nasaForm': nasaForm},
        context_instance=RequestContext(request))

def addKineticsEntry(request):
    """
    The homepage for RMG database viewing and editing.
    """
    return render_to_response('addKinetics.html', {}, context_instance=RequestContext(request))

def addStatesEntry(request):
    """
    The homepage for RMG database viewing and editing.
    """
    return render_to_response('addStates.html', {}, context_instance=RequestContext(request))
