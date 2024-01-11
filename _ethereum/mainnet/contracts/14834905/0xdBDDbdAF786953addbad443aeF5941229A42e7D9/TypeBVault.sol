//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TypeBVaultStorage.sol";

import "./ProxyAccessCommon.sol";
import "./ITypeBVault.sol";
import "./VaultStorage.sol";

contract TypeBVault is TypeBVaultStorage, VaultStorage, ProxyAccessCommon, ITypeBVault {
    using SafeERC20 for IERC20;

    ///@dev constructor
    constructor() {
    }

    function claim(address _to, uint256 _amount) external override onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= _amount, "Vault: insufficient");
        IERC20(token).safeTransfer(_to, _amount);
    }

}