//                       .   *        .       .
//        *      -0-
//           .                .  *       - )-
//        .      *       o       .       *
//  o                |
//            .     -O-
// .                 |        *      .     -0-
//        *  o     .    '       *      .        o
//               .         .        |      *
//    *             *              -O-          .
//          .             *         |     ,
//                 .           o
//         .---.
//   =   _/__~0_\_     .  *            o       '
//  = = (_________)             .
//                  .                        *
//        *               - ) -       *
// ________/\\\\\\\\\_        __/\\\________/\\\_        __/\\\\\\\\\\\\\___        __/\\\\\\\\\\\\\\\_        ____/\\\\\\\\\_____        
//  _____/\\\////////__        _\///\\\____/\\\/__        _\/\\\/////////\\\_        _\/\\\///////////__        __/\\\///////\\\___       
//   ___/\\\/___________        ___\///\\\/\\\/____        _\/\\\_______\/\\\_        _\/\\\_____________        _\/\\\_____\/\\\___      
//    __/\\\_____________        _____\///\\\/______        _\/\\\\\\\\\\\\\\__        _\/\\\\\\\\\\\_____        _\/\\\\\\\\\\\/____     
//     _\/\\\_____________        _______\/\\\_______        _\/\\\/////////\\\_        _\/\\\///////______        _\/\\\//////\\\____    
//      _\//\\\____________        _______\/\\\_______        _\/\\\_______\/\\\_        _\/\\\_____________        _\/\\\____\//\\\___   
//       __\///\\\__________        _______\/\\\_______        _\/\\\_______\/\\\_        _\/\\\_____________        _\/\\\_____\//\\\__  
//        ____\////\\\\\\\\\_        _______\/\\\_______        _\/\\\\\\\\\\\\\/__        _\/\\\\\\\\\\\\\\\_        _\/\\\______\//\\\_ 
//         _______\/////////__        _______\///________        _\/////////////____        _\///////////////__        _\///________\///__

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

//
import "./IERC1155.sol";
import "./ERC1155URI.sol";
import "./BaseRelayRecipient.sol";

import "./ECDSA.sol";
import "./LibDiamond.sol";
import "./BaseRelayRecipientStorage.sol";
import "./LibAppStorage.sol";

contract CyberDestinationFactoryBase is BaseRelayRecipient, ERC1155URI {

  using ECDSA for bytes32;
  using Counters for Counters.Counter;

  event Minted(address indexed account, uint256 indexed tokenId, uint256 indexed amount);

  function initialize(string memory _uri, address _manager, address _trustedForwarder, address _opensea, address _oncyber) public {

    require(LibDiamond.diamondStorage().contractOwner == msg.sender, "NO");

    BaseRelayRecipientStorage.layout().trustedForwarder = _trustedForwarder;
    LibDiamond.diamondStorage().supportedInterfaces[type(IERC1155).interfaceId] = true;
    setURI(_uri);
    LibAppStorage.layout().manager = _manager;
    LibAppStorage.layout().opensea = _opensea;
    LibAppStorage.layout().oncyber = _oncyber;

  }

  function totalSupply() public view returns (uint256) {

    return LibAppStorage.layout().totalSupply.current();

  }

  function manager() public view returns (address) {

    return LibAppStorage.layout().manager;

  }

  function oncyber() public view returns (address) {

    return LibAppStorage.layout().oncyber;

  }

  function minterNonce(address _minter) public view returns (uint256){

    return LibAppStorage.layout().minterNonce[_minter].current();

  }

  function mint(string memory _uri, uint256 _amount, uint256 _amount_oncyber, bytes memory _signature) public returns (uint256 _tokenId) {

    address sender = _msgSender();
    uint256 nonce = minterNonce(sender);

    bytes memory _message = abi.encodePacked(_uri, _amount, _amount_oncyber, nonce, sender);
    address _recoveredAddress = keccak256(_message).toEthSignedMessageHash().recover(_signature);
    require(_recoveredAddress == LibAppStorage.layout().manager, "NM");
    require(_amount >= _amount_oncyber, "IAO");

    // Mint token
    _tokenId = LibAppStorage.layout().totalSupply.current();
    setTokenURI(_tokenId, _uri);
    LibAppStorage.layout().totalSupply.increment();
    LibAppStorage.layout().minterNonce[sender].increment();
    _safeMint(sender, _tokenId, _amount, "");

    if(_amount_oncyber > 0){
      _safeTransfer(sender, sender, LibAppStorage.layout().oncyber, _tokenId, _amount_oncyber, "");
    }

    emit Minted(sender, _tokenId, _amount);

    if(!isApprovedForAll(sender, LibAppStorage.layout().opensea) ){

      setApprovalForAll(LibAppStorage.layout().opensea, true);

    }

    return _tokenId;

  }

}
