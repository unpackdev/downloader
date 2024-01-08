// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IBridge.sol";
import "./IFee.sol";
import "./ILimiter.sol";

abstract contract BridgeBase is IBridge, Ownable, Pausable, ReentrancyGuard {
    string private _name;
    IFee private _fee;
    ILimiter private _limiter;
    mapping(bytes32 => bool) private _unlockedCompleted;

    constructor(string memory name_, IFee fee_, ILimiter limiter) {
        _name = name_;
        _fee = fee_;
        _limiter = limiter;
    }

    receive() external payable {
        revert();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function calculateFee(uint256 amount) public view returns (uint256) {
        if (address(_fee) == address(0)) {
            return 0;
        }
        return _fee.calculate(amount);
    }

    function getFee() public view returns (IFee) {
        return _fee;
    }

    function setFee(IFee fee_) external onlyOwner {
        _fee = fee_;
    }

    function getLimiter() public view returns (ILimiter) {
        return _limiter;
    }

    function getLimiterUsage() public view returns (uint256) {
        return _limiter.getUsage(address(this));
    }

    function isLimited(uint256 amount) public view returns (bool) {
        return _limiter.isLimited(address(this), amount);
    }

    function setLimiter(ILimiter limiter) external onlyOwner {
        _limiter = limiter;
    }

    function _transferFee(uint256 amount) private nonReentrant {
        uint256 calculatedFee = calculateFee(amount);
        if (calculatedFee == 0) {
            return;
        }

        require(msg.value >= calculatedFee, "BridgeBase: not enough fee");

        (bool success,) = owner().call{value : msg.value}("");
        require(success, "BridgeBase: can not transfer fee");
    }

    function _checkLimit(uint256 amount) internal {
        if (address(_limiter) == address(0)) {
            return;
        }
        _limiter.increaseUsage(amount);
    }

    function _beforeLock(uint256 amount) internal whenNotPaused {
        _checkLimit(amount);
        _transferFee(amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isUnlockCompleted(bytes32 hash) public view override returns (bool) {
        return _unlockedCompleted[hash];
    }

    function _setUnlockCompleted(bytes32 hash) internal {
        require(!isUnlockCompleted(hash), "BridgeBase: already unlocked");
        _unlockedCompleted[hash] = true;
    }
}
