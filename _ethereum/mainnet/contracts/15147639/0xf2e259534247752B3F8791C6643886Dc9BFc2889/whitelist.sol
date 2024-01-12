// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WhIn.sol";
import "./Counters.sol";

contract whitelistChecker is WhIn {
    
    using Counters for Counters.Counter;

    mapping(address => bool) public whitelisted;
    address private Owner;
    bool public paused;
    uint256 public whitelistAmount = 3000;
    Counters.Counter amount;

    constructor() {
        Owner = msg.sender;
        whitelisted[msg.sender] = true;
    }

    modifier OnlyOwner {
        require(msg.sender == Owner, "You are not the owner of the contract.");
        _;
    }

    modifier PauseCheck {
        require(paused == false, "Whitelisting is currently paused");
        _;
    }

    function addWhitelist() public PauseCheck {
        require(whitelisted[msg.sender] == false, "User is already present in the whitelist.");
        require(amount.current() < whitelistAmount, "Whitelist limit has been hit.");
        whitelisted[msg.sender] = true;
        amount.increment();
        emit WhitelistChange(msg.sender, true);
    }

    function checkWhitelist(address account) public view override returns(bool) {
        return whitelisted[account];
    }

    function checkWhitelistCounter() public view returns(uint256) {
        return amount.current();
    }

    function removeWhitelist(address _who) public OnlyOwner {
        whitelisted[_who] = false;
        amount.decrement();
        emit WhitelistChange(_who, false);
    }

    function setWhitelistAmount(uint256 _whitelistAmount) public OnlyOwner {
        whitelistAmount = _whitelistAmount;
    }


    function whitelistArray(address[] memory _who, bool _status) public OnlyOwner {
        if (_status == true) {
            require((_who.length - 1) + amount.current() < 3, "Whitelist limit has been hit.");
        }
        for (uint256 i = 0; i < _who.length;) {
            whitelisted[_who[i]] = _status;
            if (_status == true) {
                amount.increment();
            } else {
                amount.decrement();
            }
            emit WhitelistChange(_who[i], _status);
            i += 1;
        }
    }

    function pauseContract(bool _status) public OnlyOwner {
        paused = _status;
    }

    function changeOwner(address _who) public OnlyOwner {
        Owner = _who;
    }
}