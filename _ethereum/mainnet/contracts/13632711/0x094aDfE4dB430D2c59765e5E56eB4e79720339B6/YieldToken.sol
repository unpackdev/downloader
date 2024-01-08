// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <= 0.9.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ILions.sol";

contract YieldToken is ERC20("SexyToken", "SEXY") {
	using SafeMath for uint256;
    using Address for address;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	uint256 constant public BASE_RATE = 1 ether; 
	uint256 constant public INITIAL_ISSUANCE = 10 ether;

    uint256 constant public REWARD_SEPARATOR = 86400;

    mapping(address => mapping(address => uint256)) rewards;
    mapping(address => mapping(address => uint256)) lastUpdates;

    mapping(address => uint256) rewardsEnd;
    address[] contracts;

    address owner; 

	event RewardPaid(address indexed user, uint256 reward);

    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier isContract() {
        require(msg.sender.isContract(), "Address isn`t a contract");
        _;
    }

    modifier isValidAddress() {
        bool _found;
        for(uint i=0; i<contracts.length; i++) {
            if(contracts[i] == msg.sender) {
                _found = true;
                break;
            }
        }

        require(_found, "Address is not one of permissioned addresses");
        _;
    }

	constructor() {
        owner = msg.sender;
        _mint(0x85A5F069C4f2C34C2Aa49611e84b634193d0923b, 1000000000000000000000000000);
        _mint(0x1D23a28C71b5daC1b0F3Af101666d7184b299032, 50000000000000000000000000);
	}

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        
        address _oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function updateRewardOnMint(address _user, uint256 _amount) external isValidAddress isContract {
        address _contract = msg.sender;
        uint256 _rewardTime = rewardsEnd[_contract];

		uint256 _time = min(block.timestamp, _rewardTime);
        
		uint256 _lastUpdate = lastUpdates[_contract][_user];
        if (_rewardTime <= _lastUpdate){
            rewards[_contract][_user] += _amount.mul(INITIAL_ISSUANCE);
        }else {
            if (_lastUpdate > 0)
                rewards[_contract][_user] = rewards[_contract][_user].add(ILions(_contract).balanceOG(_user).mul(BASE_RATE.mul(_time.sub(_lastUpdate))).div(REWARD_SEPARATOR)
                    .add(_amount.mul(INITIAL_ISSUANCE)));
            else 
                rewards[_contract][_user] = rewards[_contract][_user].add(_amount.mul(INITIAL_ISSUANCE));
        }

        lastUpdates[_contract][_user] = block.timestamp;
	}

	// called on transfers
	function updateReward(address _from, address _to) external isValidAddress isContract{
        address _contract = msg.sender;
        _updateReward(_contract, _from, _to);
    }

    function _updateReward(address _contract, address _from, address _to) internal {
        uint256 _rewardTime = rewardsEnd[_contract];

        uint256 _time = min(block.timestamp, _rewardTime);
        uint256 _lastUpdate = lastUpdates[_contract][_from];
        if(_rewardTime >= _lastUpdate) {
            if (_lastUpdate > 0)
                rewards[_contract][_from] += ILions(_contract).balanceOG(_from).mul(BASE_RATE.mul(_time.sub(_lastUpdate))).div(REWARD_SEPARATOR);
            if (_lastUpdate != _rewardTime)
                lastUpdates[_contract][_from] = _time;
            if (_to != address(0)) {
                uint256 _timerTo = lastUpdates[_contract][_to];
                if (_timerTo > 0)
                    rewards[_contract][_to] += ILions(_contract).balanceOG(_to).mul(BASE_RATE.mul(_time.sub(_timerTo))).div(REWARD_SEPARATOR);
                if (_timerTo != _rewardTime)
                    lastUpdates[_contract][_to] = _time;
            }
        }
    }


	function getReward(address _to) external isValidAddress isContract {
		getReward(msg.sender, _to);
	}

    function getReward(address _contract, address _to) internal {
        uint256 reward = rewards[_contract][_to];
		if (reward > 0) {
			rewards[_contract][_to] = 0;
			_mint(_to, reward);
			emit RewardPaid(_to, reward);
		}
    }

	function burn(address _from, uint256 _amount) external {
        if(msg.sender.isContract()) {
		    _burn(_from, _amount);
        }else if(msg.sender == owner) {
            _burn(msg.sender, _amount);
        }
	}

	function getTotalClaimable(address _user) external view isValidAddress isContract returns(uint256) {
        address _contract = msg.sender;
        uint256 _rewardTime = rewardsEnd[_contract];

		uint256 _time = min(block.timestamp, _rewardTime);
        uint256 _lastUpdate = lastUpdates[_contract][_user];
    
		        
		return (_rewardTime >= _lastUpdate)? rewards[_contract][_user] +  ILions(msg.sender).balanceOG(_user).mul(BASE_RATE.mul((_time.sub(_lastUpdate)))).div(REWARD_SEPARATOR) : rewards[_contract][_user];
	}

    function addContract(address _contract, uint256 _rewardTime) public onlyOwner {
        require(_contract.isContract(), "Address isn't a contract");
        contracts.push(_contract);
        rewardsEnd[_contract] = block.timestamp + _rewardTime;
    }

    function getAllRewards() public {
        for(uint i=0; i<contracts.length; i++) {
            _updateReward(contracts[i], msg.sender, address(0));
            getReward(contracts[i], msg.sender);
        }
    }
}