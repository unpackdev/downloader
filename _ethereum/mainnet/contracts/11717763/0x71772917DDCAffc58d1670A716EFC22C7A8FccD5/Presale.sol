// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./Tokemon.sol";

contract Presale is Ownable {
  ERC20 public immutable TOKEMON;
  uint public constant presaleSupply = 2500;
  uint public constant startDate = 1611518400;
  uint256 public constant presalePrice = 12; // 0.12 then divide by 100
  uint256 public constant maxTokensPerWallet = (10 * 10 ** 18) / presalePrice * 100; // max 10 eth worth of tokens per wallet

  constructor(Tokemon tokemon) public {
    TOKEMON = tokemon;
  }

  receive() external payable {
    require(startDate <= block.timestamp, "Presale hasn't started yet");

    uint tokensToTransfer = msg.value / presalePrice * 100;
    require(tokensToTransfer <= TOKEMON.balanceOf(address(this)), "Not enough tokens in Presale contract");
    require(tokensToTransfer + TOKEMON.balanceOf(address(msg.sender)) <= maxTokensPerWallet, "Max 10 eth worth of tokens allowed in presale");
    TOKEMON.transfer(msg.sender, tokensToTransfer);
  }

  function withdrawProvidedEth() external onlyOwner {  // external onlyOwner
    payable(owner()).transfer(address(this).balance);
  }

  function withdrawTokemon() external onlyOwner {  // external onlyOwner
    TOKEMON.transfer(owner(), TOKEMON.balanceOf(address(this))); //safeTransfer?
  }

}
