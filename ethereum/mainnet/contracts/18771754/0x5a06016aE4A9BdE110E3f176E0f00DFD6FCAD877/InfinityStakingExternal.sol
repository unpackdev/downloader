// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

interface DividendPayingContractOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingContractInterface {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

contract DividendPayingContract is DividendPayingContractInterface, DividendPayingContractOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
                                                                         
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  uint256 public totalDividendsDistributed;

  receive() external payable {
    distributeDividends();
  }

  function distributeDividends() public override payable {
    if(totalBalance > 0 && msg.value > 0){
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (msg.value).mul(magnitude) / totalBalance
        );
        emit DividendsDistributed(msg.sender, msg.value);

        totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);

      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) external view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) external view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }
}


contract DividendTracker is DividendPayingContract {

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() {}

    function getAccount(address _account)
        public view returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 balance) {
        account = _account;

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        balance = holderBalance[account];
    }
    function setBalance(address payable account, uint256 newBalance) internal {

        _setBalance(account, newBalance);

    	processAccount(account, true);
    }
    
    function processAccount(address payable account, bool automatic) internal returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDividendsDistributed;
    }

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return holderBalance[account];
	}

    function getNumberOfDividends() external view returns(uint256) {
        return totalBalance;
    }
}


contract InfinityStakingExternal is Ownable, ReentrancyGuard, DividendTracker {

    IERC20 public immutable token;
    address public externalWallet;


    mapping (address => uint256) public holderUnlockTime;
    uint256 public lockDuration;

    event Staked(address user, uint256 amount);
    event Unstaked(address user, uint256 amount);

    constructor(address _token, uint256 _lockPeriodWeeks, address _externalWallet) {
        require(_token != address(0), "cannot be 0 address");
        token = IERC20(_token);

        externalWallet = _externalWallet;
        
        lockDuration = _lockPeriodWeeks * 1 weeks;       
    }


    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Stake amount must be greater than zero");

        if(holderUnlockTime[msg.sender] == 0) {
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        }

        uint256 userAmount = holderBalance[msg.sender];

        uint256 amountTransferred = 0;

        uint256 initialBalance = token.balanceOf(externalWallet);
        token.transferFrom(address(msg.sender), externalWallet, _amount);
        amountTransferred = token.balanceOf(externalWallet) - initialBalance;
    
        setBalance(payable(msg.sender), userAmount + amountTransferred);

        emit Staked(msg.sender, _amount);
    }


    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Unstake amount must be greater than zero");

        uint256 userAmount = holderBalance[msg.sender];
        require(_amount <= userAmount, "Not enough tokens");
        require(holderUnlockTime[msg.sender] <= block.timestamp, "May not withdraw early");

        token.transferFrom(externalWallet, address(msg.sender), _amount);

        setBalance(payable(msg.sender), userAmount - _amount);

        if(userAmount > 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        } else {
            holderUnlockTime[msg.sender] = 0;
        }

        emit Unstaked(msg.sender, _amount);
    }

    function returnBalance(address _staker) external view returns (uint256) {
        return holderBalance[_staker];
    }

    function withdrawAll() public nonReentrant {
        uint256 userAmount = holderBalance[msg.sender];
        require(userAmount > 0, "No tokens to withdraw");
        require(holderUnlockTime[msg.sender] <= block.timestamp, "Withdrawal locked");

        require(token.transfer(address(msg.sender), userAmount), "Transfer failed");
        token.transferFrom(externalWallet, address(msg.sender), userAmount);

        holderBalance[msg.sender] = 0;
        holderUnlockTime[msg.sender] = 0;

        emit Unstaked(msg.sender, userAmount);
    }

    function claim() external nonReentrant {
        processAccount(payable(msg.sender), false);
    }

    
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
    }
 
}