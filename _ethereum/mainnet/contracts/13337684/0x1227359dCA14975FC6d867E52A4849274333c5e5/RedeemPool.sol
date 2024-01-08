// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router.sol";
import "./Operator.sol";
import "./IBurnProxy.sol";

interface IRedeemPool {
    event RedeemStart(address indexed starter, uint256 reward);
    event DepositBond(address indexed owner, uint256 amount);
    event RewardClaimed(address indexed owner, uint256 amount);
    event ReCharge(
        address indexed owner,
        address indexed token,
        uint256 indexed rid,
        uint256 amount
    );
    event ReChargeETH(
        address indexed owner,
        uint256 indexed rid,
        uint256 amount
    );
    event Withdrawal(
        address indexed from,
        address indexed to,
        uint256 indexed at
    );

    function rechargeCash(uint256 _rid, uint256 _amount) external;
}

contract RedeemPool is IRedeemPool, Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Redeemseat {
        uint256 lastSnapshotIndex;
        uint256 deposit;
        uint256 rewardEarned;
    }

    struct RedeemSnapshot {
        uint256 start;
        uint256 end;
        uint256 rewardAll;
        uint256 deposit;
        uint256 maxDeposit;
        uint256 rewardPerBond;
    }

    RedeemSnapshot[] public history;
    mapping(address => Redeemseat) public seats;

    // rid => reward amount
    mapping(uint256 => uint256) public currentReward;
    mapping(uint256 => uint256) public lastReward;
    mapping(uint256 => uint256) public historyReward;

    address public bond;
    address public cash;
    address public swapRouter;
    address public burn;
    uint256 public cashToClaim = 0;
    uint256 public nextEpoch;
    uint256 public limitRatio = 1e19;
    uint256 public period = 86400;
    uint256 public epochDuration = 30 days;

    constructor(
        address _bond,
        address _cash,
        uint256 _nextEpoch,
        address _swapRouter
    ) {
        bond = _bond;
        cash = _cash;
        nextEpoch = _nextEpoch;
        swapRouter = _swapRouter;
        history.push(
            RedeemSnapshot({
                start: 0,
                end: block.timestamp,
                deposit: 0,
                maxDeposit: 0,
                rewardAll: 0,
                rewardPerBond: 0
            })
        );
    }

    function lastSnapshotIndex() public view returns (uint256) {
        return history.length.sub(1);
    }

    function canDeposit() public view returns (bool) {
        if (history[lastSnapshotIndex()].end >= block.timestamp) {
            return true;
        }
        if (block.timestamp < nextEpoch) {
            return false;
        }
        if (IERC20(cash).balanceOf(address(this)).sub(cashToClaim) > 0) {
            return true;
        }
        return false;
    }

    function setPeriod(uint256 _period) public onlyOperator {
        period = _period;
    }

    function setNextEpoch(uint256 _nextEpoch) public onlyOperator {
        nextEpoch = _nextEpoch;
    }

    function setEpochDuration(uint256 _epochDuration) public onlyOperator {
        epochDuration = _epochDuration;
    }

    function setLimitRatio(uint256 _limitRatio) public onlyOperator {
        limitRatio = _limitRatio;
        RedeemSnapshot memory snapShot = history[lastSnapshotIndex()];
        if (snapShot.end >= block.timestamp) {
            snapShot.maxDeposit = snapShot.rewardAll.mul(limitRatio).div(1e18);
        }
        history[lastSnapshotIndex()] = snapShot;
    }

    function setSwapRouter(address _swapRouter) public onlyOwner {
        swapRouter = _swapRouter;
    }

    function setBurn(address _burn) public onlyOwner {
        burn = _burn;
    }

    function startRedeem() public onlyOperator {
        _startRedeem();
    }

    function _startRedeem() internal {
        uint256 index = lastSnapshotIndex();
        require(
            block.timestamp > history[index].end,
            'last period have not end'
        );
        uint256 cashRemain = history[index].rewardAll.sub(
            history[index].rewardPerBond.mul(history[index].deposit).div(1e18)
        );

        cashToClaim = cashToClaim - cashRemain;

        uint256 rewardAll = IERC20(cash).balanceOf(address(this)).sub(
            cashToClaim
        );
        require(rewardAll > 0, 'require cash balance gt 0');

        cashToClaim = cashToClaim.add(rewardAll);
        history.push(
            RedeemSnapshot({
                start: block.timestamp,
                end: block.timestamp.add(period),
                deposit: 0,
                maxDeposit: rewardAll.mul(limitRatio).div(1e18),
                rewardAll: rewardAll,
                rewardPerBond: 0
            })
        );
        nextEpoch = nextEpoch.add(period).add(epochDuration);

        for (uint256 i = 0; i < 4; i++) {
            lastReward[i] = currentReward[i];
            currentReward[i] = 0;
        }
        _burnBond();
        emit RedeemStart(_msgSender(), rewardAll);
    }

    function _burnBond() internal {
        if (IERC20(bond).balanceOf(address(this)) <= 0) {
            return;
        }
        IERC20(bond).approve(burn, IERC20(bond).balanceOf(address(this)));
        IBurnProxy(burn).burnFrom(
            address(this),
            IERC20(bond).balanceOf(address(this))
        );
    }

    function burnBond() public onlyOperator {
        _burnBond();
    }

    function deposit(uint256 _amount) public updateReward(_msgSender()) {
        address director = _msgSender();
        uint256 index = lastSnapshotIndex();
        RedeemSnapshot memory snapShot = history[index];
        // start redeem by user
        if (block.timestamp > nextEpoch && block.timestamp > snapShot.end) {
            _startRedeem();
            index = lastSnapshotIndex();
            snapShot = history[index];
        }
        require(
            block.timestamp >= snapShot.start &&
                block.timestamp <= snapShot.end,
            'not in redeem period'
        );
        require(
            snapShot.deposit.add(_amount) <= snapShot.maxDeposit,
            'deposit overflow'
        );
        snapShot.deposit = snapShot.deposit.add(_amount);
        snapShot.rewardPerBond = snapShot.rewardAll.mul(1e18).div(
            snapShot.deposit
        );
        if (snapShot.rewardPerBond > 1e18) {
            snapShot.rewardPerBond = 1e18;
        }
        history[index] = snapShot;

        IERC20(bond).safeTransferFrom(director, address(this), _amount);

        Redeemseat memory seat = seats[director];
        seat.lastSnapshotIndex = index;
        seat.deposit = seat.deposit.add(_amount);
        seats[director] = seat;
        emit DepositBond(director, _amount);
    }

    function claimReward() public {
        _claimRewad(_msgSender());
    }

    function claimRewadFor(address _director) public {
        _claimRewad(_director);
    }

    function _claimRewad(address _director) internal updateReward(_director) {
        Redeemseat memory seat = seats[_director];
        uint256 reward = seat.rewardEarned;
        if (reward == 0) {
            return;
        }

        cashToClaim = cashToClaim.sub(reward);
        IERC20(cash).safeTransfer(_director, reward);
        seat.rewardEarned = 0;
        seats[_director] = seat;

        emit RewardClaimed(_director, reward);
    }

    function rechargeCash(uint256 _rid, uint256 _amount) public override {
        recharge(_rid, cash, _amount);
    }

    /**
     * @param _rid 0 donate 1 vault  2 profile 3 seigniorge
     */
    function recharge(
        uint256 _rid,
        address _token,
        uint256 _amount
    ) public {
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        if (_token == cash) {
            currentReward[_rid] = currentReward[_rid].add(_amount);
            historyReward[_rid] = historyReward[_rid].add(_amount);
        }

        emit ReCharge(_msgSender(), _token, _rid, _amount);
    }

    function rechargeETH(uint256 _rid) public payable {
        emit ReChargeETH(_msgSender(), _rid, msg.value);
    }

    function currentRewardDetail()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (block.timestamp > history[lastSnapshotIndex()].end) {
            return (
                IERC20(cash).balanceOf(address(this)).sub(cashToClaim),
                currentReward[0],
                currentReward[1],
                currentReward[2],
                currentReward[3]
            );
        }
        return (
            history[lastSnapshotIndex()].rewardAll,
            lastReward[0],
            lastReward[1],
            lastReward[2],
            lastReward[3]
        );
    }

    modifier updateReward(address _director) {
        uint256 rewardNew = rewardEarned(_director);
        Redeemseat memory seat = seats[_director];
        if (seat.rewardEarned == rewardNew) {
            _;
            return;
        }
        seat.rewardEarned = rewardNew;
        seat.deposit = 0;
        seats[_director] = seat;
        _;
    }

    function rewardEarned(address _director) public view returns (uint256) {
        Redeemseat memory seat = seats[_director];
        if (seat.deposit == 0) {
            return seat.rewardEarned;
        }
        uint256 lastIndex = lastSnapshotIndex();
        if (
            seat.lastSnapshotIndex == lastIndex &&
            history[lastIndex].end >= block.timestamp
        ) {
            return seat.rewardEarned;
        }
        return
            seat.rewardEarned.add(
                seat
                    .deposit
                    .mul(history[seat.lastSnapshotIndex].rewardPerBond)
                    .div(1e18)
            );
    }

    function historySnapShot() public view returns (uint256, uint256) {
        uint256 totalDeposit = 0;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < history.length; i++) {
            totalDeposit = totalDeposit.add(history[i].deposit);
            totalReward = totalReward.add(history[i].rewardAll);
        }
        return (totalDeposit, totalReward);
    }

    function migrate(uint256 amount, address to) public onlyOwner {
        IERC20(cash).safeTransfer(to, amount);
        emit Withdrawal(_msgSender(), to, block.timestamp);
    }

    function swap(
        address token,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) public onlyOperator {
        if (amountIn > IERC20(token).balanceOf(address(this))) {
            amountIn = IERC20(token).balanceOf(address(this));
        }
        require(amountIn > 0, 'token insufficient');
        uint256 cashBefore = IERC20(cash).balanceOf(address(this));
        IERC20(token).approve(swapRouter, amountIn);
        IUniswapV2Router01(swapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 10 days
        );
        uint256 amount = IERC20(cash).balanceOf(address(this)).sub(cashBefore);

        uint256 rid = 0;
        currentReward[rid] = currentReward[rid].add(amount);
        historyReward[rid] = historyReward[rid].add(amount);
    }

    function swapETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) public onlyOperator {
        if (amountIn > address(this).balance) {
            amountIn = address(this).balance;
        }
        require(amountIn > 0, 'eth insufficient');
        uint256 cashBefore = IERC20(cash).balanceOf(address(this));
        IUniswapV2Router01(swapRouter).swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            address(this),
            block.timestamp + 10 days
        );
        uint256 amount = IERC20(cash).balanceOf(address(this)).sub(cashBefore);

        uint256 rid = 0;
        currentReward[rid] = currentReward[rid].add(amount);
        historyReward[rid] = historyReward[rid].add(amount);
    }
}
