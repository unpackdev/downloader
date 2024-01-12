// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./ERC165.sol";

abstract contract Royalty is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint256 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _defaultRoyaltyInfo;
        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();
        return (royalty.receiver, royaltyAmount);
    }

    function _royaltyReceiver() internal view returns (address){
        return _defaultRoyaltyInfo.receiver;
    }

    function _royaltyFraction() internal view returns (uint256){
        return _defaultRoyaltyInfo.royaltyFraction;
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint256) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint256 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    // @dev CreatorCore manifold.xyz
    // Gets royalty recipient and royalty percentage for a given tokenId. Public function callable by anyone.
    function getRoyalties(uint256) view public returns (address payable[] memory, uint256[] memory) {
        //address payable[] memory receiver = new address payable[];
        address payable[] memory receiver = new address payable[](1);
        receiver[0] = payable(_royaltyReceiver());

        uint256[] memory royalty = new uint256[](1);
        royalty[0] = _royaltyFraction();

        return (receiver, royalty);
    }

    // @dev Foundation 
    //Gets royalty recipient and royalty percentage for a given tokenId. 
    // Standard interface identifier for Foundation royalties. Public function callable by anyone.
    function getFees(uint256) view external returns (address payable[] memory, uint256[] memory) {
        return getRoyalties(0);
    }

    // @dev Rarible: RoyaltiesV1
    // Gets royalty percentage (bps) for a given tokenId. 
    // Standard interface identifier for Rarible royalties. Public function callable by anyone.
    function getFeeBps(uint256) view external returns (uint256[] memory) {
        uint256[] memory royalty = new uint256[](1);
        royalty[0] = _royaltyFraction();
        return royalty;
    }

    // @dev Rarible: RoyaltiesV1
    // Gets royalty recipients for a given tokenId. 
    // Standard interface identifier for Rarible royalties. Public function callable by anyone.
    function getFeeRecipients(uint256) public view returns (address payable[] memory){
        address payable[] memory receiver = new address payable[](1);
        receiver[0] = payable(_royaltyReceiver());
        return receiver;
    }
}