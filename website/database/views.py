from django.shortcuts import render_to_response
from forms import ThermoEntryForm

def index(request):
    """
    The homepage for RMG database viewing and editing.
    """
    return render_to_response('database.html', {})

def addThermoEntry(request):
    """
    The homepage for RMG database viewing and editing.
    """
    form = ThermoEntryForm()
    return render_to_response('addThermoEntry.html', {'form': form})

def addKineticsEntry(request):
    """
    The homepage for RMG database viewing and editing.
    """
    return render_to_response('addKinetics.html', {})

def addStatesEntry(request):
    """
    The homepage for RMG database viewing and editing.
    """
    return render_to_response('addStates.html', {})
