pragma solidity ^0.7;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract LPStaker is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    IUniswapV2Pair public pair;
    IERC20 public token;

    uint public reserve;
    uint public totalLpStaked;

    struct Deposit {
        address owner;
        uint amount;
        uint date;
    }
    struct Withdrawal {
        address owner;
        uint date;
        uint outstandingTokens;
        bool completed;
    }
    mapping(address => uint[]) public depositsByUser;
    mapping(address => uint[]) public withdrawalsByUser;
    mapping(uint => Deposit) public depositStorage;
    mapping(uint => Withdrawal) public withdrawalStorage;
    uint public lastDepositId;
    uint public lastWithdrawalId;

    event Deposited(address sender, uint amount, uint date);
    event Withdrawn(address sender, uint amount, uint date);
    event Rewarded(address sender, uint tokenAmount, uint date);
    constructor () {
        pair = IUniswapV2Pair(0xA8d852A4D5F79860816D7503E6457Ac47964809D);
        token = IERC20(0xBEc6Cf25aFB79b975E57b93f3216e468F8FED910);
    }

    function withdraw (uint orderId, uint lpAmount) public nonReentrant {
        address sender = address(msg.sender);
        Deposit storage _deposit = depositStorage[orderId];

        require(_deposit.amount >= lpAmount, "Not enough balance");
        require(_deposit.owner == sender, "Not authorized");

        uint timeSinceDeposit = block.timestamp - _deposit.date;
        uint daysBeforeFullRelease = 6 * 30;
        uint totalReward = calculateCurrentReward(_deposit.date, lpAmount);
        uint sentTokens;

        if (timeSinceDeposit / 1 days > daysBeforeFullRelease) {
            sentTokens = totalReward;
        } else {
            sentTokens = totalReward.div(3);

            Withdrawal memory _withdrawal = Withdrawal({
                owner: sender,
                date: _deposit.date,
                outstandingTokens: sentTokens.mul(2),
                completed: false
            });

            storeWithdrawal(_withdrawal, sender);
        }

        _withdrawFromContract(sender, lpAmount);
        _withdrawTokensFromContract(sender, sentTokens);

        emit Withdrawn (sender, lpAmount, block.timestamp);
        emit Rewarded (sender, sentTokens, block.timestamp);
        
        _deposit.amount = _deposit.amount.sub(lpAmount);
    }

    function claimOutstandingReward (uint rewardId) nonReentrant public {
        uint daysBeforeFullRelease = 6 * 30;
        Withdrawal storage _withdrawal = withdrawalStorage[rewardId];

        require(_withdrawal.completed == false, "Already completed");
        require((_withdrawal.date - block.timestamp) / 1 days > daysBeforeFullRelease, "Date not reached");

        _withdrawal.completed = true;

        _withdrawTokensFromContract(_withdrawal.owner, _withdrawal.outstandingTokens);

        emit Rewarded(_withdrawal.owner, _withdrawal.outstandingTokens, block.timestamp);
    }

    function calculateCurrentReward (uint date, uint lpAmount) public view returns (uint) {
        uint stakedMinutes = (block.timestamp - date) / 1 minutes;

        return getLpTokenWorth(lpAmount)
            .div(100)
            .div(66)
            .div(525600)
            .mul(stakedMinutes > 525600 ? 525600 : stakedMinutes);
    }

    function deposit (uint lpAmount) public nonReentrant {
        address sender = address(msg.sender);

        _depositToContract(sender, lpAmount);
        uint totalReserveDamage = getLpTokenWorth(totalLpStaked).div(100).mul(66) + getLpTokenWorth(lpAmount).div(100).mul(66);

        require(totalReserveDamage > reserve, "Not enough tokens in reserve");

        Deposit memory newDeposit = Deposit({
            owner: sender,
            amount: lpAmount,
            date: block.timestamp
        });

        storeDeposit(newDeposit, sender);

        emit Deposited(sender, lpAmount, block.timestamp);
    }

    function addReserve (uint amount) public onlyOwner {
        _depositTokensToContract(address(msg.sender), amount);

        reserve = reserve.add(amount);
    }

    function removeFromReserve (uint amount) public onlyOwner {
        require(amount <= reserve);

        reserve = reserve.sub(amount);

        _withdrawTokensFromContract(address(msg.sender), amount);
    }

    function _withdrawFromContract (address owner, uint amount) private {
        pair.transfer(owner, amount);
        totalLpStaked = totalLpStaked.sub(amount);
    }

    function _depositToContract (address owner, uint amount) private {
        uint allowance = pair.allowance(owner, address(this));
        require(allowance >= amount, "Contract not allowed to spend specified amount");
        totalLpStaked = totalLpStaked.add(amount);
        pair.transferFrom(owner, address(this), amount);
    }

    function _depositTokensToContract (address owner, uint amount) private {
        uint allowance = token.allowance(owner, address(this));
        require(allowance >= amount, "Contract not allowed to spend specified amount");

        reserve = reserve.add(amount);

        token.transferFrom(owner, address(this), amount);
    }

    function _withdrawTokensFromContract (address owner, uint amount) private {
        reserve = reserve.sub(amount);

        token.transfer(owner, amount);
    }

    function getTotalTokenSupply () public view returns (uint) {
        uint112 totalTokens;
        (totalTokens,,) = pair.getReserves();

        return uint(totalTokens);
    }

    function getTokensPerLp () public view returns (uint) {
        uint totalTokenSupply = getTotalTokenSupply();
        uint totalLpAmount = pair.totalSupply();
        uint decimals = 10 ** pair.decimals();

        return (totalTokenSupply * decimals) / totalLpAmount;
    }

    function getLpTokenWorth (uint lpAmount) public view returns (uint) {
        uint decimalPoints = 10 ** pair.decimals();
        return getTokensPerLp().mul(lpAmount.div(decimalPoints));
    }

    function storeDeposit (Deposit memory _deposit, address sender) private {
        depositStorage[lastDepositId] = _deposit;
        withdrawalsByUser[sender].push(lastDepositId);
        lastDepositId++;
    }

    function storeWithdrawal (Withdrawal memory _withdrawal, address sender) private {
        withdrawalStorage[lastWithdrawalId] = _withdrawal;
        withdrawalsByUser[sender].push(lastWithdrawalId);
        lastWithdrawalId++;
    }
}