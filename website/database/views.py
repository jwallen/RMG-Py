from django.shortcuts import render_to_response

def index(request):
    """
    The homepage for RMG database viewing and editing.
    """
    return render_to_response('database.html', {})
