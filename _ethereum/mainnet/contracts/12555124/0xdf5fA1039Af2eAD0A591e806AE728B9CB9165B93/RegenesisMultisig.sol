pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./Ownable.sol";
import "./Config.sol";

/// @title Regenesis Multisig contract
/// @author Matter Labs
contract RegenesisMultisig is Ownable, Config {
    event CandidateAccepted(bytes32 oldRootHash, bytes32 newRootHash);
    event CandidateApproval(uint256 currentApproval);

    bytes32 public oldRootHash;
    bytes32 public newRootHash;

    bytes32 public candidateOldRootHash;
    bytes32 public candidateNewRootHash;

    /// @dev Stores boolean flags which means the confirmations of the upgrade for each member of security council
    mapping(uint256 => bool) internal securityCouncilApproves;
    uint256 internal numberOfApprovalsFromSecurityCouncil;

    uint256 securityCouncilThreshold;

    constructor(uint256 threshold) Ownable(msg.sender) {
        securityCouncilThreshold = threshold;
    }

    function submitHash(bytes32 _oldRootHash, bytes32 _newRootHash) external {
        // Only zkSync team can submit the hashes
        require(msg.sender == getMaster(), "1");

        candidateOldRootHash = _oldRootHash;
        candidateNewRootHash = _newRootHash;

        oldRootHash = bytes32(0);
        newRootHash = bytes32(0);

        for (uint256 i = 0; i < SECURITY_COUNCIL_MEMBERS_NUMBER; ++i) {
            securityCouncilApproves[i] = false;
        }
        numberOfApprovalsFromSecurityCouncil = 0;
    }

    function approveHash(bytes32 _oldRootHash, bytes32 _newRootHash) external {
        require(_oldRootHash == candidateOldRootHash, "2");
        require(_newRootHash == candidateNewRootHash, "3");

        address payable[SECURITY_COUNCIL_MEMBERS_NUMBER] memory SECURITY_COUNCIL_MEMBERS =
            [0xa2602ea835E03fb39CeD30B43d6b6EAf6aDe1769,0x9D5d6D4BaCCEDf6ECE1883456AA785dc996df607,0x002A5dc50bbB8d5808e418Aeeb9F060a2Ca17346,0x71E805aB236c945165b9Cd0bf95B9f2F0A0488c3,0x76C6cE74EAb57254E785d1DcC3f812D274bCcB11,0xFBfF3FF69D65A9103Bf4fdBf988f5271D12B3190,0xAfC2F2D803479A2AF3A72022D54cc0901a0ec0d6,0x4d1E3089042Ab3A93E03CA88B566b99Bd22438C6,0x19eD6cc20D44e5cF4Bb4894F50162F72402d8567,0x39415255619783A2E71fcF7d8f708A951d92e1b6,0x399a6a13D298CF3F41a562966C1a450136Ea52C2,0xee8AE1F1B4B1E1956C8Bda27eeBCE54Cf0bb5eaB,0xe7CCD4F3feA7df88Cf9B59B30f738ec1E049231f,0xA093284c707e207C36E3FEf9e0B6325fd9d0e33B,0x225d3822De44E58eE935440E0c0B829C4232086e];
        for (uint256 id = 0; id < SECURITY_COUNCIL_MEMBERS_NUMBER; ++id) {
            if (SECURITY_COUNCIL_MEMBERS[id] == msg.sender) {
                require(securityCouncilApproves[id] == false);
                securityCouncilApproves[id] = true;
                numberOfApprovalsFromSecurityCouncil++;
                emit CandidateApproval(numberOfApprovalsFromSecurityCouncil);

                // It is ok to check for strict equality since the numberOfApprovalsFromSecurityCouncil
                // is increased by one at a time. It is better to do so not to emit the
                // CandidateAccepted event more than once
                if (numberOfApprovalsFromSecurityCouncil == securityCouncilThreshold) {
                    oldRootHash = candidateOldRootHash;
                    newRootHash = candidateNewRootHash;
                    emit CandidateAccepted(oldRootHash, newRootHash);
                }
            }
        }
    }
}
