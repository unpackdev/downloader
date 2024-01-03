// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

/*
    A pool of spores that can be takens by Spore pools according to their spore rate
*/
contract Mission is Initializable, OwnableUpgradeSafe {

    IERC20 public sporeToken;
    mapping (address => bool) public approved;

    event SporesHarvested(address pool, uint256 amount);

    modifier onlyApprovedPool() {
        require(approved[msg.sender], "Mission: Only approved pools");
        _;
    }
    function initialize(IERC20 sporeToken_) public initializer {
        __Ownable_init();
        sporeToken = sporeToken_;
    }

    function sendSpores(address recipient, uint256 amount) public onlyApprovedPool {
        sporeToken.transfer(recipient, amount);
        emit SporesHarvested(msg.sender, amount);
    }

    function approvePool(address pool) public onlyOwner {
        approved[pool] = true;
    }

    function revokePool(address pool) public onlyOwner {
        approved[pool] = false;
    }
}