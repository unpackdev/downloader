// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IRewards.sol";

library LibComitiumStorage {
    bytes32 constant STORAGE_POSITION = keccak256("com.fiatdao.comitium.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    struct Storage {
        bool initialized;

        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;

        // array of fdt staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] fdtStakedHistory;

        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;

        IERC20 fdt;
        IRewards rewards;
    }

    function comitiumStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
