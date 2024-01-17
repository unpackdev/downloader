// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract MetaUnitIDOWhitelist is Pausable, ReentrancyGuard {
    mapping (address => bool) private is_whitelist_address;
    uint256 constant _start_time = 1667991600;
    uint256 private _price;
    address private _metaunit_address;
    address private _project_address;

    constructor (uint256 price_, address metaunit_address_, address project_address_) Pausable(project_address_) {
        _price = price_;
        _metaunit_address = metaunit_address_;
        _project_address = project_address_;
    }

    function buy(uint256 amount_) public payable notPaused nonReentrant {
        require(block.timestamp >= _start_time, "Event not started yet");
        require(msg.value >= amount_ * _price, "Not enough funds sent");
        require(is_whitelist_address[msg.sender], "You are not in whitelist");
        IERC20(_metaunit_address).transfer(msg.sender, amount_);
        payable(_project_address).transfer(msg.value);
    }

    function setWhiteList(address[] memory addresses_, bool action_) public {
        require(msg.sender == _project_address, "Permission denied");
        for (uint256 i = 0; i < addresses_.length; i ++) {
            is_whitelist_address[addresses_[i]] = action_;
        }
    }

    function setPrice(uint256 price_) public {
        require(msg.sender == _project_address, "Permission denied");
        _price = price_;
    }
}
