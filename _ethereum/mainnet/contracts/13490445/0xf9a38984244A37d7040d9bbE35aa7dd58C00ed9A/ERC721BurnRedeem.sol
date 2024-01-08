// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ERC165Checker.sol";
import "./EnumerableSet.sol";

import "./IERC721CreatorCore.sol";

import "./ERC721RedeemBase.sol";
import "./IERC721BurnRedeem.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
contract ERC721BurnRedeem is
    ReentrancyGuard,
    ERC721RedeemBase,
    IERC721BurnRedeem
{
    //using EnumerableSet for EnumerableSet.UintSet;

    //  mapping(address => mapping(uint256 => address)) private _recoverableERC721;

    constructor(
        address creator,
        uint16 redemptionRate,
        uint16 redemptionMax
    ) ERC721RedeemBase(creator, redemptionRate, redemptionMax) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721RedeemBase, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721BurnRedeem).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721BurnRedeem-setERC721Recoverable}
     */
    function setERC721Recoverable(
        address contract_,
        uint256 tokenId,
        address recoverer
    ) external virtual override adminRequired {}

    /**
     * @dev See {IERC721BurnRedeem-recoverERC721}
     */
    function recoverERC721(address contract_, uint256 tokenId)
        external
        virtual
        override
    {}

    /**
     * @dev See {IERC721BurnRedeem-redeemERC721}
     
    function redeemERC721(
        address[] calldata contracts,
        uint256[] calldata tokenIds
    ) external virtual override nonReentrant {
        require(
            contracts.length == tokenIds.length,
            "BurnRedeem: Invalid parameters"
        );
        require(
            contracts.length == _redemptionRate,
            "BurnRedeem: Incorrect number of NFTs being redeemed"
        );

        // Attempt Burn
        for (uint256 i = 0; i < contracts.length; i++) {
            // Check that we can burn
            require(
                redeemable(contracts[i], tokenIds[i]),
                "BurnRedeem: Invalid NFT"
            );

            try IERC721(contracts[i]).ownerOf(tokenIds[i]) returns (
                address ownerOfAddress
            ) {
                require(
                    ownerOfAddress == msg.sender,
                    "BurnRedeem: Caller must own NFTs"
                );
            } catch (bytes memory) {
                revert("BurnRedeem: Bad token contract");
            }

            try IERC721(contracts[i]).getApproved(tokenIds[i]) returns (
                address approvedAddress
            ) {
                require(
                    approvedAddress == address(this),
                    "BurnRedeem: Contract must be given approval to burn NFT"
                );
            } catch (bytes memory) {
                revert("BurnRedeem: Bad token contract");
            }

            // Then burn
            try
                IERC721(contracts[i]).transferFrom(
                    msg.sender,
                    address(0xdEaD),
                    tokenIds[i]
                )
            {} catch (bytes memory) {
                revert("BurnRedeem: Burn failure");
            }
        }

        // Mint reward
        _mintRedemption(msg.sender);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override nonReentrant returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
