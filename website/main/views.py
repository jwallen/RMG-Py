from django.shortcuts import render_to_response

def index(request):
    """
    The RMG website homepage.
    """
    return render_to_response('index.html', {})
