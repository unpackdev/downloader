// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Storage.sol";
import "./IAdmin.sol";

/**
 * @title Admin
 * @author JieLi
 *
 * @notice Functions for admin operations
 */
abstract contract Admin is Storage, IAdmin {

    // ============ Params Setting Functions ============

    function setPrice(uint256 newPrice) external onlyOwner {
        emit UpdatePrice(_PRICE_, newPrice);
        _PRICE_ = newPrice;
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        emit UpdatePresalePrice(_PRESALE_PRICE_, newPrice);
        _PRESALE_PRICE_ = newPrice;
    }

    function setRevealURI(string memory newRevealURI) external onlyOwner {
        emit UpdateRevealURI(_REVEAL_URI_, newRevealURI);
        _REVEAL_URI_ = newRevealURI;
    }

    function setPendingURI(string memory newPendingURI) external onlyOwner {
        emit UpdatePendingURI(_PENDING_URI_, newPendingURI);
        _PENDING_URI_ = newPendingURI;
    }

    function setURIExtension(string memory newURIExtension) external onlyOwner {
        emit UpdateURIExtension(_URI_EXTENSION_, newURIExtension);
        _URI_EXTENSION_ = newURIExtension;
    }

    function setPresaleCount(uint256 newPresaleCount) external onlyOwner {
        emit UpdatePresaleCount(_PRESALE_COUNT_, newPresaleCount);
        _PRESALE_COUNT_ = newPresaleCount;
    }

    function setMaxMintCount(uint256 newMaxMintCount) external onlyOwner {
        emit UpdateMaxMintCount(_MAX_MINT_COUNT_, newMaxMintCount);
        _MAX_MINT_COUNT_ = newMaxMintCount;
    }

    function setWhiteListCount(uint256 newWhiteListCount) external onlyOwner {
        emit UpdateWhiteListCount(_WHITE_LIST_COUNT_, newWhiteListCount);
        _WHITE_LIST_COUNT_ = newWhiteListCount;
    }

    // ============ System Control Functions ============

    function enableRaffle() external onlyOwner {
        _RAFFLE_ALLOWED_ = true;
    }

    function disableRaffle() external onlyOwner {
        _RAFFLE_ALLOWED_ = false;
    }

    function enableDrop() external onlyOwner {
        _DROP_ALLOWED_ = true;
    }

    function disableDrop() external onlyOwner {
        _DROP_ALLOWED_ = false;
    }

    function enablePreSale() external onlyOwner {
        _PRESALE_ALLOWED_ = true;
    }

    function disablePreSale() external onlyOwner {
        _PRESALE_ALLOWED_ = false;
    }

    function enableReveal() external onlyOwner {
        _REVEAL_ALLOWED_ = true;
    }

    function disableReveal() external onlyOwner {
        _REVEAL_ALLOWED_ = false;
    }

    // ============ Advanced Control Functions ============

    function registerController(address _contractAddr) public onlyOwner {
        require(!controllers[_contractAddr], "ALREADY REGISTERED");
        controllers[_contractAddr] = true;
    }

    function removeController(address _contractAddr) public onlyOwner {
        require(controllers[_contractAddr], "NOT CONTROLLER");
        controllers[_contractAddr] = false;
    }

    function registerOwner(address _ownerAddr) public onlyOwner {
        require(!owners[_ownerAddr], "ALREADY REGISTERED");
        owners[_ownerAddr] = true;
    }

    function removeOwner(address _ownerAddr) public onlyOwner {
        require(owners[_ownerAddr], "NOT OWNER");
        owners[_ownerAddr] = false;
    }
}
