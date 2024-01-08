// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./ERC165.sol";

import "./IERC2981.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981 is ERC165, IERC2981 {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address private _royaltiesRecipient;
    uint256 private _royaltiesValue;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royaltiesRecipient = recipient;
        _royaltiesValue = value;
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address _receiver, uint256 _royaltyAmount)
    {
        return (_royaltiesRecipient, (value * _royaltiesValue) / 10000);
    }
}
