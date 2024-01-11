// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

/**
 * Simplified version of royalty standard that only supports default royalties
 * We plan to support token based royalties, but the royalties will always
 * flow through the main contract first. This is so we can support more complex
 * rev shares, as well as marketplaces such as OpenSea that don't currently support
 * the royalty standard
 */
library RoyaltyStandardLib {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    struct RoyaltyStandardStorage {
        RoyaltyInfo _defaultRoyaltyInfo;
    }

    function royaltyStandardStorage()
        internal
        pure
        returns (RoyaltyStandardStorage storage s)
    {
        bytes32 position = keccak256("royalty.standard.facet.storage");
        assembly {
            s.slot := position
        }
    }

    function royaltyInfo(uint256 _salePrice)
        internal
        view
        returns (address, uint256)
    {
        RoyaltyStandardStorage storage s = royaltyStandardStorage();

        RoyaltyInfo memory royalty = s._defaultRoyaltyInfo;

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `feeNumerator` cannot be greater than the fee denominator.
     * - receiver is always the contract address where payment splitting is implemented
     */
    function _setDefaultRoyalty(uint96 feeNumerator) internal {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );

        royaltyStandardStorage()._defaultRoyaltyInfo = RoyaltyInfo(
            address(this),
            feeNumerator
        );
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal {
        delete royaltyStandardStorage()._defaultRoyaltyInfo;
    }
}
