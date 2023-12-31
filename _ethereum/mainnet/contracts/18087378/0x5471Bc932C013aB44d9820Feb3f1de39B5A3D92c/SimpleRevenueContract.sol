// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

pragma solidity ^0.8.16;
import "./Denominations.sol";
import "./IERC20.sol";
import "./MutualConsent.sol";

contract SimpleRevenueContract is MutualConsent {
    address public owner;
    address public manager;
    address public methodologist;
    IERC20 revenueToken;
    uint256 public count;
    mapping (address => uint256) public nonce;

    constructor(address _owner, address token) {
        owner = _owner;
        manager = _owner;
        methodologist = _owner;
        revenueToken = IERC20(token);
    }

    function claimPullPayment() external returns (bool) {
        require(msg.sender == owner, "Revenue: Only owner can claim");
        if (address(revenueToken) != Denominations.ETH) {
            require(revenueToken.transfer(owner, revenueToken.balanceOf(address(this))), "Revenue: bad transfer");
        } else {
            payable(owner).transfer(address(this).balance);
        }
        return true;
    }

    function sendPushPayment() external returns (bool) {
        if (address(revenueToken) != Denominations.ETH) {
            require(revenueToken.transfer(owner, revenueToken.balanceOf(address(this))), "Revenue: bad transfer");
        } else {
            payable(owner).transfer(address(this).balance);
        }
        return true;
    }

    function doAnOperationsThing() external returns (bool) {
        require(msg.sender == owner, "Revenue: Only owner can operate");
        return true;
    }

    function doAnOperationsThingWithArgs(uint256 val) external returns (bool) {
        require(val > 10, "too small");
        if (val % 2 == 0) return true;
        else return false;
    }

    function transferOwnership(address newOwner) external returns (bool) {
        require(msg.sender == owner, "Revenue: Only owner can transfer");
        owner = newOwner;
        return true;
    }

    function setMethodologist(address newMethodologist) external {
        require(msg.sender == methodologist, "Only methodologist can call");
        methodologist = newMethodologist;
    }

    function setManager(address newManager) external mutualConsent(manager, methodologist) {
        require(newManager != address(0), "Zero address not valid");
        manager = newManager;
    }

    function incrementCount() external {
        require(msg.sender == manager, "Only manager can call");
        count += 1;
    }

    function updateNonce(address _address, uint256 num) external {
        require(msg.sender == manager, "Only manager can call");
        nonce[_address] += num;
    }

    function getNonce(address _address) external view returns (uint256) {
        return nonce[_address];
    }

    receive() external payable {}
}
