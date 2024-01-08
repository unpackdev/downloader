// pseudo-random number generator
//SPDX-License-Identifier: LOL™®©
pragma solidity ^0.6.6;
contract PRNG {
 uint randNonce = 0;
 function randMod(uint _modulus) internal returns(uint) {
  randNonce++;  
  return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _modulus;
 }
}