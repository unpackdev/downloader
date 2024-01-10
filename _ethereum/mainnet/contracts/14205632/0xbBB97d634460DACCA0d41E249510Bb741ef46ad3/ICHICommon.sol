// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./ICHIOwnable.sol";
import "./ICHIInitializable.sol";
import "./IERC20Extended.sol";
import "./IICHICommon.sol";

contract ICHICommon is IICHICommon, ICHIOwnable, ICHIInitializable {

    uint256 constant PRECISION = 10 ** 18;
    uint256 constant INFINITE = uint256(0-1);
    address constant NULL_ADDRESS = address(0);
    
    // @dev internal fingerprints help prevent deployment-time governance errors

    bytes32 constant COMPONENT_CONTROLLER = keccak256(abi.encodePacked("ICHI V1 Controller"));
    bytes32 constant COMPONENT_VERSION = keccak256(abi.encodePacked("ICHI V1 OneToken Implementation"));
    bytes32 constant COMPONENT_STRATEGY = keccak256(abi.encodePacked("ICHI V1 Strategy Implementation"));
    bytes32 constant COMPONENT_MINTMASTER = keccak256(abi.encodePacked("ICHI V1 MintMaster Implementation"));
    bytes32 constant COMPONENT_ORACLE = keccak256(abi.encodePacked("ICHI V1 Oracle Implementation"));
    bytes32 constant COMPONENT_VOTERROLL = keccak256(abi.encodePacked("ICHI V1 VoterRoll Implementation"));
    bytes32 constant COMPONENT_FACTORY = keccak256(abi.encodePacked("ICHI OneToken Factory"));
}
