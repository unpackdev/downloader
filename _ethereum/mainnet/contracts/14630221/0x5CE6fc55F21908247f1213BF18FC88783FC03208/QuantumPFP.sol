// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/*

                                                                                       .'',,,,,,,,,,,,,,,,,,,,,,,''.
                                                                                     ,lxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc.
                                                      .,...........''. .,'...'.     ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.
                                                      ;o:,;,;;;;:;.;:  ,ll,.;c.     ;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo'
                                                      .''..''....'...  .''. ..      .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;
                                                                                     .':cccccllllcclllllcclccccccc:;.


                                       ..''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...
                                   .':ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdoc;.
                                  ,oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.
                                .:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.
                                ;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.
                               .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd'
                               .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo'
                                ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:.
                                 ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.
                                  .cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl,.
                                    .;clodddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlc;'.
                                        ......................................................................


                     ..',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,'..
                  .;codxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdoc;.
                'cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc'
              .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.
             'oxxxxxxxxxxxolc::cloxxxxxdllodxxxdolldxxxxxollldxxxxxxdllloxxxxxxdolloxdlllllllloddllldxxxxollodxxdllldxxxxdllldxxxxxxxxxo'
            'oxxxxxxxxxd:'.      .'cdxx;  .lxxxl.  ;xxxxl.   .lxxxxxc.  .:dxxxxl.  ;d;.       .lc. .:xxxd,  .lxx;   'oxxd,.  ,dxxxxxxxxxo'
           .cxxxxxxxxxo'   .,;;,.   ,od,  .cxxxc.  ,xxxo'     'dxxxx:.    .;lxxl.  ,dl:;.   ':cdc.  ;xxxd,  .lxo.    ;dx:    .lxxxxxxxxxxc.
           .oxxxxxxxxd;   ,dxxxxo'   ;d,  .cxxxl.  ,xxd,  .,.  ;dxxx:       .;ol.  ,dxxx,  .cxxxc.  ;xxxd,  .lxc.     :c.     ;xxxxxxxxxxo.
           .oxxxxxxxxd'  .cxxdood:   ,d,  .cxxxl.  ,xx:.  :d;  .cxxx:   ;:.   .,.  ,dxxx,  .cxxxc.  ;xxxd,  .lx;  .'.  .  '.  'dxxxxxxxxxo.
           .lxxxxxxxxx:   .coc'...   :x;   :xxx:   ;xc.   .'.   .lxx:   :xoc,      ,dxxx,  .cxxxc.  'dxxo.  .oo.  ,o,    ,o;  .lxxxxxxxxxl.
            ;xxxxxxxxxd:.   ...     ;dxl.  .','.  .lo.  .'''''.  'ox:   :xxxdc.    ,dxxx,  .cxxxd,   .,,.   ;dc.  :xo'  'oxc.  :xxxxxxxxx;
            .:xxxxxxxxxxo:'........ 'lxxo;.......;oxc'..cxxxxxc..'cxl'.'lxxxxxo;...:xxxx:..,oxxxxd:'......,cdxc..'lxxl,,lxxo,..:dxxxxxxx:.
             .:dxxxxxxxxxxxdoooodxocloxxxxxdooodxxxxxddxxxxxxxxdddxxxxddxxxxxxxxxddxxxxxxddxxxxxxxxxdoooodxxxxxddxxxxxxxxxxxxddxxxxxxxd:.
               'ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl'
                 ':oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'
                   .';:lloddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddooc:;'.
                         ....................................................................................................


                                     ..,;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;;,'.
                                   .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc,.
                                 .cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl'
                                .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,
                                :xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.
                               .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd'
                               .:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo.
                                'oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;
                                 .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;
                                  .,ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.
                                     .,;ccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc:;'.


                                   ..''''''''''''''''''''''''...
                                .,ldxxxxxxxxxxxxxxxxxxxxxxxxxxdo;.
                                ;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:.   ',.','..,..'...
                               .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.   ';.;l;,::.,:;:,
                                'oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,    .. ......... ..
                                 .;cllllllllllllllllllllllllllc;.    */

import "./ERC721Upgradeable.sol";
import "./Ownable.sol";
import "./ERC165.sol";
import "./Namehash.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract ENS {
    function resolver(bytes32 node) public virtual view returns (Resolver);
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) virtual external;
}

abstract contract Resolver {
    function addr(bytes32 node) public virtual view returns (address);
    function text(bytes32 node, string calldata key) virtual external view returns (string memory);
    function setText(bytes32 node, string calldata key, string calldata value) virtual external;
    function setAddr(bytes32 node, address a) virtual external;
}

contract QuantumPFP is Initializable, UUPSUpgradeable, ERC721Upgradeable, OwnableUpgradeable, Namehash {
  string public _baseURI_;
  string public constant baseDomain = "quantum.tech";
  string terminatedURI;
  uint historicalEmployeeCount;

  enum Designations {
    Unknown,
    Mr,
    Ms,
    Agent,
    Trainee,
    Specialist
  }

  string[6] public designationNames;
  struct Employee {
    string specialty;
    Designations designation;
    string initial;
    string email;
    bool terminated;
  }

  mapping(uint => Employee) public EmployeeList;
  // Same address for Mainet, Ropsten, Rinkerby, Gorli and other networks;
  // ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
  ENS public ens;

  function initialize(string memory __baseURI, string memory _terminatedURI, address ensRegistrar) initializer public {
    __ERC721_init('Quantum Team', 'QT');
    __Ownable_init();
    __UUPSUpgradeable_init();
    _baseURI_ = __baseURI;
    terminatedURI = _terminatedURI;
    ens = ENS(ensRegistrar);
    designationNames = ["Unknown", "Mr", "Ms", "Agent", "Trainee", "Specialist"];
  }
  //proxy requirement
  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}

  function ENSResolve(bytes32 node) public view returns(address) {
      Resolver resolver = ens.resolver(node);
      return resolver.addr(node);
  }

  function initialToENS(string memory _initial) public view returns(address){
    bytes32 toResolve = computeNamehash(abi.encodePacked(_initial, ".", baseDomain));
    return ENSResolve(toResolve);
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseURI_;
  }

  function addEmployee(string memory _initial, address targetAddress, string memory email, Designations designation, string memory specialty) external onlyOwner {

    EmployeeList[historicalEmployeeCount] = Employee(specialty, designation, _initial, email, false);

    bytes32 rootNodeId = computeNamehash(abi.encodePacked(baseDomain));
    Resolver rootResolver = ens.resolver(rootNodeId);
    ens.setSubnodeRecord(computeNamehash(abi.encodePacked(baseDomain)), keccak256(abi.encodePacked(_initial)), address(this), address(rootResolver), 0);

    bytes32 nodeId = computeNamehash(abi.encodePacked(_initial,  ".", baseDomain));
    Resolver resolver = ens.resolver(nodeId);

    resolver.setAddr(nodeId, targetAddress);

    resolver.setText(nodeId, "email", email);
    resolver.setText(nodeId, "designation", designationNames[uint256(designation)]);
    resolver.setText(nodeId, "specialty", specialty);
    resolver.setText(nodeId, "status", "okay");

    _mint(targetAddress, historicalEmployeeCount);
    historicalEmployeeCount += 1;
  }

  function terminateAccess(uint tokenId) external onlyOwner {
    EmployeeList[tokenId].terminated = true;
    bytes32 nodeId = computeNamehash(abi.encodePacked(EmployeeList[tokenId].initial,  ".", baseDomain));
    Resolver resolver = ens.resolver(nodeId);
    resolver.setText(nodeId, "status", "terminated");
  }

  function restoreAccess(uint tokenId) external onlyOwner  {
    EmployeeList[tokenId].terminated = false;
    bytes32 nodeId = computeNamehash(abi.encodePacked(EmployeeList[tokenId].initial,  ".", baseDomain));
    Resolver resolver = ens.resolver(nodeId);
    resolver.setText(nodeId, "status", "okay");
  }

  function changeDesignation(uint tokenId, Designations designation) external onlyOwner  {
    require(_exists(tokenId) && !EmployeeList[tokenId].terminated, "invalid employee");

    bytes32 nodeId = computeNamehash(abi.encodePacked(EmployeeList[tokenId].initial,  ".", baseDomain));
    Resolver resolver = ens.resolver(nodeId);
    resolver.setText(nodeId, "designation", designationNames[uint(designation)]);

    EmployeeList[tokenId].designation = designation;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(!EmployeeList[tokenId].terminated) {
      string memory baseURI = _baseURI();
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uint2str(tokenId))) : "";
    } else {
      return terminatedURI;
    }
  }


  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) public override onlyOwner {
    _transfer(from, to, tokenId);
  }

 function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory
  ) public override  onlyOwner {
    _transfer(from, to, tokenId);
  }

  function setBaseURI(string memory _newURI) public onlyOwner {
    _baseURI_ = _newURI;
  }
  function setTerminatedURI(string memory _newURI) public onlyOwner {
    terminatedURI = _newURI;
  }


  function burn(uint256 tokenId) public onlyOwner {
    ens.setSubnodeRecord(computeNamehash(abi.encodePacked(baseDomain)), keccak256(abi.encodePacked(EmployeeList[tokenId].initial)), address(0), address(0), 0);
    delete EmployeeList[tokenId];
    _burn(tokenId);
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}
