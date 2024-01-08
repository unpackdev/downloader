pragma solidity 0.6.6;

import "./SafeMath.sol";

library LockLib {

    enum LockType {
        None, NoBurnPool, NoIn, NoOut, NoTransaction,
        PenaltyOut, PenaltyIn, PenaltyInOrOut, Master, LiquidityAdder, BlacklistAdmin
    }

    struct TargetPolicy {
        LockType lockType;
        uint16 penaltyRateOver1000;
        bool isPermanent;
    }
}