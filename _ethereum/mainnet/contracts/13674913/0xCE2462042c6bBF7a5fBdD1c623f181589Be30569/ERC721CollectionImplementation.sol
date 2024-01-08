// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControlUpgradeable.sol";

import "./ERC721CollectionBase.sol";

/**
 * ERC721 Collection Drop Contract Implementation
 */
contract ERC721CollectionImplementation is ERC721CollectionBase, AdminControlUpgradeable {

    /**
     * Initializer
     */
    function initialize(address creator, uint16 tokenMax_, uint256 tokenPrice_, uint16 purchaseLimit_, uint16 presalePurchaseLimit_, address signingAddress) public initializer {
        __Ownable_init();
        tokenMax = tokenMax_;
        tokenPrice = tokenPrice_;
        purchaseLimit = purchaseLimit_;
        presalePurchaseLimit = presalePurchaseLimit_;
        _initialize(creator, signingAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CollectionBase, AdminControlUpgradeable) returns (bool) {
      return ERC721CollectionBase.supportsInterface(interfaceId) || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
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
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }
}


