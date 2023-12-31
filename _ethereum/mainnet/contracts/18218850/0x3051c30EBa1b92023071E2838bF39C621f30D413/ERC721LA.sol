// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Burnable.sol";
import "./WithOperatorRegistry.sol";
import "./AirDropable.sol";
import "./IERC721LA.sol";
import "./Pausable.sol";
import "./Whitelistable.sol";
// import "./PermissionedTransfers.sol";
import "./LAInitializable.sol";
import "./LANFTUtils.sol";
import "./BPS.sol";
import "./CustomErrors.sol";
import "./RoyaltiesState.sol";
import "./ERC721State.sol";
import "./ERC721LACore.sol";

/**
 * @notice LiveArt ERC721 implementation contract
 * Supports multiple edtioned NFTs and gas optimized batch minting
 */
contract ERC721LA is ERC721LACore, Burnable, AirDropable, Whitelistable {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            Royalties
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function setRoyaltyRegistryAddress(
        address _royaltyRegistry
    ) public onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
    }

    function royaltyRegistryAddress() public view returns (IRoyaltiesRegistry) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._royaltyRegistry;
    }

    /// @dev see: EIP-2981
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            state._royaltyRegistry.royaltyInfo(address(this), _tokenId, _value);
    }

    function registerCollectionRoyaltyReceivers(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        IRoyaltiesRegistry(state._royaltyRegistry)
            .registerCollectionRoyaltyReceivers(
                address(this),
                msg.sender,
                royaltyReceivers
            );
    }

    function primaryRoyaltyInfo(
        uint256 tokenId
    ) public view returns (address payable[] memory, uint256[] memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).primaryRoyaltyInfo(
                address(this),
                tokenId
            );
    }
}
