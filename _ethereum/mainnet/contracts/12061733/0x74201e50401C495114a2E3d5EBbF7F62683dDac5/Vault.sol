// Inspired by https://github.com/BarnBridge/BarnBridge-YieldFarming/blob/master/contracts/CommunityVault.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract Vault is OwnableUpgradeSafe {

    IERC20 public SLICE;

    constructor (address sliceAddress) public {
        OwnableUpgradeSafe.__Ownable_init();
        SLICE = IERC20(sliceAddress);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) external onlyOwner {
        SafeERC20.safeApprove(SLICE, spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
