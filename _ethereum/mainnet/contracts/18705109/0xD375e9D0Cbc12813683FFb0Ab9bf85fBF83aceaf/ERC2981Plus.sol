// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./Ownable.sol";
import "./ERC2981.sol";

abstract contract ERC2981Plus is Ownable, ERC2981 {
    event DefaultRoyaltySet(address recipient, uint16 bps);

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    )
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function _setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    )
        internal
        override
    {
        super._setDefaultRoyalty(_receiver, _feeNumerator);
        emit DefaultRoyaltySet(_receiver, uint16(_feeNumerator));
    }
}
