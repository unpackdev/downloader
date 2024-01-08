// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Ownable.sol";
// import "./AccessControl.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuard.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenSwap is Ownable, ReentrancyGuard {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Create a new role identifier for the whitelisted role
    // bytes32 public constant TEAM_MEMBER = keccak256("TEAM_MEMBER");

    event OldTokensReceived(
        address token,
        uint256 value,
        address from,
        address to
    );

    event NewTokensSent(
        address token,
        uint256 value,
        address from,
        address to
    );

    // The token being sold
    IERC20Upgradeable private _oldToken;

    // The token being sold
    IERC20Upgradeable private _newToken;

    // Swap rate
    uint256 private constant _swapRate = 1;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param __oldToken Address of the token being sold
     * @param __newToken Address of the token being bought
     */
    constructor (
        IERC20Upgradeable __oldToken,
        IERC20Upgradeable __newToken
    ) {
        require(address(__newToken) != address(0), "TokenVesting: token is the zero address");
        require(address(__oldToken) != address(0), "TokenVesting: token is the zero address");
        // solhint-disable-next-line max-line-length

        _oldToken = __oldToken;
        _newToken = __newToken;
        // _setupRole(TEAM_MEMBER, _beneficiary);
    }

    /**
     * @return the token being sold.
     */
    function oldToken() public view returns (IERC20Upgradeable) {
        return _oldToken;
    }

    /**
     * @return the token being bought.
     */
    function newToken() public view returns (IERC20Upgradeable) {
        return _newToken;
    }

    /**
     * @return the swap rate for tokens.
     */
    function swapRate() public pure returns (uint256) {
        return _swapRate;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function swap() public nonReentrant {

        uint256 oldBalance = _oldToken.balanceOf(_msgSender());
        
        //Add the 1% which will be taken as transaction on the new token as well
        uint256 newBalance = oldBalance.mul(_swapRate); 

        _oldToken.safeTransferFrom(_msgSender(), this.owner(), oldBalance);

        emit OldTokensReceived(address(_oldToken), oldBalance, _msgSender(), this.owner());

        _newToken.safeTransferFrom(this.owner(), _msgSender(), newBalance);

        emit NewTokensSent(address(_newToken), newBalance, this.owner(), _msgSender());

    }

    /**
     * @dev Ends the swap.
     */
    function endSwap() onlyOwner public {
        // Require admin
        require(_msgSender() == this.owner(), 'Not called from issuer');

        // Destroy contract
        selfdestruct(payable(this.owner()));
    }
}