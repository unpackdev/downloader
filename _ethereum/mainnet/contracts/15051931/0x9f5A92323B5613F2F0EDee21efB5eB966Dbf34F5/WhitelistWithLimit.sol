// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./console.sol";

abstract contract WhitelistWithLimit is Ownable {
    mapping(address => bool) private _whitelist;
    uint256 public _whitelistSize;
    uint256 public _whitelistLimit;
    bool private _whitelistSwitcher; 

    event WhitelistAdded(address indexed _address);

    modifier onlyWhitelist {
        require(_whitelistSwitcher || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    modifier onlyWhitelistNotFull {
        require(_whitelistSwitcher && !_whitelist[msg.sender], "Whitelist: caller is on the whitelist");
        require(_whitelistSize < _whitelistLimit, "Whitelist: whitelist size exceed limit");
        _;
    }

    function isWhitelist() public view returns (bool) {
        return _whitelist[msg.sender];
    } 

    function isWhitelistOf(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function addWhitelist() public onlyWhitelistNotFull {
        _whitelist[msg.sender] = true;

        _whitelistSize = _whitelistSize + 1;

        emit WhitelistAdded(msg.sender);
    }

    function addWhitelist(address _address) external onlyOwner onlyWhitelistNotFull {
        _whitelist[_address] = true;

        _whitelistSize = _whitelistSize + 1;

        emit WhitelistAdded(_address);
    }

    function updateWhitelistInfo(uint256 _limit, bool _whitelistSwitch) external onlyOwner {
        _whitelistLimit = _limit;
        _whitelistSwitcher = _whitelistSwitch;
    }
}