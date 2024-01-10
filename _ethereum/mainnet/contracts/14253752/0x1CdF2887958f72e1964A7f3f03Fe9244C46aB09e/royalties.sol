// SPDX-License-Identifier: MIT

/**
royalties splitter contract made by 0x0000
TG: @jacko06v

 */

import "./SafeMath.sol";

pragma solidity ^0.8.7;

contract royaltiesSplitter {
    using SafeMath for uint256;

    uint256 public treasuryPerc = 2857;
    uint256 public secondAccPerc = 2857;
    uint256 public valeriyaPerc = 2857;
    uint256 public gaiaOnePerc = 1429;
    address public treasuryAddr = 0x713D3a54ba90e22f7a80Dd28bb268cE56a231586;
    address public secondAccAddr = 0xba9B045502A8A733853537114C5F2a0C87639098;
    address public valeriyaAddr = 0xaAD198caBbbCBca1AF0590D71b51F155216DAE8F;
    address public gaiaOneAddr = 0xd1Cc61b52ECAc53F318B5C8288755E334c98341F;

      
    receive() external payable {}


    fallback() external payable {}

    function withdraw() external {
        uint256 totalBalance = address(this).balance;
        uint256 wallet1Balance = totalBalance.mul(treasuryPerc).div(1e4);
        uint256 wallet2Balance = totalBalance.mul(secondAccPerc).div(1e4);
        uint256 wallet3Balance = totalBalance.mul(valeriyaPerc).div(1e4);
        uint256 wallet4Balance = totalBalance.mul(gaiaOnePerc).div(1e4);
        payable(treasuryAddr).transfer(wallet1Balance);
        payable(secondAccAddr).transfer(wallet2Balance);
        payable(valeriyaAddr).transfer(wallet3Balance);
        payable(gaiaOneAddr).transfer(wallet4Balance);
        uint256 transferBalance = totalBalance.sub(wallet1Balance.add(wallet2Balance).add(wallet3Balance).add(wallet4Balance));
        payable(msg.sender).transfer(transferBalance);
    }
}
