Web UI
======

Contractor has a web UI, served from the Contractor host.  Open `http://<contractor ip>` in
a browser and log in with the `root` user and the password you gave `setupWizard`.  Use the
site selector to pick which Site you are looking at.

The UI is for looking at what is going on.  Creating and changing things is done with
:doc:`contractorcli`, or the :doc:`api`.  The UI has pages for:

 * Home / Site graph - the Sites and what is in them
 * Foundations, Structures, Complexes and Dependencies - the details of each, their state, and the compiled configuration
 * Jobs and Job Log - the running jobs, their state and progress, and the history of what has run.  The page has refresh and auto refresh buttons
 * BluePrints, PXEs and their scripts - the blueprints, their configuration values and scripts
 * Networks, Address Blocks and Plots - the network and physical layout
 * Directory - the DNS zones and entries
 * Cartographer - the machines that have checked in from the bootstrap image
 * Todo - the Foundations that are still waiting to be built

For the steps in :doc:`tryit/index` use :doc:`contractorcli`.
