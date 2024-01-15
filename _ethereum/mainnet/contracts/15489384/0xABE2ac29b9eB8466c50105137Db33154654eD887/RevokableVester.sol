// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IStakedDVF.sol";

/**
 * @title SupporterVester
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract RevokableVester is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    // beneficiary of tokens after they are released
    address private _beneficiary;
    address public _delegateForVoting;

    modifier onlyBeneficiary() {
      require (msg.sender == _beneficiary);
      _;
    }

    IERC20 public _dvf;
    IStakedDVF public _xdvf;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    uint256 private _released;
    bool private _revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param vestingBeneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param vestingStart the time (as Unix time) at which point vesting starts
     * @param vestingDuration duration in seconds of the period in which the tokens will vest
     */
    constructor (
      address dvf,
      address xdvf,
      address vestingBeneficiary,
      uint256 vestingStart,
      uint256 cliffDuration,
      uint256 vestingDuration) public {
        require(vestingBeneficiary != address(0), "Vesting: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(cliffDuration <= vestingDuration, "Vesting: cliff is longer than duration");
        require(vestingDuration > 0, "Vesting: duration is 0");
        // solhint-disable-next-line max-line-length
        require(vestingStart.add(vestingDuration) > block.timestamp, "Vesting: final time is before current time");

        _beneficiary = vestingBeneficiary;
        _duration = vestingDuration;
        _cliff = vestingStart.add(cliffDuration);
        _start = vestingStart;
        _dvf = IERC20(dvf);
        _xdvf = IStakedDVF(xdvf);
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the nominated delegate who can vote on behalf of beneficiary
     */
    function delegateForVoting() public view returns (address) {
        if (_delegateForVoting != address(0)) return _delegateForVoting;
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return the amount of the token released.
     */
    function released() public view returns (uint256) {
        return _released;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount();

        require(unreleased > 0, "Vesting: no tokens are due");

        _released = _released.add(unreleased);

        _dvf.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(_dvf), unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = _dvf.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }

    /**
     * @notice Stakes the tokens in the vesting contract on behalf of beneficiary.
     */
    function stake() onlyBeneficiary public {
        uint256 currentBalance = _dvf.balanceOf(address(this));

        require(currentBalance > 0, "Vesting: No unstaked tokens");
        _dvf.approve(address(_xdvf), currentBalance);
        _xdvf.enter(currentBalance);
    }

    /**
     * @notice Unstakes the tokens in the vesting contract on behalf of beneficiary.
     */
    function unstake() onlyBeneficiary public {
        uint256 currentBalance = _xdvf.balanceOf(address(this));

        require(currentBalance > 0, "Vesting: No staked tokens");

        _xdvf.leave(currentBalance);
    }

    function unstakeAndRelease() onlyBeneficiary public {
        unstake();
        release();
    }

    function nominateDelegate(address _newDelegate) onlyBeneficiary public {
        _delegateForVoting = _newDelegate;
    }

    /**
    * @return true if the token is revoked.
    */
    function revoked() public view returns (bool) {
        return _revoked;
    }

    /**
    * @notice Allows the owner to revoke the vesting. Tokens already vested
    * remain in the contract, the rest are returned to the owner.
    * @param token ERC20 token which is being vested
    */
    function revoke(IERC20 token) public onlyOwner {
        require(!_revoked, "Vesting: already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount();
        uint256 refund = balance.sub(unreleased);

        _revoked = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }
}
