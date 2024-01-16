// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";

contract GameBoyWithdraw is Ownable {
    address public from;
    address public eyewitness = 0xF1B025679e530A6484B3C00aAF1006Fd47EaFA7a;
    address public token = 0x20e38996B2788CF25f94e09E58D3274558A56DAD;
    mapping (uint => bool) public ids;
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    event Withdrawal(uint id, uint amount);

    constructor() {
        from = msg.sender;
    }

    function withdraw(uint id, uint amount, uint8 v, bytes32 r, bytes32 s, uint deadline) public ensure(deadline) {
        require(!ids[id], "already withdraw");
        require(ecrecover(keccak256(abi.encodePacked(id, amount, msg.sender, deadline)), v, r, s) == eyewitness, 'INVALID_SIGNATURE');
        ids[id] = true;
        IERC20(token).transferFrom(from, msg.sender, amount);
        emit Withdrawal(id, amount);
    }

    function setFrom(address _addr) public onlyOwner {
        from = _addr;
    }

    function setEyewitness(address addr) public onlyOwner {
        require(addr != address(0), "addr err");
        eyewitness = addr;
    }
}
