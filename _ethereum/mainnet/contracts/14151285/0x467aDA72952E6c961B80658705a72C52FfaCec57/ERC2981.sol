//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./IERC2981.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981 is ERC165, IERC2981 {

    uint256 private _royalties;
    address private _recipient;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, "ERC2981: Too high");
        _royalties = value;
        _recipient = recipient;
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _recipient;
        royaltyAmount = (value * _royalties) / 10000;
    }
}
