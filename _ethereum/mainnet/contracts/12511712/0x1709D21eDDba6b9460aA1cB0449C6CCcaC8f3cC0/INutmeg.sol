// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface INutmeg {
    enum Tranche {AA, A, BBB}
    enum StakeStatus {Uninitialized, Open, Closed}
    enum PositionStatus {Uninitialized, Open, Closed, Liquidated}

    struct Pool {
        bool isExists;
        address baseToken; // base token of this pool, e.g., WETH, DAI.
        uint[3] interestRates; // interest rate per block of each tranche. supposed to be updated everyday.
        uint[3] principals; // principals of each tranche, from lenders
        uint[3] loans; // loans of each tranche, from borrowers.
        uint[3] interests; // interests accrued from loans for each tranche.

        uint totalCollateral; // total collaterals in base token from borrowers.
        uint latestAccruedBlock; // the block number of the latest interest accrual action.
        uint sumRtb; // sum of interest rate per block (after adjustment) times # of blocks
        uint irAdjustPct; // interest rate adjustment in percentage, e.g., 1, 99.
        bool isIrAdjustPctNegative; // whether interestRateAdjustPct is negative
        uint[3] sumIpp; // sum of interest per principal.
        uint[3] lossMultiplier;
        uint[3] lossZeroCounter;
    }

    struct Stake {
        uint id;
        StakeStatus status;
        address owner;
        address pool;
        uint tranche; // tranche of the pool, 0 - AA, 1 - A, 2 - BBB.
        uint principal;
        uint sumIppStart;
        uint earnedInterest;
        uint lossMultiplierBase;
        uint lossZeroCounterBase;
    }

    struct Position {
        uint id; // id of the position.
        PositionStatus status; // status of the position, Open, Close, and Liquidated.
        address owner; // borrower's address
        address adapter; // adapter's address
        address baseToken; // base token that the borrower borrows from the pool
        address collToken; // collateral token that the borrower got from 3rd party pool.
        uint[3] loans; // loans of all tranches
        uint baseAmt; // amount of the base token the borrower put into pool as the collateral.
        uint collAmt; // amount of collateral token the borrower got from 3rd party pool.
        uint borrowAmt; // amount of base tokens borrowed from the pool.
        uint sumRtbStart; // rate times block when the position is created.
        uint repayDeficit; // repay pool loss
    }

    struct NutDist {
        uint endBlock;
        uint amount;
    }

    /// @dev Get all stake IDs of a lender
    function getStakeIds(address lender) external view returns (uint[] memory);

    /// @dev Get all position IDs of a borrower
    function getPositionIds(address borrower) external view returns (uint[] memory);

    /// @dev Get the maximum available borrow amount
    function getMaxBorrowAmount(address token, uint collAmount) external view returns(uint);

    /// @dev Get the current position while under execution.
    function getCurrPositionId() external view returns (uint);

    /// @dev Get the next position ID while under execution.
    function getNextPositionId() external view returns (uint);

    /// @dev Get the current sender while under execution
    function getCurrSender() external view returns (address);

    function getPosition(uint id) external view returns (Position memory);

    function getPositionInterest(address token, uint positionId) external view returns(uint);

    function getPoolInfo(address token) external view returns(uint, uint, uint);

    /// @dev Add Collateral token from the 3rd party pool to a position
    function addCollToken(uint posId, uint collAmt) external;

    /// @dev Borrow tokens from the pool.
    function borrow(address token, address collAddr, uint baseAmount, uint borrowAmount) external;

    /// @dev Repays tokens to the pool.
    function repay(address token, uint repayAmount) external;

    /// @dev Liquidate a position when conditions are satisfied
    function liquidate(address token, uint repayAmount) external;

    /// @dev Settle credit event
    function distributeCreditLosses( address baseToken, uint collateralLoss, uint poolLoss) external;
    event addPoolEvent(address bank, uint interestRateA);
    event stakeEvent(address bank, address owner, uint tranche, uint amount, uint depId);
    event unstakeEvent(address bank, address owner, uint tranche, uint amount, uint depId);
}
