VirtualBox Setup
----------------

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/3Wbl_XWer0k" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

You will first need to shutdown the contractor VM.

Bring up the `VirtualBox Manager`, under `File` select `Host Network Manager`.
Click `Create`.  Select the newly created network and click the `Propterties` button.
Change the Ipv4 Address to `10.0.0.1`.  Make sure the DHCP Server is disabled.
Take note of the name, if it is the only network there it will be named `vboxnet0`.
Now close the `Host Network Manager`.

Now select the VM that has contractor in it, and click the `Settings` button.
Select `Network`, then `Adapter 2`.  Select `Enable Network Adapter`, by the
`Attached To` select `Host-only Adapter` and by `Name` pick the name of the
network just created in `Host Network Manager`.  Click 'Ok'.

Power the VM back up.

configure the new interface with the ip address `10.0.0.10`.

In the `/etc/subcontractor.conf` file under the `dhcpd` section, set
the `listen_interface` to the name of the newly created interface.

Normally vboxwebservice will expect the username and password of the user you
are using to run virtualbox.  If you want to disable auth so you do not need
to put your password in the virtualbox config, run this::

  vboxmanage setproperty websrvauthlibrary null

windows::

  vboxmanage.exe setproperty websrvauthlibrary null

Now we need to start the VirtualBox Web Service so subcontractor can talk to it.
If you specified an Ipv4 address other than 10.0.0.1 when setting up the Host
Network you update this command to refelect that change.  On the machine you are
running virtualbox run (if you are using linux)::

  vboxwebsrv -H 10.0.0.1

windows::

  vboxwebsrv.exe -H 10.0.0.1

Now you will need to install python3-zeep::

  sudo apt install -y python3-zeep

return to :ref:`contractor/tryit/installing:setup`
