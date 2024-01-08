// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBridge.sol";
import "./IFee.sol";
import "./ILimiter.sol";
import "./BridgeBase.sol";

contract BridgeEther is BridgeBase {
    constructor(string memory name, IFee fee, ILimiter limiter) BridgeBase(name, fee, limiter) {}

    function lock(uint256 amount) external payable override nonReentrant whenNotPaused {
        _checkLimit(amount);

        uint256 calculatedFee = calculateFee(amount);
        require(msg.value == amount + calculatedFee, "BridgeEther: invalid ether");

        (bool success,) = owner().call{value : calculatedFee}("");
        require(success, "BridgeEther: can not transfer fee");

        emit Locked(_msgSender(), amount);
    }

    function unlock(address account, uint256 amount, bytes32 hash) external override onlyOwner nonReentrant {
        _setUnlockCompleted(hash);

        require(address(this).balance >= amount, "BridgeEther: not enough ether");

        (bool success,) = account.call{value : amount}("");
        require(success, "BridgeEther: can not transfer ether");

        emit Unlocked(account, amount);
    }

    function renounceOwnership() public override onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = owner().call{value : balance}("");
            require(success, "BridgeEther: can not transfer ether");
        }

        _pause();
        Ownable.renounceOwnership();
    }
}
