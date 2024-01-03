// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IComptroller.sol";
import "./IInterestRateModel.sol";
import "./PTokenStorage.sol";

abstract contract IPToken is PTokenStorage {
    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(
        IComptroller oldComptroller,
        IComptroller newComptroller
    );

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(
        IInterestRateModel oldInterestRateModel,
        IInterestRateModel newInterestRateModel
    );

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(
        uint256 oldReserveFactorMantissa,
        uint256 newReserveFactorMantissa
    );

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    event NewMigrator(address oldMigrator, address newMigrator);

    /*** User Interface ***/

    function transfer(address dst, uint256 amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool);

    function allowance(address owner, address spender)
        external
        virtual
        view
        returns (uint256);

    function balanceOf(address owner) external virtual view returns (uint256);

    function balanceOfUnderlying(address owner)
        external
        virtual
        returns (uint256);

    function getAccountSnapshot(address account)
        external
        virtual
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external virtual view returns (uint256);

    function supplyRatePerBlock() external virtual view returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function borrowBalanceCurrent(address account)
        external
        virtual
        returns (uint256);

    function borrowBalanceStored(address account)
        public
        virtual
        view
        returns (uint256);

    function exchangeRateCurrent() public virtual returns (uint256);

    function exchangeRateStored() public virtual view returns (uint256);

    function getCash() external virtual view returns (uint256);

    function accrueInterest() public virtual returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    /*** Admin Functions ***/

    function _setComptroller(IComptroller newComptroller)
        public
        virtual
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        virtual
        returns (uint256);

    function _reduceReserves(uint256 reduceAmount)
        external
        virtual
        returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel)
        public
        virtual
        returns (uint256);

    function _setMigrator(address newMigrator)
        public
        virtual
        returns (uint256);
}
