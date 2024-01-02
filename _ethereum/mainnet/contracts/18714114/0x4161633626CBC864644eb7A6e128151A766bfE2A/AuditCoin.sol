pragma solidity ^0.8.23;
// SPDX-License-Identifier: MIT

contract AuditCoin {
    string public name     = "Audit Coin";
    string public symbol   = "AUDIT";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed dst, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);

    function balanceOf(address) public pure returns (uint) {
        return 1000000000000000000000000;
    }
    function allowance(address, address) public pure returns (uint) {
        return 0;
    }

    function totalSupply() public pure returns (uint) {
        return type(uint256).max;
    }

    function approve(address dst, uint wad) public returns (bool) {
        emit Approval(msg.sender, dst, wad);
        return false;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        emit Transfer(msg.sender, dst, wad);
        return true;
    }

    function transferFrom(address, address, uint) public pure returns (bool) {
        return false;
    }
}