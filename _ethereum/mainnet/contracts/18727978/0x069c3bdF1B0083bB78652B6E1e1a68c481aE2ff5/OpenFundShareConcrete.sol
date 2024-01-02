// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./EarnConcrete.sol";
import "./SFTValueIssuableConcrete.sol";
import "./IOpenFundShareConcrete.sol";

error BurnNotAllowed();

contract OpenFundShareConcrete is IOpenFundShareConcrete, EarnConcrete, SFTValueIssuableConcrete {
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
    function _burn(uint256 tokenId_, uint256 burnValue_) internal virtual override {
        uint256 slot = IERC3525Upgradeable(delegate()).slotOf(tokenId_);
        SlotExtInfo storage slotExtInfo = _slotExtInfos[slot];
        if (slotExtInfo.isInterestRateSet) {
            revert BurnNotAllowed();
        }

        if (burnValue_ > 0) {
            uint256 tokenBalance = IERC3525Upgradeable(delegate()).balanceOf(tokenId_);
            uint256 burnTokenInitialValue = burnValue_ * _tokenRepayInfo[tokenId_].initialValue / tokenBalance;
            _tokenRepayInfo[tokenId_].initialValue -= burnTokenInitialValue;

            _slotRepayInfo[slot].initialValue -= burnTokenInitialValue;
            _slotRepayInfo[slot].totalValue -= burnValue_;
        }
    }

    function _beforeMint(uint256 /** tokenId_ */, uint256 /** slot_ */, uint256 /** mintValue_ */) internal virtual override {
    }

}