// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./AccessControl.sol";

import "./IERC20.sol";
import "./ITomiStaking.sol";
import "./ITomiConfig.sol";
import "./ITomiBallotFactory.sol";
import "./ITomiBallot.sol";
import "./ITomiBallotRevenue.sol";
import "./ITgas.sol";
import "./ITokenRegistry.sol";
import "./ConfigNames.sol";
import "./TransferHelper.sol";
import "./TgasStaking.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TomiGovernance is TgasStaking, Ownable, AccessControl {
    using SafeMath for uint;

    uint public version = 1;
    address public configAddr;
    address public ballotFactoryAddr;
    address public rewardAddr;
    address public stakingAddr;

    uint public T_CONFIG = 1;
    uint public T_LIST_TOKEN = 2;
    uint public T_TOKEN = 3;
    uint public T_SNAPSHOT = 4;
    uint public T_REVENUE = 5;

    uint public VOTE_DURATION;
    uint public FREEZE_DURATION;
    uint public REVENUE_VOTE_DURATION;
    uint public REVENUE_FREEZE_DURATION;
    uint public MINIMUM_TOMI_REQUIRED_IN_BALANCE = 100e18;

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256(abi.encodePacked("SUPER_ADMIN_ROLE"));
    bytes32 REVENUE_PROPOSAL = bytes32('REVENUE_PROPOSAL');
    bytes32 SNAPSHOT_PROPOSAL = bytes32('SNAPSHOT_PROPOSAL');

    mapping(address => uint) public ballotTypes;
    mapping(address => bytes32) public configBallots;
    mapping(address => address) public tokenBallots;
    mapping(address => uint) public rewardOf;
    mapping(address => uint) public ballotOf;
    mapping(address => mapping(address => uint)) public applyTokenOf;
    mapping(address => mapping(address => bool)) public collectUsers;
    mapping(address => address) public tokenUsers;

    address[] public ballots;
    address[] public revenueBallots;

    event ConfigAudited(bytes32 name, address indexed ballot, uint proposal);
    event ConfigBallotCreated(address indexed proposer, bytes32 name, uint value, address indexed ballotAddr, uint reward);
    event TokenBallotCreated(address indexed proposer, address indexed token, uint value, address indexed ballotAddr, uint reward);
    event ProposalerRewardRateUpdated(uint oldVaue, uint newValue);
    event RewardTransfered(address indexed from, address indexed to, uint value);
    event TokenListed(address user, address token, uint amount);
    event ListTokenAudited(address user, address token, uint status, uint burn, uint reward, uint refund);
    event TokenAudited(address user, address token, uint status, bool result);
    event RewardCollected(address indexed user, address indexed ballot, uint value);
    event RewardReceived(address indexed user, uint value);

    modifier onlyRewarder() {
        require(msg.sender == rewardAddr, 'TomiGovernance: ONLY_REWARDER');
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "TomiGovernance: sender not allowed to do!");
        _;
    }

    constructor (
        address _tgas, 
        uint _VOTE_DURATION,
        uint _FREEZE_DURATION,
        uint _REVENUE_VOTE_DURATION,
        uint _REVENUE_FREEZE_DURATION
    ) TgasStaking(_tgas) public {
        _setupRole(SUPER_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, SUPER_ADMIN_ROLE);

        VOTE_DURATION = _VOTE_DURATION;
        FREEZE_DURATION = _FREEZE_DURATION;
        REVENUE_VOTE_DURATION = _REVENUE_VOTE_DURATION;
        REVENUE_FREEZE_DURATION = _REVENUE_FREEZE_DURATION;
    }

    // called after deployment
    function initialize(address _rewardAddr, address _configContractAddr, address _ballotFactoryAddr, address _stakingAddr) external onlyOwner {
        require(_rewardAddr != address(0) && _configContractAddr != address(0) && _ballotFactoryAddr != address(0) && _stakingAddr != address(0), 'TomiGovernance: INPUT_ADDRESS_IS_ZERO');

        stakingAddr = _stakingAddr;
        rewardAddr = _rewardAddr;
        configAddr = _configContractAddr;
        ballotFactoryAddr = _ballotFactoryAddr;
        lockTime = getConfigValue(ConfigNames.UNSTAKE_DURATION);
    }

    function newStakingSettle(address _STAKING) external onlyRole(SUPER_ADMIN_ROLE) {
        require(stakingAddr != _STAKING, "STAKING ADDRESS IS THE SAME");
        require(_STAKING != address(0), "STAKING ADDRESS IS DEFAULT ADDRESS");
        stakingAddr = _STAKING;
    }

    function changeProposalDuration(uint[4] calldata _durations) external onlyRole(SUPER_ADMIN_ROLE) {
        VOTE_DURATION = _durations[0];
        FREEZE_DURATION = _durations[1];
        REVENUE_VOTE_DURATION = _durations[2];
        REVENUE_FREEZE_DURATION = _durations[3];
    }

    function changeTomiMinimumRequired(uint _newMinimum) external onlyRole(SUPER_ADMIN_ROLE) {
        require(_newMinimum != MINIMUM_TOMI_REQUIRED_IN_BALANCE, "TomiGovernance::Tomi required is identical!");
        MINIMUM_TOMI_REQUIRED_IN_BALANCE = _newMinimum;
    }

    // function changeProposalVoteDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != VOTE_DURATION, "TomiGovernance::Vote duration has not changed");
    //     VOTE_DURATION = _newDuration;
    // }

    // function changeProposalFreezeDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != FREEZE_DURATION, "TomiGovernance::Freeze duration has not changed");
    //     FREEZE_DURATION = _newDuration;
    // }

    // function changeRevenueProposalVoteDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != REVENUE_VOTE_DURATION, "TomiGovernance::Vote duration has not changed");
    //     REVENUE_VOTE_DURATION = _newDuration;
    // }

    // function changeRevenueProposalFreezeDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != REVENUE_FREEZE_DURATION, "TomiGovernance::Freeze duration has not changed");
    //     REVENUE_FREEZE_DURATION = _newDuration;
    // }

    function vote(address _ballot, uint256 _proposal, uint256 _collateral) external {
        require(configBallots[_ballot] != REVENUE_PROPOSAL, "TomiGovernance::Fail due to wrong ballot");
        uint256 collateralRemain = balanceOf[msg.sender]; 

        if (_collateral > collateralRemain) {
            uint256 collateralMore = _collateral.sub(collateralRemain);
            _transferForBallot(collateralMore, true, ITomiBallot(_ballot).executionTime());
        }

        ITomiBallot(_ballot).voteByGovernor(msg.sender, _proposal);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_collateral);

        _transferToStaking(_collateral);
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_collateral); 
    }

    function participate(address _ballot, uint256 _collateral) external {
        require(configBallots[_ballot] == REVENUE_PROPOSAL, "TomiGovernance::Fail due to wrong ballot");
        
        uint256 collateralRemain = balanceOf[msg.sender];
        uint256 collateralMore = _collateral.sub(collateralRemain);

        _transferForBallot(collateralMore, true, ITomiBallot(_ballot).executionTime());
        ITomiBallotRevenue(_ballot).participateByGovernor(msg.sender);
    }

    function audit(address _ballot) external returns (bool) {
        if(ballotTypes[_ballot] == T_CONFIG) {
            return auditConfig(_ballot);
        } else if (ballotTypes[_ballot] == T_LIST_TOKEN) {
            return auditListToken(_ballot);
        } else if (ballotTypes[_ballot] == T_TOKEN) {
            return auditToken(_ballot);
        } else {
            revert('TomiGovernance: UNKNOWN_TYPE');
        }
    }

    function auditConfig(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        require(result, 'TomiGovernance: NO_PASS');
        uint value = ITomiBallot(_ballot).value();
        bytes32 name = configBallots[_ballot];
        result = ITomiConfig(configAddr).changeConfigValue(name, value);
        if (name == ConfigNames.UNSTAKE_DURATION) {
            lockTime = value;
        } else if (name == ConfigNames.PRODUCE_TGAS_RATE) {
            _changeAmountPerBlock(value);
        }
        emit ConfigAudited(name, _ballot, value);
        return result;
    }

    function auditListToken(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        address token = tokenBallots[_ballot];
        address user = tokenUsers[token];
        require(ITokenRegistry(configAddr).tokenStatus(token) == ITokenRegistry(configAddr).REGISTERED(), 'TomiGovernance: AUDITED');
        uint status = result ? ITokenRegistry(configAddr).PENDING() : ITokenRegistry(configAddr).CLOSED();
	    uint amount = applyTokenOf[user][token];
        (uint burnAmount, uint rewardAmount, uint refundAmount) = (0, 0, 0);
        if (result) {
            burnAmount = amount * getConfigValue(ConfigNames.LIST_TOKEN_SUCCESS_BURN_PRECENT) / ITomiConfig(configAddr).PERCENT_DENOMINATOR();
            rewardAmount = amount - burnAmount;
            if (burnAmount > 0) {
                TransferHelper.safeTransfer(baseToken, address(0), burnAmount);
                totalSupply = totalSupply.sub(burnAmount);
            }
            if (rewardAmount > 0) {
                rewardOf[rewardAddr] = rewardOf[rewardAddr].add(rewardAmount);
                ballotOf[_ballot] = ballotOf[_ballot].add(rewardAmount);
                _rewardTransfer(rewardAddr, _ballot, rewardAmount);
            }
            ITokenRegistry(configAddr).publishToken(token);
        } else {
            burnAmount = amount * getConfigValue(ConfigNames.LIST_TOKEN_FAILURE_BURN_PRECENT) / ITomiConfig(configAddr).PERCENT_DENOMINATOR();
            refundAmount = amount - burnAmount;
            if (burnAmount > 0) TransferHelper.safeTransfer(baseToken, address(0), burnAmount);
            if (refundAmount > 0) TransferHelper.safeTransfer(baseToken, user, refundAmount);
            totalSupply = totalSupply.sub(amount);
            ITokenRegistry(configAddr).updateToken(token, status);
        }
	    emit ListTokenAudited(user, token, status, burnAmount, rewardAmount, refundAmount);
        return result;
    }

    function auditToken(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        uint status = ITomiBallot(_ballot).value();
        address token = tokenBallots[_ballot];
        address user = tokenUsers[token];
        require(ITokenRegistry(configAddr).tokenStatus(token) != status, 'TomiGovernance: TOKEN_STATUS_NO_CHANGE');
        if (result) {
            ITokenRegistry(configAddr).updateToken(token, status);
        } else {
            status = ITokenRegistry(configAddr).tokenStatus(token);
        }
	    emit TokenAudited(user, token, status, result);
        return result;
    }

    function getConfigValue(bytes32 _name) public view returns (uint) {
        return ITomiConfig(configAddr).getConfigValue(_name);
    }

    function _createProposalPrecondition(uint _amount, uint _executionTime) private {
        address sender = msg.sender;
        if (!hasRole(DEFAULT_ADMIN_ROLE, sender)) {
            require(IERC20(baseToken).balanceOf(sender).add(balanceOf[sender]) >= MINIMUM_TOMI_REQUIRED_IN_BALANCE, "TomiGovernance::Require minimum TOMI in balance");
            require(_amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
            
            uint256 collateralRemain = balanceOf[sender];

            if (_amount > collateralRemain) {
                uint256 collateralMore = _amount.sub(collateralRemain);
                _transferForBallot(collateralMore, true, _executionTime);
            } 

            collateralRemain = balanceOf[sender];
            
            require(collateralRemain >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
            balanceOf[sender] = collateralRemain.sub(_amount);

            _transferToStaking(_amount);
        }
    }

    function createRevenueBallot(
        string calldata _subject, 
        string calldata _content
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        uint endTime = block.timestamp.add(REVENUE_VOTE_DURATION);
        uint executionTime = endTime.add(REVENUE_FREEZE_DURATION);

        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).createShareRevenue(msg.sender, endTime, executionTime, _subject, _content);
        configBallots[ballotAddr] = REVENUE_PROPOSAL;
        uint reward = _createdBallot(ballotAddr, T_REVENUE);
        emit ConfigBallotCreated(msg.sender, REVENUE_PROPOSAL, 0, ballotAddr, reward);
        return ballotAddr;
    }

    function createSnapshotBallot(
        uint _amount, 
        string calldata _subject, 
        string calldata _content
    ) external returns (address) {
        uint endTime = block.timestamp.add(VOTE_DURATION);
        uint executionTime = endTime.add(FREEZE_DURATION);

        _createProposalPrecondition(_amount, executionTime);

        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(msg.sender, 0, endTime, executionTime, _subject, _content);
        
        configBallots[ballotAddr] = SNAPSHOT_PROPOSAL;
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);

        uint reward = _createdBallot(ballotAddr, T_SNAPSHOT);
        emit ConfigBallotCreated(msg.sender, SNAPSHOT_PROPOSAL, 0, ballotAddr, reward);
        return ballotAddr;
    }

    function createConfigBallot(bytes32 _name, uint _value, uint _amount, string calldata _subject, string calldata _content) external returns (address) {
        require(_value >= 0, 'TomiGovernance: INVALID_PARAMTERS');
        { // avoids stack too deep errors
        (uint minValue, uint maxValue, uint maxSpan, uint value, uint enable) = ITomiConfig(configAddr).getConfig(_name);
        require(enable == 1, "TomiGovernance: CONFIG_DISABLE");
        require(_value >= minValue && _value <= maxValue, "TomiGovernance: OUTSIDE");
        uint span = _value >= value? (_value - value) : (value - _value);
        require(maxSpan >= span, "TomiGovernance: OVERSTEP");
        }

        uint endTime = block.timestamp.add(VOTE_DURATION);
        uint executionTime = endTime.add(FREEZE_DURATION);

        _createProposalPrecondition(_amount, executionTime);
        
        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(msg.sender, _value, endTime, executionTime, _subject, _content);
        
        configBallots[ballotAddr] = _name;
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);

        uint reward = _createdBallot(ballotAddr, T_CONFIG);
        emit ConfigBallotCreated(msg.sender, _name, _value, ballotAddr, reward);
        return ballotAddr;
    }

    function createTokenBallot(address _token, uint _value, uint _amount, string calldata _subject, string calldata _content) external returns (address) {
        require(!_isDefaultToken(_token), 'TomiGovernance: DEFAULT_LIST_TOKENS_PROPOSAL_DENY');
        uint status = ITokenRegistry(configAddr).tokenStatus(_token);
        require(status == ITokenRegistry(configAddr).PENDING(), 'TomiGovernance: ONLY_ALLOW_PENDING');
        require(_value == ITokenRegistry(configAddr).OPENED() || _value == ITokenRegistry(configAddr).CLOSED(), 'TomiGovernance: INVALID_STATUS');
        require(status != _value, 'TomiGovernance: STATUS_NO_CHANGE');

        uint endTime = block.timestamp.add(VOTE_DURATION);
        uint executionTime = endTime.add(FREEZE_DURATION);

        _createProposalPrecondition(_amount, executionTime);

        address ballotAddr = _createTokenBallot(T_TOKEN, _token, _value, _subject, _content, endTime, executionTime);
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        return ballotAddr;
    }

	function listToken(address _token, uint _amount, string calldata _subject, string calldata _content) external returns (address) {
        uint status = ITokenRegistry(configAddr).tokenStatus(_token);
        require(status == ITokenRegistry(configAddr).NONE() || status == ITokenRegistry(configAddr).CLOSED(), 'TomiGovernance: LISTED');
	    // require(_amount >= getConfigValue(ConfigNames.LIST_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_LIST");
	    tokenUsers[_token] = msg.sender;

        uint endTime = block.timestamp.add(VOTE_DURATION);
        uint executionTime = endTime.add(FREEZE_DURATION);

        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            require(_amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
            
            uint256 collateralRemain = balanceOf[msg.sender]; 
            uint256 collateralMore = _amount.sub(collateralRemain);
            
            applyTokenOf[msg.sender][_token] = _transferForBallot(collateralMore, true, executionTime);
            collateralRemain = balanceOf[msg.sender];

            require(collateralRemain >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
            balanceOf[msg.sender] = collateralRemain.sub(_amount);

            _transferToStaking(_amount);
        }

	    ITokenRegistry(configAddr).registryToken(_token);
        address ballotAddr = _createTokenBallot(T_LIST_TOKEN, _token, ITokenRegistry(configAddr).PENDING(), _subject, _content, endTime, executionTime);
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        emit TokenListed(msg.sender, _token, _amount);
        return ballotAddr;
	}

    function _createTokenBallot(uint _type, address _token, uint _value, string memory _subject, string memory _content, uint _endTime, uint _executionTime) private returns (address) {
        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(msg.sender, _value, _endTime, _executionTime, _subject, _content);
        
        uint reward = _createdBallot(ballotAddr, _type);
        ballotOf[ballotAddr] = reward;
        tokenBallots[ballotAddr] = _token;
        emit TokenBallotCreated(msg.sender, _token, _value, ballotAddr, reward);
        return ballotAddr;
    }

    function collectReward(address _ballot) external returns (uint) {
        require(block.timestamp >= ITomiBallot(_ballot).endTime(), "TomiGovernance: NOT_YET_ENDED");
        require(!collectUsers[_ballot][msg.sender], 'TomiGovernance: REWARD_COLLECTED');
        require(configBallots[_ballot] == REVENUE_PROPOSAL, "TomiGovernance::Fail due to wrong ballot");
        
        uint amount = getRewardForRevenueProposal(_ballot);
        _rewardTransfer(_ballot, msg.sender, amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        stakingSupply = stakingSupply.add(amount);
        rewardOf[msg.sender] = rewardOf[msg.sender].sub(amount);
        collectUsers[_ballot][msg.sender] = true;
       
        emit RewardCollected(msg.sender, _ballot, amount);
    }

    // function getReward(address _ballot) public view returns (uint) {
    //     if (block.timestamp < ITomiBallot(_ballot).endTime() || collectUsers[_ballot][msg.sender]) {
    //         return 0;
    //     }
    //     uint amount;
    //     uint shares = ballotOf[_ballot];

    //     bool result = ITomiBallot(_ballot).result();

    //     if (result) {
    //         uint extra;
    //         uint rewardRate = getConfigValue(ConfigNames.VOTE_REWARD_PERCENT);
    //         if ( rewardRate > 0) {
    //            extra = shares * rewardRate / ITomiConfig(configAddr).PERCENT_DENOMINATOR();
    //            shares -= extra;
    //         }
    //         if (msg.sender == ITomiBallot(_ballot).proposer()) {
    //             amount = extra;
    //         }
    //     }

    //     if (ITomiBallot(_ballot).total() > 0) {  
    //         uint reward = shares * ITomiBallot(_ballot).weight(msg.sender) / ITomiBallot(_ballot).total();
    //         amount += ITomiBallot(_ballot).proposer() == msg.sender ? 0: reward;
    //     }
    //     return amount;
    // }

    function getRewardForRevenueProposal(address _ballot) public view returns (uint) {
        if (block.timestamp < ITomiBallotRevenue(_ballot).endTime() || collectUsers[_ballot][msg.sender]) {
            return 0;
        }
        
        uint amount = 0;
        uint shares = ballotOf[_ballot];

        if (ITomiBallotRevenue(_ballot).total() > 0) {  
            uint reward = shares * ITomiBallotRevenue(_ballot).weight(msg.sender) / ITomiBallotRevenue(_ballot).total();
            amount += ITomiBallotRevenue(_ballot).proposer() == msg.sender ? 0 : reward; 
        }
        return amount;
    }

    // TOMI TEST ONLY
    // function addReward(uint _value) external onlyRewarder returns (bool) {
    function addReward(uint _value) external returns (bool) {
        require(_value > 0, 'TomiGovernance: ADD_REWARD_VALUE_IS_ZERO');
        uint total = IERC20(baseToken).balanceOf(address(this));
        uint diff = total.sub(totalSupply);
        require(_value <= diff, 'TomiGovernance: ADD_REWARD_EXCEED');
        rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_value);
        totalSupply = total;
        emit RewardReceived(rewardAddr, _value);
    }

    function _rewardTransfer(address _from, address _to, uint _value) private returns (bool) {
        require(_value >= 0 && rewardOf[_from] >= _value, 'TomiGovernance: INSUFFICIENT_BALANCE');
        rewardOf[_from] = rewardOf[_from].sub(_value);
        rewardOf[_to] = rewardOf[_to].add(_value);
        emit RewardTransfered(_from, _to, _value);
    }

    function _isDefaultToken(address _token) internal returns (bool) {
        address[] memory tokens = ITomiConfig(configAddr).getDefaultListTokens();
        for(uint i = 0 ; i < tokens.length; i++){
            if (tokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function _transferForBallot(uint _amount, bool _wallet, uint _endTime) internal returns (uint) {
        if (_wallet && _amount > 0) {
            _add(msg.sender, _amount, _endTime);
            TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
            totalSupply += _amount;
        } 

        if (_amount == 0) allowance[msg.sender] = estimateLocktime(msg.sender, _endTime);

        return _amount;
    }

    function _transferToStaking(uint _amount) internal {
        if (stakingAddr != address(0)) {
            TransferHelper.safeTransfer(baseToken, stakingAddr, _amount);
            ITomiStaking(stakingAddr).updateRevenueShare(_amount);
        }
    }

    function _createdBallot(address _ballot, uint _type) internal returns (uint) {
        uint reward = 0;
        
        if (_type == T_REVENUE) {
            reward = rewardOf[rewardAddr];
            ballotOf[_ballot] = reward;
            _rewardTransfer(rewardAddr, _ballot, reward);
        }

        _type == T_REVENUE ? revenueBallots.push(_ballot): ballots.push(_ballot);
        ballotTypes[_ballot] = _type;
        return reward;
    }

    function ballotCount() external view returns (uint) {
        return ballots.length;
    }

    function ballotRevenueCount() external view returns (uint) {
        return revenueBallots.length;
    }

    function _changeAmountPerBlock(uint _value) internal returns (bool) {
        return ITgas(baseToken).changeInterestRatePerBlock(_value);
    }

    function updateTgasGovernor(address _new) external onlyOwner {
        ITgas(baseToken).upgradeGovernance(_new);
    }

    function upgradeApproveReward() external returns (uint) {
        require(rewardOf[rewardAddr] > 0, 'TomiGovernance: UPGRADE_NO_REWARD');
        require(ITomiConfig(configAddr).governor() != address(this), 'TomiGovernance: UPGRADE_NO_CHANGE');
        TransferHelper.safeApprove(baseToken, ITomiConfig(configAddr).governor(), rewardOf[rewardAddr]);
        return rewardOf[rewardAddr]; 
    }

    function receiveReward(address _from, uint _value) external returns (bool) {
        require(_value > 0, 'TomiGovernance: RECEIVE_REWARD_VALUE_IS_ZERO');
        TransferHelper.safeTransferFrom(baseToken, _from, address(this), _value);
        rewardOf[rewardAddr] += _value;
        totalSupply += _value;
        emit RewardReceived(_from, _value);
        return true;
    }

}