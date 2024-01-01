// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC11554K.sol";
import "./Strings.sol";

/**
 * @dev {ERC11554KDrops} token. 4K collections are created as 4K modified ERC1155 contracts,
 * which inherit all ERC11554K functionality, extends and overrides it.
 * Special ERC11554K version for Minting Drops.
 */
contract ERC11554KDrops is ERC11554K {
    using Strings for uint256;

    /// @notice Minting drops contract address.
    address public mintingDrops;
    /// @notice If collection is vaulted.
    bool public vaulted;
    /// @notice If collection is revealed.
    bool public revealed;
    /// @notice Actual items ids to URIs ids.
    mapping(uint256 => uint256) public itemIDs;

    event Revealed(string collectionURI);
    event Vaulted();

    error InvalidSender();
    error AlreadyRevealed();
    error AlreadyVaulted();
    error NotVaulted();

    /**
     * @dev Only minting drops.
     */
    modifier onlyMintingDrops() {
        if (mintingDrops != _msgSender()) {
            revert InvalidSender();
        }
        _;
    }

    /**
     * @notice Sets item URI id.
     *
     * Requirements:
     *
     * 1) The caller must be a Minting Drops contract.
     * @param id Actual item id.
     * @param uriID Randomized URI id.
     **/
    function setItemUriID(
        uint256 id,
        uint256 uriID
    ) external virtual onlyMintingDrops {
        itemIDs[id] = uriID;
    }

    /**
     * @notice Sets collection status to vaulted.
     *
     * Requirements:
     *
     * 1) The caller must be minting drops contract
     **/
    function setVaulted() external virtual onlyMintingDrops {
        if (vaulted) {
            revert AlreadyVaulted();
        }
        vaulted = true;
        emit Vaulted();
    }

    /**
     * @notice Sets collection to revealed status.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param collectionURI_ Revealed collection URI.
     **/
    function setRevealed(
        string calldata collectionURI_
    ) external virtual onlyAdmin {
        if (revealed) {
            revert AlreadyRevealed();
        }
        _collectionURI = collectionURI_;
        revealed = true;
        emit Revealed(_collectionURI);
    }

    /**
     * @notice Sets Minting drops contract.
     *
     * Requirements:
     *
     * 1) The caller be a contract owner.
     * @param mintingDrops_ Minting Drops contract
     **/
    function setMintingDrops(address mintingDrops_) external virtual onlyAdmin {
        mintingDrops = mintingDrops_;
    }

    /**
     * @dev Burn function for controller contract.
     *
     * Requirements:
     *
     * 1) The caller must be a controller contract.
     * 2) Collection must have vaulted status.
     * @param burnAddress Address that will be burnining token(s).
     * @param tokenId Token id of the token within the collection that will be burnt.
     * @param amount Amount of token(s) that will be burnt.
     */
    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external virtual override {
        if (_msgSender() != address(controller)) {
            revert InvalidSender();
        }
        if (!vaulted) {
            revert NotVaulted();
        }
        _burn(burnAddress, tokenId, amount);
    }

    /**
     * @notice uri returns the URI for item with itemsIDs[id] (if latter is 0, then just uses id).
     * @param id Token id for which the requester will get the URI.
     * @return uri URI of the token.
     */
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        if (itemIDs[id] == 0) {
            return
                string(abi.encodePacked(_uri, id.toPaddedHexString(), ".json"));
        } else {
            return
                string(
                    abi.encodePacked(
                        _uri,
                        itemIDs[id].toPaddedHexString(),
                        ".json"
                    )
                );
        }
    }
}
