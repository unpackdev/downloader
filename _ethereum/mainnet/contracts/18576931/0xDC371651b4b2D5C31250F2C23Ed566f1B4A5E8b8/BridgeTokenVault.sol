// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";

contract BridgeTokenVault is Ownable {
    IERC20 public token;
    uint256 public unlockTime;

    event Deposit(uint256 amount);
    event Withdrawal(uint256 amount);
    event UnlockTimeUpdated(uint256 unlockTime);

    constructor (IERC20 _token, uint256 _unlockTime) Ownable(msg.sender) {
        token = _token;
        unlockTime = _unlockTime;
    }

    function setUnlockTime(uint256 _unlockTime) public onlyOwner {
        require(_unlockTime > unlockTime, "Vault: Unlock time can only be extended");
        unlockTime = _unlockTime;
        emit UnlockTimeUpdated(_unlockTime);
    }

    function deposit(uint256 amount) public onlyOwner {
        token.transferFrom(owner(), address(this), amount);
        emit Deposit(amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(block.timestamp >= unlockTime, "Vault: Unlock time not reached yet");
        token.transfer(owner(), amount);
        emit Withdrawal(amount);
    }
}
