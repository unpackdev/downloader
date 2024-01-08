// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./Rex.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract EvolveToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    
	using SafeMathUpgradeable for uint256;

	uint256 public UNCOMMON_RATE; 
	uint256 public RARE_RATE; 
	uint256 public LEGENDARY_RATE; 
	uint256 public MYTHICAL_RATE; 
	uint256 public GENESIS_RATE; 
	uint256 public END; 
	uint256 public START; 

	mapping(address => uint256) public claimable;
	mapping(address => uint256) public lastUpdate;

	Rex public REX_CONTRACT;

    function initialize(string memory name_, string memory symbol_) public initializer {
        __Ownable_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        UNCOMMON_RATE = 1 ether;
        RARE_RATE = 5 ether;
        LEGENDARY_RATE = 15 ether;
        MYTHICAL_RATE = 60 ether;
        GENESIS_RATE = 30 ether;
        END = 1798761599;
        START = 1798761599;
    }

    function setRexContract(address _rex) external onlyOwner {
        REX_CONTRACT = Rex(_rex);
    }

    function enableEarning() external onlyOwner {
        START = block.timestamp;
    }

    function setEnd(uint256 _timestamp) external onlyOwner {
        END = _timestamp;
    }

    function setGenesisRate(uint256 _rate) external onlyOwner {
        GENESIS_RATE = _rate;
    }

    function setUncommonRate(uint256 _rate) external onlyOwner {
        UNCOMMON_RATE = _rate;
    }

    function setRareRate(uint256 _rate) external onlyOwner {
        RARE_RATE = _rate;
    }

    function setLegendaryRate(uint256 _rate) external onlyOwner {
        LEGENDARY_RATE = _rate;
    }

    function setMythicalRate(uint256 _rate) external onlyOwner {
        MYTHICAL_RATE = _rate;
    }

	function updateClaimable(address _from, address _to) external {
		require(msg.sender == address(REX_CONTRACT), "not allowed");
        if(START <= block.timestamp){
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom == 0){
                timerFrom = START;
            }
            updateClaimableFor(_from,timerFrom);
            delete timerFrom;

            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];
                if (timerTo == 0){
                    timerTo = START;
                }
                updateClaimableFor(_to,timerTo);
                delete timerTo;
            }
        }
	}

    function updateClaimableFor(address _owner, uint256 _timer) internal {
        uint256 pending = getPendingClaimable(_owner, _timer);
        claimable[_owner] += pending;
        if (_timer != END) {
            uint256 time = min(block.timestamp, END);
			lastUpdate[_owner] = time;
            delete time;
        }
        delete pending;
    }

	function claimTokens(address _to) external {
		require(msg.sender == address(REX_CONTRACT));
		uint256 canClaim = claimable[_to];
		if (canClaim > 0) {
			claimable[_to] = 0;
			_mint(_to, canClaim);
		}
        delete canClaim;
	}

	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(REX_CONTRACT));
		_burn(_from, _amount);
	}

    function getPendingClaimable(address _owner, uint256 _timer) internal view returns(uint256){
        uint256 pending = 0;
        uint256 time = min(block.timestamp, END);
        pending += REX_CONTRACT.balanceGenesis(_owner).mul(GENESIS_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceUncommon(_owner).mul(UNCOMMON_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceRare(_owner).mul(RARE_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceLegendary(_owner).mul(LEGENDARY_RATE.mul((time.sub(_timer)))).div(86400);
        pending += REX_CONTRACT.balanceMythical(_owner).mul(MYTHICAL_RATE.mul((time.sub(_timer)))).div(86400);
        return pending;
    }

	function getTotalClaimable(address _user) external view returns(uint256) {
        uint256 pending = 0;
        if(START <= block.timestamp){
            uint256 timerFrom = lastUpdate[_user];
            if (timerFrom == 0){
                timerFrom = START;
            }
            pending += getPendingClaimable(_user, timerFrom);
            delete timerFrom;
        }
		return claimable[_user] + pending;
	}

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

}