// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";

contract ExchangeTokens is Context, Ownable {
    using SafeMath for uint256;

    // The QTUM token
    IERC20 public QTUM;
    // The WQTUM token
    IERC20 public WQTUM;

    // Contract initially locked
    bool locked = true;

    // Events
    event ExchangeEvent(address user, uint256 amount);
    event WithdrawEvent(address to, address token, uint256 amount);
    event Locked(uint256 timestamp);
    event Unlocked(uint256 timestamp);

    constructor(IERC20 _QTUM, IERC20 _WQTUM) public {
        QTUM = _QTUM;
        WQTUM = _WQTUM;
    }

    /**
     * @dev Token exchange
     */
    function exchange() public {
        require(!locked, 'exchange: exchange function is locked');
        require(msg.sender != address(0x0), 'exchange: sender must be a valid address');

        uint256 amount = QTUM.balanceOf(msg.sender);

        require(amount > 20000000000, 'exchange: amount must be greater than 20000000000');
        require(
            QTUM.allowance(msg.sender, address(this)) >= amount,
            'exchange: contract not allowed to transfer enough QTUM for this exchange'
        );
        require(
            WQTUM.balanceOf(address(this)) >= amount,
            'exchange: not enough WQTUM token in the contract for this exchange'
        );

        QTUM.transferFrom(_msgSender(), address(this), amount);
        WQTUM.transfer(_msgSender(), amount);

        emit ExchangeEvent(_msgSender(), amount);
    }

    /**
     * @dev Withdrawal of not exchanged tokens
     * @param _token exchange token
     */
    function withdrawTokens(IERC20 _token) public onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(_msgSender(), balance);

        emit WithdrawEvent(_msgSender(), address(_token), balance);
    }

    /**
     * @dev Lock the exchange function
     */
    function lock() public onlyOwner {
        locked = true;

        emit Locked(block.timestamp);
    }

    /**
     * @dev Unlock the exchange function
     */
    function unlock() public onlyOwner {
        locked = false;

        emit Unlocked(block.timestamp);
    }
}
