pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./math.sol";
import "./basic.sol";
import "./interfaces.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
  TokenInterface constant internal rewardToken = TokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);
}