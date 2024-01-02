pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract L1GmxBase is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public constant CROSS_CHAIN_PORTAL =
        0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address public constant ARB_RECEIVER =
        0xe43d752271E9C343237F6d2a0c6dfeABC9857114;
    uint64 public constant GAS_LIMIT_FOR_CALL = 3_500_000;
    uint256 public constant MAX_FEE_PER_GAS = 1 gwei;
    uint256 public constant MAX_SUBMISSION_COST = 0.001 ether;
    
    uint256[50] private _gap;
    
    function initialize() public initializer {
        __Ownable_init();
    }

}
