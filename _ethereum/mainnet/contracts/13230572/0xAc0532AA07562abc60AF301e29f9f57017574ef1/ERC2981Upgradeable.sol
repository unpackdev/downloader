// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./Initializable.sol";

import "./IERC2981Upgradeable.sol";

///
/// @dev EIP-2981: NFT Royalty Standard
///
abstract contract ERC2981Upgradeable is Initializable, ERC721Upgradeable, IERC2981Upgradeable {
    function __ERC2981_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC2981_init_unchained();
    }

    // solhint-disable-next-line no-empty-blocks
    function __ERC2981_init_unchained() internal initializer {}

    // Address of who should be sent the royalty payment
    address private _royaltyReceiver;

    // Share of the sale price owed as royalty to the receiver, expressed as BPS (1/10,000)
    uint256 private _royaltyBps;

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param - the NFT asset queried for royalty information
     * @param salePrice_ - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice_ * _royaltyBps) / 10000;
    }

    /**
     * @dev A method to update royalty information.
     * @param receiver_ - the address of who should be sent the royalty payment
     * @param royaltyBps_ - the share of the sale price owed as royalty to the receiver, expressed as BPS (1/10,000)
     */
    function _setRoyaltyInfo(address receiver_, uint256 royaltyBps_) internal virtual {
        _royaltyReceiver = receiver_;
        _royaltyBps = royaltyBps_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return interfaceId == type(ERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    uint256[48] private __gap;
}
