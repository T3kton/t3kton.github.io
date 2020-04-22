Other Languages
---------------

These examples show the initial login and network setup.

Python
~~~~~~

You will need to be sure the cinp client is installed::

  pip3 install cinp

main.py::

  import sys
  from cinp.client import CInP

  CHOST = 'http://127.0.0.1'
  PROXY = ''
  USERNAME = 'root'
  PASSWORD = 'root'

  SITE = '/api/v1/Site/Site:site1:'
  NETWORKNAME = 'internal'  # vcenter: internal, virtual box: vboxnet0, IPMI/AMT: internal
  ADDRESSBLK = '/api/v1/Utilities/AddressBlock:1:'


  c = CInP( CHOST, '/api/v1/', PROXY )

  print( 'Login...' )
  result = c.call( '/api/v1/Auth/User(login)', { 'username': USERNAME, 'password': PASSWORD } )

  print( 'Auth Token "{0}"'.format( result ) )
  c.setAuth( USERNAME, result )

  result = c.call( '/api/v1/Auth/User(whoami)', {} )

  print( 'Logged in as "{0}"'.format( result ) )

  print( 'Create Network...' )
  obj = {
    'site': SITE,
    'name': NETWORKNAME
  }
  obj_id, result = c.create( '/api/v1/Utilities/Network', obj )
  print( result )
  network = obj_id
  print( 'Newly created network is "{0}"'.format( network ) )

  print( 'Attach AddressBlock to Network...' )
  obj = {
    'network': network,
    'address_block': ADDRESSBLK
  }
  _, result = c.create( '/api/v1/Utilities/NetworkAddressBlock', obj )
  print( result )

  print( 'Reserve Ip Addresses...' )
  for offset in ( 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ):
    obj = {
      'offset': offset,
      'address_block': ADDRESSBLK,
      'reason': 'Network Reserved'
    }
    _, result = c.create( '/api/v1/Utilities/ReservedAddress', obj )
    print( result )

  print( 'Done!' )

run::

  python3 main.py


Golang
~~~~~~

You will need go version 1.12 or better, for the module support.

With Generic Maps
^^^^^^^^^^^^^^^^^

main.go::

  package main

  import (
  	"fmt"
  	"strconv"
  	cinp "github.com/cinp/go"
  )

  const CHOST = "http://127.0.0.1"
  const PROXY = ""
  const USERNAME = "root"
  const PASSWORD = "root"

  const SITE = "/api/v1/Site/Site:site1:"
  const NETWORKNAME = "internal"  # vcenter: internal, virtual box: vboxnet0, IPMI/AMT: internal
  const ADDRESSBLK = "/api/v1/Utilities/AddressBlock:1:"

  func main() {
  	c, err := cinp.NewCInP(CHOST, "/api/v1/", PROXY)
  	if err != nil {
  		fmt.Println(err)
  		return
  	}

  	fmt.Println("Login...")
  	args := map[string]interface{}{
  		"username": USERNAME,
  		"password": PASSWORD,
  	}
  	result := ""

  	if err = c.Call("/api/v1/Auth/User(login)", &args, &result); err != nil {
  		fmt.Println(err)
  		return
  	}

  	fmt.Printf("Auth Token '%s'\n", result)
  	c.SetAuth(USERNAME, result)

  	// Print curent user, should be the same as USERNAME
  	args = map[string]interface{}{}
  	if err = c.Call("/api/v1/Auth/User(whoami)", &args, &result); err != nil {
  		fmt.Println(err)
  		return
  	}
  	fmt.Printf("Logged in as '%s'\n", result)

  	fmt.Println("Create Network...")
  	obj := &cinp.MappedObject{Data:map[string]interface{}{
  		"site": SITE,
  		"name": NETWORKNAME,
  	}}
  	if err = c.Create("/api/v1/Utilities/Network", obj); err != nil {
  		fmt.Println(err)
  		return
  	}
  	fmt.Println(obj.Data)
  	network := obj.GetID()
  	fmt.Printf("Newly created network is '%s'\n", network)

  	fmt.Println("Attach AddressBlock to Network...")
  	obj = &cinp.MappedObject{Data:map[string]interface{}{
  		"network": network,
  		"address_block": ADDRESSBLK,
  	}}
  	if err = c.Create("/api/v1/Utilities/NetworkAddressBlock", obj); err != nil {
  		fmt.Println(err)
  		return
  	}
  	fmt.Println(obj.Data)

  	fmt.Println("Reserve Ip Addresses...")
  	for _, offset := range []int{2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20} {
  		obj = &cinp.MappedObject{Data:map[string]interface{}{
  			"offset": strconv.Itoa(offset),
  			"address_block": ADDRESSBLK,
  			"reason": "Network Reserved",
  		}}
  			if err = c.Create("/api/v1/Utilities/ReservedAddress", obj); err != nil {
  			fmt.Println(err)
  			return
  		}
  		fmt.Println(obj.Data)
  	}
  	fmt.Println("Done!")
  }

build::

  go get github.com/cinp/go
  go build

run::

  ./main

With Pre-Built Service
^^^^^^^^^^^^^^^^^^^^^^

main.go::

  package main

  import (
  	"fmt"
  	contractor "github.com/t3kton/contractor_client/go"
  )

  const CHOST = "http://127.0.0.1"
  const PROXY = ""
  const USERNAME = "root"
  const PASSWORD = "root"

  const SITE = "/api/v1/Site/Site:site1:"
  const NETWORKNAME = "internal"  # vcenter: internal, virtual box: vboxnet0, IPMI/AMT: internal
  const ADDRESSBLK = "/api/v1/Utilities/AddressBlock:1:"

  func main() {
  	fmt.Println("Login...")
  	c, err := contractor.NewContractor(CHOST, PROXY, USERNAME, PASSWORD)
  	if err != nil {
  		fmt.Println(err)
  		return
  	}

  	// Print curent user, should be the same as USERNAME
  	result, err := c.AuthUserCallWhoami()
  	if err != nil {
  		fmt.Println(err)
  		return
  	}
  	fmt.Printf("Logged in as '%s'\n", result)

  	fmt.Println("Create Network...")
  	network := c.UtilitiesNetworkNew()
  	network.Site = SITE
  	network.Name = NETWORKNAME
  	err = network.Create()
  	if err != nil {
  		fmt.Println(err)
  		return
  	}
  	fmt.Println(network)
  	fmt.Printf("Newly created network is '%s'\n", network.GetID())

  	fmt.Println("Attach AddressBlock to Network...")
  	nab := c.UtilitiesNetworkAddressBlockNew()
  	nab.Network = network.GetID()
  	nab.AddressBlock = ADDRESSBLK
  	err = nab.Create()
  	if err != nil {
  		fmt.Println(err)
  		return
  	}
  	fmt.Println(nab)

  	fmt.Println("Reserve Ip Addresses...")
  	for _, offset := range []int{2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20} {
  		ra := c.UtilitiesReservedAddressNew()
  		ra.Offset = offset
  		ra.AddressBlock = ADDRESSBLK
  		ra.Reason = "Network Reserved"
  		err = ra.Create()
  		if err != nil {
  			fmt.Println(err)
  			return
  		}
  		fmt.Println(ra)
  	}
  	fmt.Println("Done!")
  }


build::

  go get github.com/t3kton/contractor_client/go
  go build

run::

  ./main
