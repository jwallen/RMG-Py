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

def viewThermoEntry(request, index):
    entry = ThermoEntry(
        index=1,
        molecule="""methane\n1 C 0""",
        #data=WilhoitModel(1, 2, 3, 4, 5, 6, 7000, 8, 9, 1000), 
        #data=ThermoGAModel(Tdata=[300,400,500,600,800,1000,1500], Cpdata=[1, 2, 3, 4, 5, 6, 7], H298=1000, S298=20), 
        data=NASAModel(polynomials=[NASAPolynomial(Tmin=300, Tmax=1000, coeffs=[1, 2, 3, 4, 5, 6, 7]), NASAPolynomial(Tmin=1000, Tmax=2000, coeffs=[1, 2, 3, 4, 5, 6, 7, 8, 9])]), 
        reference="""n/a""", 
        referenceLink='n/a', 
        referenceType='n/a', 
        shortDesc='n/a', 
        longDesc="""n/a""",
        comments=[(datetime.datetime.today(),'jwallen','This entry is only a test. The data it contains is made up. **Do not use** this data for anything except making sure your thermo data viewer is pretty. This data will self-destruct in ten seconds.')],
        history=[
            (datetime.datetime.today(),'user','jwallen added this entry to the thermodynamics depository.'),
            (datetime.datetime.today(),'user','jwallen commented on this entry.'),
        ],
    )
    form = ThermoEvalForm()
    entry.data.Tmin = 300; entry.data.Tmax = 2000
    parameters = {'form': form, 'entry': entry, 'type': ''}
    if isinstance(entry.data, ThermoGAModel):
        parameters['format'] = 'Group additivity'
        parameters['Cpdata'] = zip(entry.data.Tdata, entry.data.Cpdata)
        parameters['H298'] = entry.data.H298 / 1000.
        parameters['S298'] = entry.data.S298
    elif isinstance(entry.data, WilhoitModel):
        parameters['format'] = 'Wilhoit polynomial'
        parameters['Cp0'] = entry.data.cp0
        parameters['CpInf'] = entry.data.cpInf
        parameters['a0'] = entry.data.a0
        parameters['a1'] = entry.data.a1
        parameters['a2'] = entry.data.a2
        parameters['a3'] = entry.data.a3
        parameters['B'] = entry.data.B
        parameters['H0'] = entry.data.H0 / 1000.
        parameters['S0'] = entry.data.S0
    elif isinstance(entry.data, NASAModel):
        parameters['format'] = 'NASA polynomials'
        parameters['polynomials'] = entry.data.polynomials
        
    parameters['Tmin'] = entry.data.Tmin
    parameters['Tmax'] = entry.data.Tmax
    return render_to_response('viewThermoEntry.html', parameters, context_instance=RequestContext(request))

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
