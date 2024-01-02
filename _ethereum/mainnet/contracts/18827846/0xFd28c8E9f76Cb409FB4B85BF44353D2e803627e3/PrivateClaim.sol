// SPDX-License-Identifier: GPL-3.0

//██████╗░░█████╗░██████╗░██████╗░  ██╗░░██╗██╗░░░██╗██████╗░░██╗░░░░░░░██╗░█████╗░
//██╔══██╗██╔══██╗██╔══██╗██╔══██╗  ██║░██╔╝██║░░░██║██╔══██╗░██║░░██╗░░██║██╔══██╗
//██████╦╝██║░░██║██████╦╝██████╔╝  █████═╝░██║░░░██║██████╔╝░╚██╗████╗██╔╝███████║
//██╔══██╗██║░░██║██╔══██╗██╔══██╗  ██╔═██╗░██║░░░██║██╔══██╗░░████╔═████║░██╔══██║
//██████╦╝╚█████╔╝██████╦╝██║░░██║  ██║░╚██╗╚██████╔╝██║░░██║░░╚██╔╝░╚██╔╝░██║░░██║
//╚═════╝░░╚════╝░╚═════╝░╚═╝░░╚═╝  ╚═╝░░╚═╝░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝

//█▄▄ █▀█ █▄▄ █▀█ ░ █▀▀ █░░ █░█ █▄▄
//█▄█ █▄█ █▄█ █▀▄ ▄ █▄▄ █▄▄ █▄█ █▄█
//https://bobr.com/

//Official Private-sale contract
pragma solidity >=0.8.2 <0.9.0;

contract PrivateClaim {

    address private owner;
    uint tokenCost = 0.0002 ether;
    uint nextSpot = 0;

    mapping (uint => address) private _lineSpot;
    mapping (address => uint) private _amountOwned;

    constructor() {
        owner = msg.sender;
    }

    function claimTokens() public payable {
        require(msg.value > tokenCost);
        _lineSpot[nextSpot] = msg.sender; 
        _amountOwned[msg.sender] += msg.value / tokenCost;
        nextSpot++;
    }

    function withdraw() public {
        require(msg.sender == owner);
        (bool oc, ) = payable(owner).call {
            value: address(this).balance
        }("");
        require(oc);
    }
}

//░░█ ▄▀█   █▀█ █ █▀▀ █▀█ █▀▄ █▀█ █░░ █▀▀
//█▄█ █▀█   █▀▀ █ ██▄ █▀▄ █▄▀ █▄█ █▄▄ ██▄