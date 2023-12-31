// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IRoyalty.sol";

abstract contract Royalty is IRoyalty {
    /**
     * @dev ERC2981 interface
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev Token ID => royalty recipient and bps for token
     */
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /**
     *  @notice   View royalty info for a given token and sale price.
     *  @dev      Returns royalty amount and recipient for `tokenId` and `salePrice`.
     *  @param tokenId          The tokenID of the NFT for which to query royalty info.
     *  @param salePrice        Sale price of the token.
     *
     *  @return receiver        Address of royalty recipient account.
     *  @return royaltyAmount   Royalty amount calculated at current royaltyBps value.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / 10_000;
    }

    /**
     *  @notice          View royalty info for a given token.
     *  @dev             Returns royalty recipient and bps for `_tokenId`.
     *  @param _tokenId  The tokenID of the NFT for which to query royalty info.
     */
    function getRoyaltyInfoForToken(
        uint256 _tokenId
    ) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function _setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) internal {
        if (_bps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({
            recipient: _recipient,
            bps: _bps
        });
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function _supportsRoyaltyInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        } else {
            return false;
        }
    }
}
