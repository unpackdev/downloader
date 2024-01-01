// SPDX-License-Identifier: GPL-3.0
import "./CLLNFT.sol";

pragma solidity ^0.8.15;

contract CLLPadlock is CLLNFT("CherishedLoveLocks Padlock", "CLL_P"){

    // Engraving
    mapping(uint256 => bytes32) public padlockEngraving_1st_line;
    mapping(uint256 => bytes32) public padlockEngraving_2nd_line;
    mapping(uint256 => bytes32) public padlockEngraving_3rd_line;
    mapping(uint256 => bool)    public padlockEngraving_engraved;

    function engravePadlock( uint256 padlockTokenId
                            ,bytes32 text_1
                            ,bytes32 text_2
                            ,bytes32 text_3) external onlyOwner{

      require(padlockEngraving_engraved[padlockTokenId] == false, "Already engraved");

      padlockEngraving_1st_line[padlockTokenId] = text_1;
      padlockEngraving_2nd_line[padlockTokenId] = text_2;
      padlockEngraving_3rd_line[padlockTokenId] = text_3;
      padlockEngraving_engraved[padlockTokenId] = true;
    }
}

