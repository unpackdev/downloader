import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Stakeable is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 private initialTimestamp;
    uint256 private timePeriod;
    uint256 private maxPositions = 1;
    uint256 private MinStakeValueToClosePosition = 100000000000000000;
    address private StakingAccount = 0x0000000000000000000000000000000000000000;
    bool private MoveFundsUponReceipt = false;
    bool private ClaimWithinContract = true;
    bool private MovePercentageOfFundsUponReceipt = false;
    uint256 private MovePercentageBasisNumber = 500; // =5%
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event Withdrawn(address indexed, uint256 amount, uint256 timestamp);
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 _plan,
        uint256 timePeriod
    );

    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));

    constructor() {
        stakeholders.push();
    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 since; // time since staked
        uint256 rewardPerHour;
        uint256 timePeriod;
        uint256 reward;
    }
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    struct StakingSummary {
        Stake[] stakes;
    }

    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakes;

    function _addStakeholder(address staker) private returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _stake(
        uint256 _amount,
        uint256 _rewardPerHour,
        uint256 _timePeriodInSeconds,
        address _Sender
    ) internal {
        require(StakingAccount != address(0), "Staking account not set.");
        require(canStake(_Sender), "Already have max open positions.");
        if (MoveFundsUponReceipt == true) {
            payable(StakingAccount).transfer(_amount);
        }
        if (MovePercentageOfFundsUponReceipt == true) {
            payable(StakingAccount).transfer(
                _amount.mul(MovePercentageBasisNumber).div(1000000)
            );
        }
        uint256 index = stakes[_Sender];
        uint256 timestamp = block.timestamp;
        if (index == 0) {
            index = _addStakeholder(_Sender);
        }
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
        stakeholders[index].address_stakes.push(
            Stake(
                payable(_Sender),
                _amount,
                timestamp,
                _rewardPerHour,
                timePeriod,
                0
            )
        );
        emit Staked(
            _Sender,
            _amount,
            index,
            timestamp,
            _rewardPerHour,
            timePeriod
        );
    }

    function _stake_noKeys(
        uint256 _amount,
        uint256 _rewardPerHour,
        uint256 _timePeriodInSeconds,
        address _Sender,
        uint256 _startTime
    ) internal {
        require(StakingAccount != address(0), "Staking account not set.");
        require(canStake(_Sender), "Already have max open positions.");
        if (MoveFundsUponReceipt == true) {
            payable(StakingAccount).transfer(_amount);
        }
        if (MovePercentageOfFundsUponReceipt == true) {
            payable(StakingAccount).transfer(
                _amount.mul(MovePercentageBasisNumber).div(1000000)
            );
        }
        uint256 index = stakes[_Sender];
        uint256 timestamp = _startTime;
        if (index == 0) {
            index = _addStakeholder(_Sender);
        }
        initialTimestamp = _startTime;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
        stakeholders[index].address_stakes.push(
            Stake(
                payable(_Sender),
                _amount,
                timestamp,
                _rewardPerHour,
                timePeriod,
                0
            )
        );
        emit Staked(
            _Sender,
            _amount,
            index,
            timestamp,
            _rewardPerHour,
            timePeriod
        );
    }

    function calculateStakeReward(Stake memory _current_stake)
        private
        view
        returns (uint256)
    {
        return
            (
                ((block.timestamp.sub(_current_stake.since)).div(1 hours))
                    .mul(_current_stake.amount)
                    .mul(_current_stake.rewardPerHour)
            ).div(1000000);
    }

    function _withdrawStake(uint256 amount, uint256 index)
        internal
        returns (uint256)
    {
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "Claim: Address not registered in contract.");
        require(
            index <= maxPositions - 1,
            "Claim: Index out of range for Max Open Positions"
        );
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(
            current_stake.amount > 0,
            "Claim: No active positions for this address."
        );
        uint256 reward = calculateStakeReward(current_stake);
        require(reward > 0, "Claim: Claim not ready yet.");
        uint256 claimable = current_stake.amount.add(reward);
        require(
            amount <= claimable,
            "Claim: Claim amount is higher than total claimable."
        );
        require(
            address(this).balance > amount,
            "Claim: Not enough balance in Contract"
        );
        require(
            block.timestamp >= current_stake.timePeriod,
            "Claim: Not matured yet."
        );
        uint256 _current_stake_amount = claimable.sub(amount);
        if (_current_stake_amount < MinStakeValueToClosePosition) {
            delete stakeholders[user_index].address_stakes[index];
            stakeholders[user_index].address_stakes[index] = stakeholders[
                user_index
            ].address_stakes[
                    stakeholders[user_index].address_stakes.length - 1
                ];
            stakeholders[user_index].address_stakes.pop();
        } else {
            stakeholders[user_index]
                .address_stakes[index]
                .amount = _current_stake_amount;
            stakeholders[user_index].address_stakes[index].since = block
                .timestamp;
        }
        if (ClaimWithinContract == true) {
            payable(msg.sender).transfer(amount);
            amount = 0;
        }
        emit Withdrawn(msg.sender, amount, block.timestamp);
        return amount;
    }

    function hasStake(address _staker, uint256 index)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            index <= maxPositions - 1,
            "Stake: Index out of range for Max Open Positions"
        );
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        require(
            summary.stakes.length > 0,
            "Stake: No active positions for this address."
        );
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].reward = availableReward;
        }
        return (
            summary.stakes[index].user,
            summary.stakes[index].amount,
            summary.stakes[index].since,
            summary.stakes[index].rewardPerHour,
            summary.stakes[index].timePeriod,
            summary.stakes[index].reward
        );
    }

    function canStake(address _staker) private view returns (bool result) {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        if (summary.stakes.length >= maxPositions) {
            return false;
        }
        return true;
    }

    function setMaxPositions(uint256 _maxPositions) external onlyRole(ADMIN) {
        maxPositions = _maxPositions;
    }

    function getMaxPositions() external view returns (uint256) {
        return maxPositions;
    }

    //@notice: co-exists with minStakeValue
    function setMinStakeValueToClosePosition(
        uint256 _MinStakeValueToClosePosition
    ) external onlyRole(ADMIN) {
        MinStakeValueToClosePosition = _MinStakeValueToClosePosition;
    }

    function getMinStakeValueToClosePosition() external view returns (uint256) {
        return MinStakeValueToClosePosition;
    }

    function setStakingAccount(address _StakingAccount)
        external
        onlyRole(ADMIN)
    {
        StakingAccount = _StakingAccount;
    }

    function setClaimWithinContract(bool _ClaimWithinContract)
        external
        onlyRole(ADMIN)
    {
        ClaimWithinContract = _ClaimWithinContract;
    }

    function setMoveFundsUponReceipt(bool _MoveFundsUponReceipt)
        external
        onlyRole(ADMIN)
    {
        MoveFundsUponReceipt = _MoveFundsUponReceipt;
    }

    function getMoveFundsUponReceipt() external view returns (bool) {
        return MoveFundsUponReceipt;
    }

    function setMovePercentageBasisNumber(uint256 _MovePercentageBasisNumber)
        external
        onlyRole(ADMIN)
    {
        MovePercentageBasisNumber = _MovePercentageBasisNumber;
    }

    function getMovePercentageBasisNumber() external view returns (uint256) {
        return MovePercentageBasisNumber;
    }

    function setMovePercentageOfFundsUponReceipt(
        bool _MovePercentageOfFundsUponReceipt
    ) external onlyRole(ADMIN) {
        MovePercentageOfFundsUponReceipt = _MovePercentageOfFundsUponReceipt;
    }

    function getMovePercentageOfFundsUponReceipt()
        external
        view
        returns (bool)
    {
        return MovePercentageOfFundsUponReceipt;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Role: Not authorized.");
        _;
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _grantRole(_role, _account);
    }

    function _revokeRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _revokeRole(_role, _account);
    }
}
