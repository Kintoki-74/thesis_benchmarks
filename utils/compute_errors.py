#!/usr/bin/env python

import numpy
import sys
import clawpack.pyclaw.solution as solution
import clawpack.pyclaw.controller as controller

# Compute error norm for and maximum
def compute_error(q, qref, n, name):
    # TODO: Check if this is working as expected
    error = numpy.linalg.norm(q - qref, ord=n)
    maxdiff = numpy.max(numpy.absolute(q-qref))
    
    return [error, maxdiff]

if __name__ == '__main__':
    print "Comparison of \"" + sys.argv[1] + "\" and \"" + sys.argv[2] + "\""

    outdir = "/_output/"
    # Load reference solution and test solution
    n = numpy.infty# n-norm

    # Lists to store errors (p-norm) and absolute difference, for h, hu, hv
    errors = [[],[],[]]

    tbegin = 0
    tend = 19

    print "### Computing error ({:f}-norm) and maximum difference for time step {:d} to {:d} ###".format(n, tbegin, tend)
    for t in xrange(tbegin,tend):
        ref = solution.Solution(t, path=sys.argv[1] + outdir, read_aux=False)
        sol = solution.Solution(t, path=sys.argv[2] + outdir, read_aux=False)
#        print "=== Test solution stats for timestep {:d} ===".format(t)
#        print "Number of cells: " + str(ref.q.shape[0])
#        print "Number of cells (x-dir): " + str(ref.q.shape[1])
#        print "Number of cells (y-dir): " + str(ref.q.shape[2])

        # Format: h = h(x, t)
        h     = sol.q[0, ...]
        href  = ref.q[0, ...]
        hu    = sol.q[1, ...]
        huref = ref.q[1, ...]
        hv    = sol.q[2, ...]
        hvref = ref.q[2, ...]
        
        #if (t==7):
        #    print h
        errors[0].append(compute_error(h,  href,  n, "h"))
        errors[1].append(compute_error(hu, huref, n, "hu"))
        errors[2].append(compute_error(hv, hvref, n, "hv"))

    # STATS
    for q in errors:
        maxima = [(max(a)) for a in zip(*q)]
        print "===> Stats for ???TODO???:" # Add h, hu, hv
        print "  Maximum {:f}-norm found:              {:e}".format(n, maxima[0])
        print "  Maximum absolute difference found: {:e}".format(maxima[1])
    
