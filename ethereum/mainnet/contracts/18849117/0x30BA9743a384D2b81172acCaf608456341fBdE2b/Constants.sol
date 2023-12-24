/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Copyright 2023 Lucky8 Lottery

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./IToken.sol";

contract Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1; // 1 888 -> 1 s888


    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    // we start in epoch 0 and CURRENT_EPOCH_START allows to advance to epoch 1, starting the first draw
    uint256 private constant CURRENT_EPOCH_OFFSET = 1;
    // the timestamp when the first draw should happen
    // eg Fri Dec 22 2023 15:00:00 GMT+0000
    uint256 private constant CURRENT_EPOCH_START = 1703257200; 
    uint256 private constant CURRENT_EPOCH_PERIOD = 86400; // a draw every 24 hours

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 3; // 3 epochs
    uint256 private constant GOVERNANCE_EXPIRATION = 2; // 2 + 1 epochs
    uint256 private constant GOVERNANCE_QUORUM = 25e16; // 25%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 15e15; // 1,5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 40e16; // 40%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 3; // 3 epochs

    /* DAO */
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 2; // 2 epochs fluid

    /* Lottery */
    uint256 private constant DISTRICUTION_PER_EPOCH  = 10e16; // 10% distribution per epoch
    uint256 private constant WINNINGTICKETS  = 3; // 3 winners per epoch

    /* Chainlink */
    address private constant VRF_COORDINATOR = address(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
    bytes32 private constant VRF_KEYHASH = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; // 200 gwei
    uint64 private constant CHAINLINK_SUBID = 888;

    /**
     * Getters
     */
    function getCurrentEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: CURRENT_EPOCH_OFFSET,
            start: CURRENT_EPOCH_START,
            period: CURRENT_EPOCH_PERIOD
        });
    }

    function getUsdc() internal pure returns (address) {
        return USDC;
    }

    function VRFKeyhash() public view returns (bytes32) {
        return VRF_KEYHASH;
    }

    function VRFCoordinator() public view returns (address) {
        return VRF_COORDINATOR;
    }

    function ChainlinkSubId() public view returns (uint64) {
        return CHAINLINK_SUBID;
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint256) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getDistributionPerEpoch() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DISTRICUTION_PER_EPOCH});
    }

    function getWinningTickets() internal pure returns (uint256) {
        return WINNINGTICKETS;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }
}
