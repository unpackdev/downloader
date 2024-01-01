// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************\
 .    . . . . . . .... .. ...................... . . . .  .   .+
   ..  .   . .. . ............................ ... ....  . .. .+
 .   .  .. .. ....... ..;@@@@@@@@@@@@@@@@@@@;........ ... .  . +
  .   .  .. ...........X 8@8X8X8X8X8X8X8X8X@ 8  ....... .. .. .+
.  .. . . ... ... .:..% 8 88@ 888888888888@%..8  .:...... . .  +
 .  . ... . ........:t:88888888@88888@8@888 ;  @......... .. ..+
.  . . . ........::.% 8 888@888888X888888  .   88:;:.:....... .+
.   . .. . .....:.:; 88888888@8888888@88      S.88:.:........ .+
 . . .. .......:.:;88 @8@8@888888@@88888.   .888 88;.:..:..... +
.  .. .......:..:; 8888888888888@88888X :  :Xt8 8 :S:.:........+
 .  .......:..:.;:8 8888888%8888888888 :. .888 8 88:;::::..... +
 . .. .......:::tS8@8888888@88%88888X ;. .@.S 8  %:  8:..:.....+
. .........:..::8888@S888S8888888888 ;. :88SS 8t8.    @::......+
 . . .....:.::.8@ 88 @88 @8 88@ 88 @::  8.8 8 8@     88:.:.....v
. . .......:.:;t8 :8 8 88.8 8:8.:8 t8..88 8 8 @ 8   88;::.:....+
.. .......:.:::;.%8 @ 8 @ .8:@.8 ;8;8t8:X@ 8:8X    88t::::.....+
. .. ......:..:::t88 8 8 8 t8 %88 88.@8 @ 888 X 8 XX;::::.::...+
..........:::::::;:X:8 :8 8 ;8.8.8 @ :88 8:@ @   8X;::::::.:...+
  . .......:.:::::; 8 8.:8 8 t8:8 8 8.;88 XX  8 88t;:::::......+
.. .......:.:.:::::; @:8.;8 8.t8 8 tt8.%8@. 8  88t;:;::::.:....+
 ... ....:.:.:.::;::; 8:8 ;8 8 t8 8:8 8.t8S. 888;;:;::::.:..:..+
.  ........::::::::;:;.t 8 ;8 8 ;88:;8.8 ;88 88S:::::::.:.:....+
 .. .. .....:.:.:::::;; 888X8S8 X@XSSS88 888X:t;;;::::::.:.....+
 .. ........:..:::::;::;%;:   .t. ;ttS:;t. .  :;;:;:::.::......+
 . . ......:.:..::::::;;;t;;:;;;;;;;;t;;;;;:: :;:;:::.:........+
/***************************************************************/

import "./LibDiamond.sol";
import "./LibSignature.sol";

library LibUpdates {
  
  bytes32 constant STORAGE_SLOT = keccak256("diamond.standard.diamond.updates");      

  struct Layout {    
    mapping(bytes32 => uint256) claimedSignatures;
  }            

  function layout() internal pure returns (Layout storage l) {
    bytes32 position = STORAGE_SLOT;
    assembly {
      l.slot := position
    }
  }

  function getMessageHash(
    string memory updateId, 
    string memory collectionId, 
    string memory id,
    uint8 updateType
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(updateId, collectionId, id, updateType));
  }

  function getEthSignedMessageHash(
    bytes32 _messageHash
  ) internal pure returns (bytes32) {
    /*
    Signature is produced by signing a keccak256 hash with the following format:
    "\x19Ethereum Signed Message\n" + len(msg) + msg
    */
    return
      keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
      );
    }
  
  function verify(
    address _signer,
    string memory updateId, 
    string memory collectionId, 
    string memory id,
    uint8 updateType,
    bytes memory signature
  ) internal returns (bool) {    
    bytes32 messageHash = getMessageHash(updateId, collectionId, id, updateType);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);     
    return LibSignature.recoverSigner(ethSignedMessageHash, signature) == _signer;
  }

  function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
    assembly {
      addr := mload(add(bys,32))
    } 
  }

  function checkTokenIdOwnership(address owner, uint256 tokenId) internal returns (string memory){
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    bytes4 functionSelector = bytes4(keccak256("ownerOf(uint256)"));        
    LibDiamond.FacetAddressAndSelectorPosition  memory facet = ds.facetAddressAndSelectorPosition[functionSelector];     
    bytes memory functionCall = abi.encodeWithSelector(functionSelector, tokenId);    
    (bool success, bytes memory result) = address(facet.facetAddress).delegatecall(functionCall);
    require(success == true, "function failed");     
    require(bytesToAddress(result) == owner, "not token owner"); 
    return '';
  }

}