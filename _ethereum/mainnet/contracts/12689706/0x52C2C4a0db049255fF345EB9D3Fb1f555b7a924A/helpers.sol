pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./math.sol";
import "./basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev InstaGovernorBravo
     */
    InstaGovernorInterface internal constant instaGovernor = InstaGovernorInterface(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);

    /**
     * @dev INST Token
     */
    InstaTokenInterface internal constant instToken = InstaTokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);
}