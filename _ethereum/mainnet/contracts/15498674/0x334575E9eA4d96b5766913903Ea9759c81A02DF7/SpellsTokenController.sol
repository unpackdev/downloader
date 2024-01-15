// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "./ERC165Storage.sol";

import "./LibDiamond.sol";
import "./ISpellsCoin.sol";
import "./ECDSA.sol";
import "./SpellsCastStorage.sol";
import "./SpellsStorage.sol";
import "./ERC721Checkpointable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./CallProtection.sol";
import "./LinearVRGDA.sol";
import { toDaysWadUnsafe } from  "./VRGDA/math/SignedWadMath.sol";
import "./ReentryProtection.sol";
import "./ERC721Checkpointable.sol";


contract SpellsTokenController is ReentryProtection, CallProtection {
    
    event GodspellUpdated(address godspell);
    
    error SenderNotGodspell();
    
    function setSpellGate(address _spellGate) external protectedCall {
        SpellsStorage.getStorage().spellGate = _spellGate;
    }

    function getSpellGate() external view returns (address) {
        return SpellsStorage.getStorage().spellGate;
    }
    
    modifier onlyGodspell() {
         if(msg.sender != SpellsStorage.getStorage().godspell) revert SenderNotGodspell();
        _;
    }
   
    /**
    * @notice Set the godspell.
    * @dev Only callable by the godspell.
    */
   function setGodsepll(address _godspell) external onlyGodspell {
       SpellsStorage.getStorage().godspell = _godspell;
       emit GodspellUpdated(_godspell);
   }

   /**
    * @dev Sets sale state to CLOSED (0), PRESALE (1), or OPEN (2).
    */
   function setSaleState(uint8 _state) external protectedCall {
       SpellsStorage.getStorage().saleState = SpellsStorage.SaleState(
           _state
       );
   }

   function getSaleState() external view returns (uint8 _state) {
       return uint8(SpellsStorage.getStorage().saleState);
   }

   function setPrice(uint256 price_) external protectedCall {
       SpellsStorage.getStorage().seedMintPrice = price_;
   }
   
}