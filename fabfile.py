import os, time
from glob import glob
from fabric.api import *

def clean():

    if os.path.exists('chrome-app'):
        local('rm -Rf chrome-app')

def static():

    local('mkdir -p chrome-app')

    local('cp manifest.json chrome-app')
    local('cp index.html chrome-app')
    local('cp -R vendor chrome-app')
    local('cp -R res chrome-app')

def build():

    local('mkdir -p chrome-app/js')
    for f in glob('src/*.coffee'):
        coffee(f, os.path.split(f.replace('.coffee', '.js'))[1])

    local('mkdir -p chrome-app/css')
    for f in glob('styles/*.less'):
        lessc(f, os.path.split(f.replace('.less', '.css'))[1])

def chrome():

    clean()
    static()
    build()

def pack():

    chrome()

    if os.path.exists('mminds.zip'):
        local('rm mminds.zip')

    local('zip -r mminds.zip chrome-app/*')

def watch():

    globs_to_watch = [
        'manifest.json',
        'src/*.coffee',
        'styles/*.less',
    ]

    files_to_watch = []
    for g in globs_to_watch:
        files_to_watch.extend(glob(g))

    chrome()

    mtimes = {}

    for f in files_to_watch:
        mtimes[f] = os.stat(f).st_mtime

    while True:
        for f in files_to_watch:
            mt = os.stat(f).st_mtime
            if mt != mtimes[f]:
                build()
                mtimes[f] = mt

        time.sleep(.2)

def coffee(infile, outfile):
    local('coffee -p {infile} > chrome-app/js/{outfile}'.format(
        infile=infile,
        outfile=outfile
        ))

def lessc(infile, outfile):
    local('lessc {infile} > chrome-app/css/{outfile}'.format(
        infile=infile,
        outfile=outfile
        ))
