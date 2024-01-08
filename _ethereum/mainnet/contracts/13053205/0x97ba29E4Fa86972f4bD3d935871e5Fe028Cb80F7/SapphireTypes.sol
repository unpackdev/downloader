// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

library SapphireTypes {

    struct ScoreProof {
        address account;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct CreditScore {
        uint256 score;
        uint256 lastUpdated;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 borrowedAmount;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        Operation operation;
        address userToLiquidate;
    }

}
