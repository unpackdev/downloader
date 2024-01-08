pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
* @title TokenVesting
* @dev A token holder contract that can release its token balance gradually like a
* typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
* owner.
*/
contract Vesting is Ownable, ReentrancyGuard {

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public immutable beneficiary;

  uint256 public immutable cliff;
  uint256 public immutable start;
  uint256 public immutable duration;
  uint256 public immutable initialAllocation;
 
  bool public immutable revokable;
  bool public revoked;
  bool public complete;

  uint256 public released;
  IERC20 public mxsToken;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revokable whether the vesting is revocable or not
   ** @param _initialAllocation the initial allocation of tokens, used to find reflections
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool    _revokable,
    uint256 _initialAllocation,
    address _mxsToken
  ) {
    require(_beneficiary != address(0), "The beneficiary address is zero address");
    require(_cliff <= _duration, "The cliff is larger than duration");
   
    beneficiary = _beneficiary;
    start       = _start;
    cliff       = _start + _cliff;
    duration    = _duration;
    revokable   = _revokable;
    initialAllocation = _initialAllocation;
    mxsToken = IERC20(_mxsToken);

    bool approved = mxsToken.approve( owner(), type(uint256).max);
    require(approved, "Transfer token failed");
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() onlyOwner external returns(uint256 tokenAmount) {
    require(block.timestamp >= cliff, "Cliff has not been reached yet");
    tokenAmount = _releaseTo(beneficiary);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function _releaseTo(address target) internal nonReentrant returns(uint256) {
    uint256 unreleased = releasableAmount();
    released = released + unreleased;
    
    bool transferred = mxsToken.transfer(target, unreleased);
    require(transferred, "Transfer token failed");

    if (mxsToken.balanceOf(address(this)) == 0) {
        complete = true;
    }
    emit Released(released);
    return(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested are sent to the beneficiary.
   */
  function revoke() onlyOwner external {
    require(revokable, "It's not revokable");
    require(!revoked, "It's already revoked");

    // Release all vested tokens
    _releaseTo(beneficiary);

    // Send the remainder to the owner
    bool transferred = mxsToken.transfer(owner(), mxsToken.balanceOf(address(this)));
    require(transferred, "Transfer token failed");

    revoked = true;
    complete = true;
    emit Revoked();
  }


  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function releasableAmount() public view returns (uint256) {
    return vestedAmount() - released;
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount() public view returns (uint256) {
    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start + duration || revoked) {
      uint256 vested = mxsToken.balanceOf(address(this)) + released;
      // vesting is complete, allocate all tokens
      return vested;
    } else {
      uint256 vested = initialAllocation * (block.timestamp - start) / duration;
      return vested;
    }
  }
 
    /**
   * @dev Calculates the amount of reflections the vesting contract has received.
   */
  function reflections() external view returns (uint256) {
    return mxsToken.balanceOf(address(this)) + released - initialAllocation;
  }

    /**
   * @dev Calculates the amount of time remaining in seconds.
   */
  function timeRemaining() external view returns (uint256) {
      return start + duration - block.timestamp;
  }
 
  /**
   * @notice Allow withdrawing any token other than the relevant one
   */
  function releaseForeignToken(IERC20 _token, uint256 amount) external onlyOwner {
    require(_token != mxsToken, "The token is mxsToken");
    bool transferred = _token.transfer(owner(), amount);
    require(transferred, "Transfer token failed");
  }
}

