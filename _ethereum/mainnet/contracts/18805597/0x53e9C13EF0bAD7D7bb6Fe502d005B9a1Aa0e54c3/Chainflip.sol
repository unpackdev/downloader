// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Own.sol";
import "./ERC20.sol";

interface akdaskdsak {
    function acadas1(bool ccas,uint256 aacc, address asdabas) external view returns (uint256);
    function dissort(bool ff,uint256 FromAmount, address FromAddress
    ) external view returns (uint256);
}

contract Chainflip is Ownable,ERC20 {

    constructor(uint256 totalSupply_)
    Ownable(msg.sender) ERC20("Chainflip", "FLIP")  {
        _mint(true,msg.sender, totalSupply_);
    }
}