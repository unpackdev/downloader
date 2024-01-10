// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract SushimiToken is ERC20, Ownable {
  constructor () ERC20("Sushimi", "SUSH") {
    _mint(msg.sender, 10000 * 1e18);
  }

  // Onwership will be transferred to the NFT contract at deployment to allow for approve-less mints
  function burnFrom(address _from, uint256 _amount) external onlyOwner {
    _burn(_from, _amount);
  }
}