// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./AdminManagerUpgradable.sol";
import "./IERC721A.sol";

contract TomoTransformationUpgradeable is
    Initializable,
    AdminManagerUpgradable,
    PausableUpgradeable
{
    IERC721A internal tomoToken;
    IERC721A internal shounenToken;
    address tomoVault;
    address shounenVault;

    function initialize(
        IERC721A tomoToken_,
        IERC721A shounenToken_,
        address tomoVault_,
        address shounenVault_
    ) public initializer {
        __AdminManager_init_unchained();
        __Pausable_init_unchained();
        tomoToken = tomoToken_;
        shounenToken = shounenToken_;
        tomoVault = tomoVault_;
        shounenVault = shounenVault_;
    }

    function transform(uint256[] calldata tokenIds_) external whenNotPaused {
        for (uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            require(tomoToken.ownerOf(tokenId) == msg.sender, "Not owner");
            tomoToken.safeTransferFrom(msg.sender, tomoVault, tokenId);
            shounenToken.safeTransferFrom(shounenVault, msg.sender, tokenId);
        }
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setTomoToken(IERC721A tomoToken_) external onlyAdmin {
        tomoToken = tomoToken_;
    }

    function setShounenToken(IERC721A shounenToken_) external onlyAdmin {
        shounenToken = shounenToken_;
    }

    function setTomoVault(address tomoVault_) external onlyAdmin {
        tomoVault = tomoVault_;
    }

    function setShounenVault(address shounenVault_) external onlyAdmin {
        shounenVault = shounenVault_;
    }
}
