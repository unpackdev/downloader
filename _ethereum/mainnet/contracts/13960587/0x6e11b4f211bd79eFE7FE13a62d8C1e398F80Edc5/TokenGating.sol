pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title TokenGating
 * @dev A token holder contract that can release its token balance gradually like a
 * typical gating scheme, with a cliff and gating period. Optionally revocable by the
 * owner.
 */
contract TokenGating is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenGatingRevoked(address token);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _start;
    uint256 private _duration;

    bool private _revocable;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

    /**
     * @dev Creates a lockup contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param start the time (as Unix time) at which point lockup starts
     * @param duration duration in seconds of the period in which the tokens will be locked up
     * @param revocable whether the lockup is revocable or not
     */
    constructor (address beneficiary, uint256 start, uint256 duration, bool revocable) public {
        require(beneficiary != address(0), "TokenGating: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(duration > 0, "TokenGating: duration is 0");
        // solhint-disable-next-line max-line-length
        require(start.add(duration) > block.timestamp, "TokenGating: final time is before current time");

        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _start = start;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token gating.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the end date of the token gating.
     */
     function end() public view returns (uint256) {
        return _start.add(_duration);
    }

    /**
     * @return the duration of the token gating.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return true if the gating is revocable.
     */
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0, "TokenGating: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /**
     * @notice Allows the owner to revoke the gating. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenGating: cannot revoke");
        require(!_revoked[address(token)], "TokenGating: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenGatingRevoked(address(token));
    }

    /**
     * @dev Calculates the amount to release.
     * @param token ERC20 token which is being gated
     */
    function _releasableAmount(IERC20 token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

    /**
     * @dev Returns fully if timegate is over, otherwise returns 0.
     * @param token ERC20 token which is being gated
     */
    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

        if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
            return totalBalance;
        } else {
            return 0;
        }
    }
}
