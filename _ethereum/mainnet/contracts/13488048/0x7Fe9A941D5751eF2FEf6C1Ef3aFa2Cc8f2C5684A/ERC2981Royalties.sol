// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC165.sol";
import "./IERC2981.sol";
import "./ERC165.sol";

import "./ERC2981Base.sol";

abstract contract ERC2981Royalties is ERC2981Base, IERC2981, ERC165 {
    uint16 internal royalty = 500; // base 10000, 5%

    // set royalty in constructor
    constructor(uint16 _royalty) {
        royalty = _royalty;
    }

    /// @dev Support for IERC-2981, royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Calculate the royalty payment
    /// @param _salePrice the sale price of the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / BASE);
    }
}
