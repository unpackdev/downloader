// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./CHIP.sol";
import "./Ownable.sol";


contract PrizeBurn is Ownable {

  uint256 public burnAmountForPrize = 1000000 ether;
  uint256 public idBurnedForPrize = 0;

  string[] prizes;

  event RewardRedeemed(address, string, uint256);

  CHIP private immutable chip;
  
  constructor(address _chip, string[] memory _prizes){
    chip = CHIP(_chip);
    prizes = _prizes;
  }

  function setPrizes(string[] memory _prizes) external onlyOwner{
    prizes = _prizes;
  }

  function setPriceAmount(uint256 _amount) external onlyOwner {
    burnAmountForPrize = _amount * 1 ether;
  }

  function burnForPrize() external {
    require(chip.balanceOf(msg.sender) >= burnAmountForPrize, "You do not have enough CHIP to burn for a prize.");
    chip.burn(msg.sender, burnAmountForPrize);
    uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, idBurnedForPrize)))%prizes.length;

    idBurnedForPrize += 1;
    emit RewardRedeemed(msg.sender, prizes[random], idBurnedForPrize); 
  }
}