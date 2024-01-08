// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title Vesting
 * @dev Token vesting contract for investors
 */
contract Vesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address account, uint256 amount);
    event VestingRevoked(address account);

    string public name = "Token Vesting";

    // vesting token
    IERC20 public token;

    // vesting is revocable or not
    bool public revocable;

    // investors and allocated token amount
    struct Investor {
        address investor;
        uint256 allocated;
        uint256 initialRelease;
        uint256 start;
        uint256 duration;
        uint256 released;
    }
    Investor[] private investors;
    mapping (address => uint256) private investorMap;
    mapping (address => bool) private revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param _revocable whether the vesting is revocable or not
     */
    constructor (
        address _token,
        bool _revocable
    ) {
        require(_token != address(0), "Vesting: invalid token address");
        token = IERC20(_token);
        revocable = _revocable;
    }

    /**
     * @notice Add investors.
     */
    function add(
        address investor,
        uint256 allocated,
        uint256 initialRelase,
        uint256 duration_
    ) public onlyOwner {
        // solhint-disable-next-line max-line-length
        require(investor != address(0), "Vesting: investor is the zero address");
        require(investorMap[investor] == 0, "Vesting: investor exists");
        uint256 initial = allocated.mul(initialRelase).div(100);
        investors.push(Investor(
            investor,
            allocated,
            initial,
            block.timestamp,
            duration_,
            0
        ));
        investorMap[investor] = investors.length;
    }

    /**
     * @return the allocation of investor.
     */
    function allocation(address investor) public view returns (uint256) {
        return investors[investorMap[investor] - 1].allocated;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start(address investor) public view returns (uint256) {
        return investors[investorMap[investor] - 1].start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration(address investor) public view returns (uint256) {
        return investors[investorMap[investor] - 1].duration;
    }

    /**
     * @return the amount of the token initially released.
     */
    function initialRelease(address investor) public view returns (uint256) {
        return investors[investorMap[investor] - 1].initialRelease;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address investor) public view returns (uint256) {
        return investors[investorMap[investor] - 1].released;
    }

    function releasable(address investor) public view returns (uint256) {
        return _releasableAmount(investor);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount(msg.sender);

        require(unreleased > 0, "Vesting: no tokens are due");

        investors[investorMap[msg.sender] - 1].released = investors[investorMap[msg.sender] - 1].released.add(unreleased);

        token.safeTransfer(msg.sender, unreleased);

        emit TokensReleased(msg.sender, unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param _revoke address which is being vested
     */
    function revoke(address _revoke) public onlyOwner {
        require(revocable, "Vesting: cannot revoke");
        require(!revoked[_revoke], "Vesting: token already revoked");

        uint256 balance = allocation(_revoke);
        require(balance > 0, "Vesting: no allocation");

        uint256 unreleased = _releasableAmount(_revoke);
        uint256 refund = balance.sub(unreleased);
        require(refund > 0, "Vesting: no refunds");

        revoked[_revoke] = true;

        token.safeTransfer(owner(), refund);

        emit VestingRevoked(_revoke);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param investor address which is being vested
     */
    function _releasableAmount(address investor) private view returns (uint256) {
        return _vestedAmount(investor).add(initialRelease(investor)).sub(released(investor));
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param investor address which is being vested
     */
    function _vestedAmount(address investor) private view returns (uint256) {
        uint256 totalBalance = allocation(investor).sub(initialRelease(investor));

        if (block.timestamp >= start(investor).add(duration(investor)) || revoked[investor]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start(investor))).div(duration(investor));
        }
    }
}
