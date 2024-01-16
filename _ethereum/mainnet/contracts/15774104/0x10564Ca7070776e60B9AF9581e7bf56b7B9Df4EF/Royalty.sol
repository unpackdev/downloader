// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 *  Magic Mynt's `Royalty` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of royalty fee and the royalty fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about royalty fees, if desired.
 *
 *  The `Royalty` contract is ERC2981 compliant.
 */

abstract contract Royalty is ERC2981Upgradeable, OwnableUpgradeable {
    function getDefaultRoyalty() public view returns (address, uint96) {
        RoyaltyInfo memory royalty = _defaultRoyaltyInfo;

        return (royalty.receiver, royalty.royaltyFraction);
    }

    function getRoyaltyForToken(uint256 tokenId)
        public
        view
        returns (address, uint96)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];
        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        return (royalty.receiver, royalty.royaltyFraction);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setRoyaltyForToken(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
}
