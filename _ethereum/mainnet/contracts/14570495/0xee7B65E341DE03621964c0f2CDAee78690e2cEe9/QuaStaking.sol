// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./AccessControl.sol";

contract QuaStaking is AccessControl {

    uint256 constant private MONTH = 60 * 60 * 24 * 30;
    uint256 constant private DAY = 60 * 60 * 24;
    uint256 constant private PERSENT_BASE = 10000;

    IERC20 public immutable token;
    uint256 public lockedAmount;
    address public commissionAddress;

    Pool[3] public pools;
    mapping(address => DepositInfo[]) public addressToDepositInfo;

    struct DepositInfo {
        uint256 amount;
        uint256 start;
        uint256 poolId;
        uint256 maxUnstakeAmount;
    }

    struct Pool {
        uint64 APY;
        uint8 timeLockUp;
        uint64 commission;
    }

    event TokensStaked(
        address user, 
        uint256 amount, 
        uint256 poolId, 
        uint256 timestamp
    );

    event Withdraw(
        address user, 
        uint256 amount, 
        uint256 poolId, 
        bool earlyWithdraw
    );

    event WithdrawExcess(address user, uint256 amount);

    /**
     * @dev setup DEFAULT_ADMIN_ROLE to deployer
     * @param _owner address of admin
     * @param _commissionAddress address to which the commission is sent 
     * @param _token address of ERC20 token Quarashi 
     * @param  _APY = 0.0055/0,0125/0,028 * 10000, 
     * @param _commission = 0.01/0.03/0.08 * 10000, 
     * @param _timeLockUp = 1/6/12
     */
    constructor(
        address _owner,
        address _commissionAddress,
        IERC20 _token, 
        uint8[3] memory _timeLockUp, 
        uint64[3] memory _APY, 
        uint64[3] memory _commission
    ) 
    {
        require(address(_token) != address(0), "Zero token address");
        token = _token;
        require(_owner != address(0), "Zero owner address");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        require(_commissionAddress != address(0), "Zero commission address");
        commissionAddress = _commissionAddress;

        Pool memory pool; 
        for (uint256 i; i < 3; i++) {
            pool = Pool(_APY[i], _timeLockUp[i], _commission[i]);
            pools[i] = (pool);
        }
    }

    /**
     * @param _commissionAddress new address to which the commission is sent 
     */
    function setCommissionAddress(address _commissionAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        commissionAddress = _commissionAddress;
    }

    /** 
     * @notice Create deposit for msg.sender with input params
     * @dev tokens must be approved for contract before call this func
     * @dev fires TokensStaked event
     * @param amount - initial balance of deposit
     * @param _poolId - id of pool of deposit,
     * = 0 for 1 month, 1 for 6 months, 2 for 12 months
     */
    function stake(uint256 amount, uint256 _poolId) external {
        require(
            token.balanceOf(_msgSender()) >= amount, 
            "Token: balance too low"
        );
        require(_poolId < pools.length, "Pool: wrong pool");

        uint256 _maxUnstakeAmount = amount;
        for (uint256 i; i < pools[_poolId].timeLockUp; i++) {
            _maxUnstakeAmount += _maxUnstakeAmount * pools[_poolId].APY / PERSENT_BASE;
        }
        lockedAmount += _maxUnstakeAmount;

        DepositInfo memory deposit = DepositInfo(
            amount, 
            block.timestamp, 
            _poolId,
            _maxUnstakeAmount
        );
        addressToDepositInfo[_msgSender()].push(deposit);

        
        require(
            lockedAmount <= token.balanceOf(address(this)) + amount, 
            "Token: do not have enouth tokens for reward"
        );

        require(
            token.transferFrom(_msgSender(), address(this), amount), 
            "Token: token did not transfer"
        );

        emit TokensStaked(_msgSender(), amount, _poolId, block.timestamp);
    }

    /** 
     * @notice Withdraw deposit with _depositInfoId for caller,
     * allow early withdraw, fire Withdraw event
     * @param _depositInfoId - id of deposit of caller
     */
    function withdraw(uint256 _depositInfoId) external {
        require(
            _depositInfoId < addressToDepositInfo[_msgSender()].length,
            "Pool: wrong staking id"
        );
        
        DepositInfo memory deposit = addressToDepositInfo[_msgSender()][_depositInfoId];
        require(deposit.amount != 0, "Deposit: tokens already been sended");

        uint256 amount;
        bool earlyWithdraw;
        uint256 commissionAmount;
        (amount, earlyWithdraw, commissionAmount) = getRewardAmount(_msgSender(), _depositInfoId);
        
        delete addressToDepositInfo[_msgSender()][_depositInfoId];
        lockedAmount -= deposit.maxUnstakeAmount;

        if (commissionAmount > 0) {
            require(
                token.transfer(commissionAddress, commissionAmount),
                "Token: can not transfer commission"
            );
        }
        require(
            token.transfer(_msgSender(), amount), 
            "Token: can not transfer reward"
        );
        
        emit Withdraw(_msgSender(), amount, deposit.poolId, earlyWithdraw);
    }

    /** 
     * @notice Withdraw excess of tokens from this contract,
     * can be called only by admin,
     * excess = balanceOf(this) - all deposits amount + max rewards,
     * fire WithdrawExcess event
     */
    function withdrawExcess() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = token.balanceOf(address(this)) - lockedAmount;
        require(amount > 0, "Token: do not have excess tokens");
        require(
            token.transfer(_msgSender(), amount),
            "Token: can not transfer excess"
        );

        emit WithdrawExcess(_msgSender(), amount);
    }

    /**
     * @notice Return all deposits of msg.sender, 
     * include unstaked deposits (with 0 amount)
     * @return amounts - initial balance of deposit[i] 
     * @return starts - start time of deposit[i]
     * @return poolIds - id of pool of deposit[i], 
     * = 0 for 1 month, 1 for 6 months, 2 for 12 months
     */
    function getDepositInfo(address _user) external view returns (
            uint256[] memory, 
            uint256[] memory, 
            uint256[] memory
        ) 
    {
        uint256 depositsAmount = addressToDepositInfo[_user].length;
        uint256[] memory amounts = new uint256[](depositsAmount);
        uint256[] memory starts = new uint256[](depositsAmount);
        uint256[] memory poolIds = new uint256[](depositsAmount);

        for (uint256 i; i < depositsAmount; i++) {
            amounts[i] = addressToDepositInfo[_user][i].amount;
            starts[i] = addressToDepositInfo[_user][i].start;
            poolIds[i] = addressToDepositInfo[_user][i].poolId;
        }

        return (amounts, starts, poolIds);
    }

    /**
     * @notice Return reward amount of deposit with input params if unstake it now
     * @param _user - address of deposit holder
     * @param _depositInfoId - id of deposit of _user
     * @return amount - reward amount = initial balance + reward - commission, 
     * if early unstake, else = initial balance + reward
     * @return earlyWithdraw - if early unstake = true, else = false 
     * @return commissionAmount - amount of tokens written off for an early unstake,
     * = 0 otherwise 
     */
    function getRewardAmount(
        address _user,
        uint256 _depositInfoId
    ) public view returns (
            uint256, 
            bool,
            uint256
        ) 
    {
        DepositInfo memory deposit = addressToDepositInfo[_user][_depositInfoId];
        Pool memory pool = pools[deposit.poolId];

        bool earlyWithdraw = true;
        if (deposit.start + MONTH * pool.timeLockUp <= block.timestamp) {
            earlyWithdraw = false;
        }
        uint256 amount;
        uint256 commissionAmount;

        if (earlyWithdraw) {
            amount = deposit.amount;
            uint256 stakingMonths = (block.timestamp - deposit.start) / MONTH;
            uint256 stakingDays = (block.timestamp - deposit.start) % MONTH / DAY;
            for (uint256 i; i < stakingMonths; i++) {
                amount += amount * pool.APY  / PERSENT_BASE;
            }
            amount += amount * pool.APY * stakingDays / 30 / PERSENT_BASE;
            commissionAmount = deposit.amount * pool.commission / PERSENT_BASE;
            amount -= commissionAmount;
        } else {
            amount = deposit.maxUnstakeAmount;
        }

        return (amount, earlyWithdraw, commissionAmount);
    }

}