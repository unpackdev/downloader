// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract HoldingAcct {
    address public owner;

    constructor(address _owner){
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function changeOwner(address _new) public onlyOwner {
        owner = _new;
    }

    function withdrawToken(address _token, uint256 _amt) public onlyOwner {
        IERC20(_token).transfer(owner, _amt);
    }
}