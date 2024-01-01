// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************\
 .    . . . . . . .... .. ...................... . . . .  .   .+
   ..  .   . .. . ............................ ... ....  . .. .+
 .   .  .. .. ....... ..;@@@@@@@@@@@@@@@@@@@;........ ... .  . +
  .   .  .. ...........X 8@8X8X8X8X8X8X8X8X@ 8  ....... .. .. .+
.  .. . . ... ... .:..% 8 88@ 888888888888@%..8  .:...... . .  +
 .  . ... . ........:t:88888888@88888@8@888 ;  @......... .. ..+
.  . . . ........::.% 8 888@888888X888888  .   88:;:.:....... .+
.   . .. . .....:.:; 88888888@8888888@88      S.88:.:........ .+
 . . .. .......:.:;88 @8@8@888888@@88888.   .888 88;.:..:..... +
.  .. .......:..:; 8888888888888@88888X :  :Xt8 8 :S:.:........+
 .  .......:..:.;:8 8888888%8888888888 :. .888 8 88:;::::..... +
 . .. .......:::tS8@8888888@88%88888X ;. .@.S 8  %:  8:..:.....+
. .........:..::8888@S888S8888888888 ;. :88SS 8t8.    @::......+
 . . .....:.::.8@ 88 @88 @8 88@ 88 @::  8.8 8 8@     88:.:.....v
. . .......:.:;t8 :8 8 88.8 8:8.:8 t8..88 8 8 @ 8   88;::.:....+
.. .......:.:::;.%8 @ 8 @ .8:@.8 ;8;8t8:X@ 8:8X    88t::::.....+
. .. ......:..:::t88 8 8 8 t8 %88 88.@8 @ 888 X 8 XX;::::.::...+
..........:::::::;:X:8 :8 8 ;8.8.8 @ :88 8:@ @   8X;::::::.:...+
  . .......:.:::::; 8 8.:8 8 t8:8 8 8.;88 XX  8 88t;:::::......+
.. .......:.:.:::::; @:8.;8 8.t8 8 tt8.%8@. 8  88t;:;::::.:....+
 ... ....:.:.:.::;::; 8:8 ;8 8 t8 8:8 8.t8S. 888;;:;::::.:..:..+
.  ........::::::::;:;.t 8 ;8 8 ;88:;8.8 ;88 88S:::::::.:.:....+
 .. .. .....:.:.:::::;; 888X8S8 X@XSSS88 888X:t;;;::::::.:.....+
 .. ........:..:::::;::;%;:   .t. ;ttS:;t. .  :;;:;:::.::......+
 . . ......:.:..::::::;;;t;;:;;;;;;;;t;;;;;:: :;:;:::.:........+
/***************************************************************/

import "./LibDiamond.sol";
import "./LibUpdates.sol";
import "./Strings.sol";

/**
 * @title UpdateFacet
 * @dev This contract allows to store token updates logs on chain. We will differentiate two types of updates - standard
 * and layered.
 *
 * NOTE: Update functions are protected by modifiers to allow execution only for admin or token holders.
 */

contract UpdateFacet is Modifiers {

  uint8 public constant STANDARD_UPDATE = 1;
  uint8 public constant LAYERED_UPDATE = 2;  

  /**
   * @dev emits `Update` event with given parameters.
   * `sender`, `contractAddress` and `updateType` are indexed to allow on chain filtering
   */
  event Update(address indexed sender, address indexed contractAddress, uint8 indexed updateType, string updateId, string collectionId, string tokenOrGroupId);

  /**
  * @dev Emits `Update` event to store update log.
  * It takes:
  * - `collectionId` and `tokenId` to  identify specific token data within CAKE
  * - `updateId` to identify update data
  * - `updateType` to keep information which typo of update was performed
  */
  function emitUpdate(address from, string memory updateId, string memory collectionId, string memory tokenOrGroupId, uint8 updateType) internal {
    emit Update(from, address(this), updateType, updateId, collectionId, tokenOrGroupId);
  }

  /**
  * @dev Triggers standard update with given params
  * available only for cake admin
  */
  function standardUpdate(address from, string memory updateId, string memory collectionId, string memory groupId) external onlyOwner() {
    emitUpdate(from, updateId, collectionId, groupId, STANDARD_UPDATE);
  }

/**
  * @dev Triggers layered update with given params
  * available only for cake admin
  */
  function layeredUpdate(address from, string memory updateId, string memory collectionId, uint256 tokenId, bytes calldata signature, bytes32 messageHash) external {
    address CAKE_WALLET = 0x29c6a598a3447F69ff52b9b96dadf630750886FD;
    LibUpdates.Layout storage layout = LibUpdates.layout();
    bytes32 _message = LibUpdates.getMessageHash(updateId, collectionId, Strings.toString(tokenId), LAYERED_UPDATE);
    
    require( _message == messageHash, 'invalid update parameters.');
    require(LibUpdates.verify(CAKE_WALLET, updateId, collectionId, Strings.toString(tokenId), LAYERED_UPDATE, signature) == true, 'signature not verified.');
    require(bytes(LibUpdates.checkTokenIdOwnership(from, tokenId)).length == 0, 'not token owner');
    require(layout.claimedSignatures[messageHash] == 0, 'update already claimed.');

    layout.claimedSignatures[messageHash] = 1;
    emitUpdate(from, updateId, collectionId, Strings.toString(tokenId), LAYERED_UPDATE);
  }
}