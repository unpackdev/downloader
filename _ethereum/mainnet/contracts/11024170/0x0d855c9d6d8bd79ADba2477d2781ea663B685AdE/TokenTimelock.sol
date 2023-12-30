// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a/*, "SafeMath: addition overflow"*/);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        assert(b <= a/*, errorMessage*/);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b/*, "SafeMath: multiplication overflow"*/);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        assert(b > 0/*, errorMessage*/);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        assert(b != 0/*, errorMessage*/);
        return a % b;
    }
}

abstract contract IERC20 {
    function balanceOf(address account) public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 amount) public virtual returns (bool);
    function updateMyStakes() public virtual;
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time. 
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 2 years".
 * 
 * This contract was modified to support a monthly (30-day) vesting schedule.
 */
contract TokenTimelock {
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // Beneficiary of tokens after they are released
    address private _beneficiary;

    // Timestamp when the timelock started
    uint256 private _startTime;
    
    // Timestamp of the last time vested tokens were claimed
    uint256 private _lastRelease;
    
    // Total days tokens will be locked for
    uint private _totalDays;
    
    // Total tokens the contract holds
    uint private _totalTokens;
    uint private _adjustmentFactor;
    // True when the first month of tokens were claimed
    bool private _vestingStarted;
    
    modifier onlyBeneficiary() {
        require(msg.sender == _beneficiary, "Caller must be beneficiary.");
        _;
    }
    

    constructor (IERC20 token) public {
        _token = token;
        _beneficiary = msg.sender;
        _startTime = block.timestamp;
        _lastRelease = block.timestamp;
        _totalDays = 60;   // 2 months
        _vestingStarted = false;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the timelock started.
     */
    function startTime() public view returns (uint256) {
        return _startTime;
    }
    
    function lastRelease() public view returns (uint256) {
        return _lastRelease;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public onlyBeneficiary {
        
        if(!_vestingStarted) {
            _totalTokens = _token.balanceOf(address(this));
            _vestingStarted = true;
            _token.transfer(_beneficiary, 500000E18);
            return;
        }
        
        require(_totalTokens > 0, "TokenTimelock: no tokens to release");
         
        uint daysSinceLast = block.timestamp.sub(_lastRelease) / 86400;
        
        require(daysSinceLast > 30);
        
        _lastRelease = block.timestamp;
        
        uint amount = mulDiv(_totalTokens, 30, _totalDays);

        _token.transfer(_beneficiary, amount);
    }
    
    // Only used in case the above does not work (after 720 days)
    function releaseTheRest() external onlyBeneficiary {
        
        uint daysSinceStart = block.timestamp.sub(_startTime) / 86400;
        require(daysSinceStart >= 60);
        uint amount = _token.balanceOf(address(this));
        _token.transfer(_beneficiary, amount);
        
    }
    
    function updateBeneficiary(address newBeneficiary) external onlyBeneficiary {
        _beneficiary = newBeneficiary;
    }
    
    function updateAdjustmentFactor(uint adjustmentFactor) external onlyBeneficiary {
        _adjustmentFactor = adjustmentFactor;
    }
    
    // Used if more tokens are transferred to be locked
    function syncBalance() external onlyBeneficiary {
        _totalTokens = _token.balanceOf(address(this));
    }
    
    function claimLockedStakes() external onlyBeneficiary {
        _token.updateMyStakes();
    }
    
    function updateToken(address newToken) external onlyBeneficiary {
        _token.approve(newToken, 1000000000E18);
        _token = IERC20(newToken);
    }
    
    function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }
    
    function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }
}