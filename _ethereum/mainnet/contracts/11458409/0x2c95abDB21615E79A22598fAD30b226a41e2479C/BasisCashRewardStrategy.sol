// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseStrategy.sol";

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Uni.sol";
import "./IBoardRoom.sol";
import "./ITreasury.sol";
import "./console.sol";
import "./AttendanceRules.sol";

contract BasisCashRewardStrategy is BaseStrategy, AttendanceRules {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address internal constant UNIROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address internal constant BAC = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bool private preparingReturn = false;

    modifier prepare() {
        preparingReturn = true;
        _;
        preparingReturn = false;
    }


    IBoardRoom private board;

    IUniswap private uniswap;

    IERC20 private reward;


    constructor(
        address _vault,
        address _boardRoom
    ) public BaseStrategy(_vault) {
        board = IBoardRoom(_boardRoom);

        reward = IERC20(BAC);

        uniswap = IUniswap(UNIROUTER);
        //approve uniswap for bac
        reward.safeApprove(address(uniswap), uint256(- 1));
        //bas token approval to boardroom for staking
        want.safeApprove(address(board), uint256(- 1));
    }

    function ethToWant(uint256 _amount) public view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = address(want);
        uint256[] memory amounts = uniswap.getAmountsOut(_amount, path);

        return amounts[amounts.length - 1];
    }

    function _swapRewardForWant(uint256 _amount) internal {
        address[] memory path = new address[](3);

        path[0] = BAC;
        path[1] = DAI;
        path[2] = address(want);

        uint256[] memory amounts = uniswap.getAmountsOut(_amount, path);
        uint256 amountOut = amounts[amounts.length - 1];
        uniswap.swapExactTokensForTokens(
            _amount,
            amountOut,
            path,
            address(this),
            block.timestamp
        );
    }

    function name() external pure override returns (string memory) {
        return "BasisCashRewardStrategy";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        //what about unclaimed rewards, is why estimate, rewards are claimed on exit
        return balanceWant().add(balanceShares()).add(balanceReward());
    }

    function harvestTrigger(uint256 _callCost) public view override returns (bool) {
        return super.harvestTrigger(ethToWant(_callCost));
    }

    function prepareReturn(uint256 _debtOutstanding)
    internal
    override
    prepare
    returns (
        uint256 _profit,
        uint256 _loss,
        uint256 _debtPayment
    )
    {

        // Try to pay debt asap
        if (_debtOutstanding > 0) {
            uint256 _amountFreed = liquidatePosition(_debtOutstanding);
            // Using Math.min() since we might free more than needed
            _debtPayment = Math.min(_amountFreed, _debtOutstanding);
        }


        if (!emergencyExit) {
            board.claimReward();
        }
        // if we have any basis cash, sell it for basis shares
        // This is done in a separate step since there might have been
        // a migration or an exitPosition
        uint256 rewardBalance = balanceReward();

        if (rewardBalance > 0) {
            // This might be > 0 because of a strategy migration

            uint256 totalWantIncludingSharesBeforeSwap = balanceWant().add(balanceShares());
            _swapRewardForWant(rewardBalance);
            _profit = balanceWant().add(balanceShares()).sub(totalWantIncludingSharesBeforeSwap);
        }

    }


    function adjustPosition(uint256 _debtOutstanding) internal override {
        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        if (balanceWant() > 0 && !visitThisBlock()) {// if we had to visit the boardroom already this block we can't go again
            _stakeWant(balanceWant());
        }
    }

    function exitPosition(uint256 _debtOutstanding)
    internal
    oneBlockOneVisit
    override
    returns (
        uint256 _profit,
        uint256 _loss,
        uint256 _debtPayment
    )
    {
        board.exit();
        return prepareReturn(_debtOutstanding);
    }

    function _withdrawStakedWant(uint256 _amount) internal oneBlockOneVisit {
        board.withdraw(_amount);
    }

    function _stakeWant(uint256 _amount) internal oneBlockOneVisit {
        board.stake(_amount);
    }

    //the boardroom only allows one withdraw or one stake per block per user/including contract
    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed) {
        if (balanceWant() < _amountNeeded) {
            _withdrawStakedWant(_amountNeeded.sub(balanceWant()));
        }

        _amountFreed = balanceWant();
    }

    function prepareMigration(address _newStrategy) internal override {
        //ensure we leave with nothing left in the boardroom.
        board.exit();
        want.safeTransfer(_newStrategy, balanceWant());
        reward.safeTransfer(_newStrategy, balanceReward());
    }

    function protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = DAI;
        protected[1] = BAC;

        return protected;
    }

    function balanceReward() public view returns (uint256) {
        return reward.balanceOf(address(this));
    }

    function balanceWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceShares() public view returns (uint256) {
        return board.balanceOf(address(this));
    }
}