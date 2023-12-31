// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./Ownable.sol";

interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function mint(address user, uint256 amount) external returns(bool);
    function burn(address user, uint256 amount) external returns(bool);
}

contract GrantHelper is Ownable {
    IToken public esLBR;
    IToken public LBR;

    event Grant(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 time
    );

    constructor(address _lbr, address _esLBR) {
        LBR = IToken(_lbr);
        esLBR = IToken(_esLBR);
    }

    function grant(address to, uint256 amount) external {
        LBR.burn(msg.sender, amount);
        esLBR.mint(to, amount);
        emit Grant(msg.sender, to, amount, block.timestamp);
    }

    function withdraw(address token, uint256 amount, address to) external onlyOwner {
        IToken(token).transfer(to, amount);
    }
}