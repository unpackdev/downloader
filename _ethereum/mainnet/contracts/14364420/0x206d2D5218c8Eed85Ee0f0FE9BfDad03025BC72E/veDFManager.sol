//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./veDFCore.sol";

contract veDFManager is veDFCore {
    IERC20Upgradeable public DF;

    event SupplySDF(uint256 amount);

    constructor(
        IveDF _veDF,
        IStakedDF _sDF,
        IERC20Upgradeable _rewardToken,
        uint256 _startTime,
        address _rewardDistributor
    ) public {
        initialize(_veDF, _sDF, _rewardToken, _startTime, _rewardDistributor);
    }

    function initialize(
        IveDF _veDF,
        IStakedDF _sDF,
        IERC20Upgradeable _rewardToken,
        uint256 _startTime,
        address _rewardDistributor
    ) public override {
        require(
            _sDF.DF() == IRewardDistributor(_rewardDistributor).rewardToken(),
            "veDFManager: vault distribution token error"
        );

        require(
            address(_sDF) == address(_rewardToken),
            "veDFManager: Distributed as SDF"
        );

        super.initialize(_veDF, _sDF, _rewardToken, _startTime, _rewardDistributor);
        DF = IERC20Upgradeable(_sDF.DF());
        DF.safeApprove(address(sDF), uint256(-1));
    }

    ///@notice Supply SDF to be distributed
    ///@param _amount DF amount
    function supplySDFUnderlying(uint256 _amount) public onlyOwner {
        require(
            _amount > 0,
            "veDFManager: supply SDF Underlying amount must greater than 0"
        );
        DF.safeTransferFrom(rewardDistributor, address(this), _amount);
        sDF.stake(address(this), _amount);
        emit SupplySDF(_amount);
    }

    ///@notice Supply SDF to be distributed
    ///@param _amount sDF amount
    function supplySDF(uint256 _amount) external onlyOwner {
        require(_amount > 0, "veDFManager: supply SDF amount must greater than 0");

        //Calculate the number of needed DF based on _exchangeRate
        uint256 _exchangeRate = sDF.getCurrentExchangeRate();
        uint256 _underlyingAmount = _amount.rmul(_exchangeRate);
        supplySDFUnderlying(_underlyingAmount);
    }

    /**
     * @notice Lock DF and harvest veDF, One operation will DF lock
     * @dev Create lock-up information and mint veDF on lock-up amount and duration.
     * @param _amount DF token amount.
     * @param _dueTime Due time timestamp, in seconds.
     */
    function createInOne(uint256 _amount, uint256 _dueTime)
        external
        sanityCheck(_amount)
        isDueTimeValid(_dueTime)
        updateReward(msg.sender)
    {
        DF.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _sDFAmount = sDF.stake(address(this), _amount);

        uint256 _duration = _dueTime.sub(block.timestamp);
        uint256 _veDFAmount = veDF.create(msg.sender, _sDFAmount, _duration);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Create(msg.sender, _sDFAmount, _duration, _veDFAmount);
    }

    function refillInOne(uint256 _amount)
        external
        sanityCheck(_amount)
        updateReward(msg.sender)
    {
        DF.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _sDFAmount = sDF.stake(address(this), _amount);

        uint256 _veDFAmount = veDF.refill(msg.sender, _sDFAmount);

        (uint32 _dueTime, , ) = veDF.getLocker(msg.sender);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Refill(msg.sender, _sDFAmount, _veDFAmount);
    }

    ///@param _increment The number of DF added to the original number of locked warehouses
    function refreshInOne(uint256 _increment, uint256 _dueTime)
        external
        isDueTimeValid(_dueTime)
        nonReentrant
        updateReward(msg.sender)
    {
        (, , uint256 _lockedSDF) = veDF.getLocker(msg.sender);
        uint256 _newSDF = _lockedSDF;

        if (_increment > 0) {
            DF.safeTransferFrom(msg.sender, address(this), _increment);
            uint256 _incrementSDF = sDF.stake(address(this), _increment);
            _newSDF = _newSDF.add(_incrementSDF);
        }

        uint256 _duration = _dueTime.sub(block.timestamp);
        uint256 _oldVEDFAmount = balances[msg.sender];
        (uint256 _newVEDFAmount, ) = veDF.refresh(msg.sender, _newSDF, _duration);

        balances[msg.sender] = _newVEDFAmount;
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;

        totalSupply = totalSupply.add(_newVEDFAmount).sub(_oldVEDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_newVEDFAmount);
        accSettledBalance = accSettledBalance.sub(_oldVEDFAmount);

        emit Refresh(
            msg.sender,
            _lockedSDF,
            _newSDF,
            _duration,
            _oldVEDFAmount,
            _newVEDFAmount
        );
    }

    function _withdraw() internal {
        (, , uint96 _lockedSDF) = veDF.getLocker(msg.sender);
        uint256 _burnVEDF = veDF.withdraw(msg.sender);
        uint256 _oldBalance = balances[msg.sender];

        totalSupply = totalSupply.sub(_oldBalance);
        balances[msg.sender] = balances[msg.sender].sub(_oldBalance);

        //Since totalsupply is reduced and the operation must be performed after the lock expires,
        //accsettledbalance should be reduced at the same time
        accSettledBalance = accSettledBalance.sub(_oldBalance);

        uint256 _DFAmount = sDF.unstake(address(this), _lockedSDF);
        DF.safeTransfer(msg.sender, _DFAmount);

        emit Withdraw(msg.sender, _burnVEDF, _oldBalance);
    }

    function getReward() public override updateReward(msg.sender) {
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, _reward);
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function getRewardInOne() public updateReward(msg.sender) {
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            uint256 _DFAmount = sDF.unstake(address(this), _reward);
            DF.safeTransfer(msg.sender, _DFAmount);
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function exit2() external {
        getReward();
        _withdraw();
    }

    function exitInOne() external {
        getRewardInOne();
        _withdraw();
    }

    function earnedInOne(address _account)
        public
        updateReward(_account)
        returns (uint256 _reward)
    {
        _reward = rewards[_account];
        if (_reward > 0) {
            uint256 _exchangeRate = sDF.getCurrentExchangeRate();
            _reward = _reward.rmul(_exchangeRate);
        }
    }
}
