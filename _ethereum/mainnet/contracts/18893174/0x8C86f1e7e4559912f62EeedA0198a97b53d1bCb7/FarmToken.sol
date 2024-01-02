// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./WhitelistUpgradeable.sol";

error OperationOnlyAllowedByManager();
error TransferToNonWhitelistedAddressIsNotAllowed();
error TransferToBlacklistedAddressIsNotAllowed();

contract FarmToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address public farmManager;
    
    modifier onlyManager() {
        if(msg.sender != farmManager)
          revert OperationOnlyAllowedByManager();
        _;
    }

    constructor(address _farmManager) ERC20("FarmToken", "FTKN") {
        farmManager = _farmManager;
    }

    function setFarmManager(address _farmManager) external onlyOwner {
        farmManager = _farmManager;
    }

    function burn(address account, uint256 amount) external onlyManager {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyManager {
        _mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        WhitelistUpgradeable whitelistContract = WhitelistUpgradeable(farmManager);
        // Allow only moving tokens to an address that is whitelisted
        if (
            (to != address(0) &&
                !whitelistContract.isWhitelisted(address(this), to))
        ) {
            revert TransferToNonWhitelistedAddressIsNotAllowed();
        }
        // Allow only moving tokens to an address that is not blacklisted
        if (to != address(0) && whitelistContract.isBlacklisted(to)) {
            revert TransferToBlacklistedAddressIsNotAllowed();
        }
    }
}
