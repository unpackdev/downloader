// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Strings.sol";

contract Aprons is Ownable, ERC20Capped {
  bool public alreadyGivenToTendiesContract = false;

  constructor() ERC20("Aprons", "APRON") ERC20Capped(500) {
    ERC20._mint(msg.sender, 250);
  }

  function giveToTendiesContract(address tendiesContract) public onlyOwner {
    require(!alreadyGivenToTendiesContract, "Already minted to Tendies contract.");
    alreadyGivenToTendiesContract = true;
    _mint(tendiesContract, 250);
  }
}