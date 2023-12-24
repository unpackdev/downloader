// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "SafeERC20.sol";
import "YPrismaAuthenticated.sol";
import "IPrismaFeeDistributor.sol";
import "IVault.sol";

interface IStaker {
    function deposit(uint amount, address receiver) external returns (uint);
    function notifyRewardAmount(uint reward) external;
}

/**
    @title Yearn Prisma Fee Distributor
    @author Yearn Finance
    @notice Distributes fees from receiver to target staking contract.
 */
contract YPrismaFeeDistributor is YPrismaAuthenticated {
    using SafeERC20 for IERC20;

    IERC20 public constant MKUSD =
        IERC20(0x4591DBfF62656E7859Afe5e45f6f47D3669fBB28);
    IVault public constant YVMKUSD =
        IVault(0x04AeBe2e4301CdF5E9c57B01eBdfe4Ac4B48DD13);
    IPrismaFeeDistributor public constant PRISMA_FEE_DISTRIBUTOR =
        IPrismaFeeDistributor(0x62253F7c165e34fd7343b37839bf5186a9E21D4a);
    address public immutable YPRISMA_FEE_RECEIVER;
    IStaker public immutable STAKER;

    uint public threshold;
    bool public paused;
    uint public performanceFee;
    address public feeReceiver;

    event ParamsSet(
        bool paused,
        uint threshold,
        uint performanceFee,
        address feeReceiver
    );
    event FeesDistributed(uint amount, uint fee);

    constructor(
        address _locker,
        address _yprisma_fee_receiver,
        address _staker
    ) YPrismaAuthenticated(_locker) {
        YPRISMA_FEE_RECEIVER = _yprisma_fee_receiver;
        STAKER = IStaker(_staker);
        threshold = 100e18;
        performanceFee = 1_000;
        feeReceiver = 0x93A62dA5a14C80f265DAbC077fCEE437B1a0Efde;
        MKUSD.approve(address(YVMKUSD), type(uint).max);
    }

    /**
        @notice Permissionless distribution of Yearn fees to staker users.
        @return amount amount of yvmkUSD tokens added to staker.
    */
    function distributeFees() external returns (uint amount) {
        require(!paused, "paused");
        require(canClaim(), "cannot claim");

        uint receiverBalance = MKUSD.balanceOf(YPRISMA_FEE_RECEIVER);
        if (receiverBalance > threshold) {
            MKUSD.transferFrom(
                YPRISMA_FEE_RECEIVER,
                address(this),
                receiverBalance
            );
            amount += receiverBalance;
        }
        amount += _claim();

        if (amount < threshold) return 0;

        amount = YVMKUSD.deposit(amount, address(this));

        uint fee = (amount * performanceFee) / 10_000;
        if (fee > 0) {
            amount -= fee;
            IERC20(address(YVMKUSD)).safeTransfer(feeReceiver, fee);
        }

        IERC20(address(YVMKUSD)).safeTransfer(address(STAKER), amount);

        STAKER.notifyRewardAmount(amount);

        emit FeesDistributed(amount, fee);
    }

    function _claim() internal returns (uint) {
        address[] memory tokens = new address[](1);
        tokens[0] = address(MKUSD);
        uint[] memory amounts = PRISMA_FEE_DISTRIBUTOR.claim(
            address(LOCKER),
            address(this),
            tokens
        );
        return amounts[0];
    }

    /**
        @notice Allow authorized users to configure distributor parameters
        @param _paused set to true if we should disallow claims
        @param _threshold set a minimum mkUSD threshold for which we should claim.
        @param _performanceFee fee charged on each claim.
        @param _feeReceiver fee recipient.
    */
    function setParams(
        bool _paused,
        uint _threshold,
        uint _performanceFee,
        address _feeReceiver
    ) external enforceAuth {
        require(_threshold >= 10e18 && _threshold <= 200e18);
        require(_performanceFee <= 2_000); // 20% max
        require(_feeReceiver != address(0));
        paused = _paused;
        performanceFee = _performanceFee;
        feeReceiver = _feeReceiver;
        emit ParamsSet(_paused, _threshold, _performanceFee, _feeReceiver);
    }

    /**
        @notice Helper function to determine if we have claimable tokens.
    */
    function canClaim() public view returns (bool) {
        address[] memory tokens = new address[](1);
        tokens[0] = address(MKUSD);
        uint[] memory amounts = PRISMA_FEE_DISTRIBUTOR.claimable(
            address(LOCKER),
            tokens
        );
        return amounts[0] > 0;
    }

    /**
        @notice Sweep stuck tokens to governance.
    */
    function sweep(IERC20 _token) external enforceAuth {
        uint balance = _token.balanceOf(address(this));
        if (balance > 0) {
            _token.safeTransfer(LOCKER.governance(), balance);
        }
    }
}
