// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";

interface IVotV {
    function mint(uint256 _mintAmount) external payable;
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract MintVotV {

    IVotV constant votv = IVotV(0x5BC0F0911034d23c90c96945d9c072596ee64ed5);

    constructor() payable {
        uint256 supply = votv.totalSupply();
        votv.mint{value: 0.06 ether}(2);
        votv.mint{value: 0.06 ether}(2);
        votv.transferFrom(address(this), tx.origin, supply + 1);
        votv.transferFrom(address(this), tx.origin, supply + 2);
        votv.transferFrom(address(this), tx.origin, supply + 3);
        votv.transferFrom(address(this), tx.origin, supply + 4);
    }
}

contract VotVMinter is Ownable {

    constructor() {
        _initializeOwner(tx.origin);
    }

    function mint(uint256 quantity) external payable onlyOwner {
        require(quantity % 4 == 0, "quantity must be divisible by 4");
        require(msg.value == quantity * 0.03 ether, "incorrect amount of ether sent");

        uint256 mintCalls = quantity / 4;
        for (uint256 i; i < mintCalls;) {
            new MintVotV{value: 0.12 ether}();

            unchecked {
                ++i;
            }
        }
    }

}