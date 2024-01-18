// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IOracle.sol";

library ConditionalTokenLibrary {
    struct Condition {
        IOracle oracle;
        bytes32 questionId;
        uint256 outcomeSlotCount;
    }

    struct Collection {
        bytes32 parentCollectionId;
        bytes32 conditionId;
        uint256 indexSet;
    }

    struct Position {
        IERC20 collateralToken;
        bytes32 collectionId;
        uint8 decimalOffset;
    }
}
