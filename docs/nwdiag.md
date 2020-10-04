# test nwdiag

## L4 network diagram 


```nwdiag
nwdiag {
  network dmz {
      address = "210.x.x.x/24"

      web01 [address = "210.x.x.1"];
      web02 [address = "210.x.x.2"];
  }
  network internal {
      address = "172.x.x.x/24";

      web01 [address = "172.x.x.1"];
      web02 [address = "172.x.x.2"];
      db01;
      db02;
  }
}
```


## Rack diagram

```nwdiag
rackdiag {
  // define height of rack
  16U;

  // define rack items
  1: UPS [2U];
  3: DB Server
  4: Web Server 1  // put 2 units to rack-level 4
  4: Web Server 2
  5: Web Server 3
  5: Web Server 4
  7: Load Balancer
  8: L3 Switch
}
```

## Block Diag

```nwdiag
blockdiag {
  // branching edges to multiple children
  A -> B, C;

  // branching edges from multiple parents
  D, E -> F;
}
```


## Blockdiag complex

```nwdiag
blockdiag admin {
  index [label = "List of FOOs"];
  add [label = "Add FOO"];
  add_confirm [label = "Add FOO (confirm)"];
  edit [label = "Edit FOO"];
  edit_confirm [label = "Edit FOO (confirm)"];
  show [label = "Show FOO"];
  delete_confirm [label = "Delete FOO (confirm)"];

  index -> add  -> add_confirm  -> index;
  index -> edit -> edit_confirm -> index;
  index -> show -> index;
  index -> delete_confirm -> index;
}
```

## Sequence diagram

```diag
seqdiag {
  browser  -> webserver [label = "GET /index.html"];
  browser <-- webserver;
  browser  -> webserver [label = "POST /blog/comment"];
              webserver  -> database [label = "INSERT comment"];
              webserver <-- database;
  browser <-- webserver;
}
```


## activity diagram

```diag
actdiag {
  write -> convert -> image

  lane user {
     label = "User"
     write [label = "Writing reST"];
     image [label = "Get diagram IMAGE"];
  }
  lane actdiag {
     convert [label = "Convert reST to Image"];
  }
}
```


