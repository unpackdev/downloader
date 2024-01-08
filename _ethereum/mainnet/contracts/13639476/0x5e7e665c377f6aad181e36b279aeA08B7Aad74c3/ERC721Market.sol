// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

import "./AddressUpgradeable.sol";
import "./ERC721Upgradeable.sol";

import "./IMarket.sol";
import "./IGetRoyalties.sol";
import "./IHasSecondarySaleFees.sol";

import "./TreasuryNode.sol";

/**
 * @notice Holds a reference to the Foundation Market and communicates fees to 3rd party marketplaces.
 */
abstract contract ERC721Market is TreasuryNode, IHasSecondarySaleFees, ERC721Upgradeable {
    using AddressUpgradeable for address;

    event NFTMarketUpdated(address indexed nftMarket);

    IMarket private nftMarket;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        if (interfaceId == type(IGetRoyalties).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the address of the Foundation NFTMarket contract.
     */
    function getNFTMarket() public view returns (address) {
        return address(nftMarket);
    }

    function _updateNFTMarket(address _nftMarket) internal {
        require(_nftMarket.isContract(), "NFT721Market: Market address is not a contract");
        nftMarket = IMarket(_nftMarket);

        emit NFTMarketUpdated(_nftMarket);
    }

    /**
     * @notice Returns an array of recipient addresses to which fees should be sent.
     * The expected fee amount is communicated with `getFeeBps`.
     */
    function getFeeRecipients(uint256 id) public view override returns (address payable[] memory) {
        address payable[] memory result = new address payable[](2);
        result[0] = getTreasury();
        result[1] = getTokenCreatorPaymentAddress();
        return result;
    }

    /**
     * @notice Returns an array of fees in basis points.
     * The expected recipients is communicated with `getFeeRecipients`.
     */
    function getFeeBps(uint256 id) public view override returns (uint256[] memory) {
        (uint256 secondaryFakturaFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
        uint256[] memory result = new uint256[](2);
        result[0] = secondaryFakturaFeeBasisPoints;
        result[1] = secondaryCreatorFeeBasisPoints;
        return result;
    }

    /**
     * @notice Get fee recipients and fees in a single call.
     * The data is the same as when calling getFeeRecipients and getFeeBps separately.
     */
    function getRoyalties()
    public
    view
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints)
    {
        recipients = new address payable[](2);
        recipients[0] = getTreasury();
        recipients[1] = getTokenCreatorPaymentAddress();
        (uint256 secondaryFakturaFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
        feesInBasisPoints = new uint256[](2);
        feesInBasisPoints[0] = secondaryFakturaFeeBasisPoints;
        feesInBasisPoints[1] = secondaryCreatorFeeBasisPoints;
    }
        uint256[46] private __gap;
}