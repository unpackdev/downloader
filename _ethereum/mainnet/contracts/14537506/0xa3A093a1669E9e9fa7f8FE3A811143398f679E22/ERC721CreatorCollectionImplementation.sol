// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz


import "./IERC165.sol";
import "./ERC165Checker.sol";
import "./IERC721CreatorCore.sol";
import "./AdminControlUpgradeable.sol";
import "./IERC721CreatorExtensionApproveTransfer.sol";

import "./ERC721CreatorCollectionBase.sol";

/**
 * ERC721 Creator Collection Drop Contract Implementation
 */
contract ERC721CreatorCollectionImplementation is ERC721CreatorCollectionBase, IERC721CreatorExtensionApproveTransfer, AdminControlUpgradeable {

    /**
     * Initializer
     */
    function initialize(address creator, uint16 purchaseMax_, uint256 purchasePrice_, uint16 purchaseLimit_, uint16 transactionLimit_, uint256 presalePurchasePrice_, uint16 presalePurchaseLimit_, address signingAddress, bool useDynamicPresalePurchaseLimit_) public initializer {
        __Ownable_init();
        _initialize(creator, purchaseMax_, purchasePrice_, purchaseLimit_, transactionLimit_, presalePurchasePrice_, presalePurchaseLimit_, signingAddress, useDynamicPresalePurchaseLimit_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorCollectionBase, IERC165, AdminControlUpgradeable) returns (bool) {
      return ERC721CreatorCollectionBase.supportsInterface(interfaceId)
        || AdminControlUpgradeable.supportsInterface(interfaceId)
        || interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId;
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        _premint(addresses);
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     * @dev See {IERC1155CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "creator must implement IERC721CreatorCore");
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-approveTransfer}.
     */
    function approveTransfer(address from, address, uint256) external override returns (bool) {
        return _validateTokenTransferability(from);
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }
}


