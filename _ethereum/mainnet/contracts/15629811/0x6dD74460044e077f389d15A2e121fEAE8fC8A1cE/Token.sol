// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity 0.8.4;
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

/**
 * Merge transfer functionality of Ethereum and tokens
 */
contract Token is ReentrancyGuard{

    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * Notify When transfer happened
     * @param sender who sender
     * @param receiver who receiver
     * @param value transfer value
     */
    event Transfer(address indexed sender, address indexed receiver, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * Get balance of this contract
     */
    function _balanceOf(address token) internal view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /**
     * allowance (Used for ERC20)
     * @param owner owner
     * @param spender spender
     */
    function _allowance(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256) {
        if (token != address(0)) {
            return IERC20(token).allowance(owner, spender);
        }
        return 0;
    }

    /**
     * Transfer
     * @param to the destination address
     * @param value value of transaction.
     */
    function _transfer(
        address token,
        address to,
        uint256 value
    ) internal nonReentrant() {
        if (token == address(0)) {
            payable(to).sendValue(value);
            emit Transfer(address(this), to, value);
        } else {
            IERC20(token).safeTransfer(to, value);
        }
    }

    /**
     * Transfer form (Used for ERC20)
     * @param from the source address
     * @param to the destination address
     * @param value value of transaction.
     */
    function _transferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (token != address(0)) {
            IERC20(token).safeTransferFrom(from, to, value);
        }
    }

    /**
     * check transfer in
     * @param value value
     */
    function _checkTransferIn(address token, uint256 value) internal {
        __checkTransferIn(token, msg.sender, value);
    }

    function __checkTransferIn(
        address token,
        address owner,
        uint256 value
    ) internal {
        if (token == address(0)) {
            require(msg.value == value, "VIV0002");
        } else {
            require(IERC20(token).balanceOf(owner) >= value, "VIV0003");
            require(_allowance(token, owner, address(this)) >= value, "VIV0004");
        }
    }
}
