// contracts/DBridgeExchange.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract DBridgeExchange is AccessControl {
    using SafeERC20 for IERC20;
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    mapping(IERC20 => mapping(IERC20 => uint256)) private _exchanges;

    event Exchange(address indexed fromToken, address indexed toToken, address indexed src, uint256 amount, uint256 stableAmount);
    event ExchangeRate(address indexed from, address indexed to, uint256 amount);
    event WithdrawToken(address indexed token, address indexed dest, uint256 amount);
    event Received(address indexed src, uint256 amount);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Function to exchange token
     * @param amount Amount of tokens
     */
    function exchange(
    	IERC20 fromToken,
    	IERC20 toToken,
        uint256 amount
    ) external {
        require (amount > 0, "DExchange: Not zero amount");
        fromToken.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 exchangeAmount = _getExchangeRate(fromToken, toToken, amount);
        require(exchangeAmount > 0, "DExchange: Not zero exchange amount");
        if (address(toToken) != address(this)) {
            toToken.safeTransfer(_msgSender(), exchangeAmount);
            emit Exchange(address(fromToken), address(toToken), _msgSender(), amount, exchangeAmount);
        } else {
            require(
                payable(_msgSender()).send(exchangeAmount),
                "DExchange: !send"
            );
            emit Exchange(address(fromToken), address(this), _msgSender(), amount, exchangeAmount);
        }
    }

    /**
     * @notice Function to withdraw token
     * Owner is assumed to be governance
     * @param token Address of token to be rescued
     * @param destination User address
     * @param amount Amount of tokens
     */
    function withdrawToken(
        IERC20 token,
        address destination,
        uint256 amount
    ) external onlyRole(GOVERNOR_ROLE) {
        require(address(0) != destination, "DExchange: Not zero amount");
        require(address(token) != destination, "DExchange: token and destination are same");
        require(amount > 0, "!zero");

        if (address(token) != address(this)) {
            token.safeTransfer(destination, amount);
            emit WithdrawToken(address(token), destination, amount);
        } else {
            require(
                payable(destination).send(amount),
                "!treasury1Transfer"
            );
            emit WithdrawToken(address(this), destination, amount);
        }

    }

    function setExchangeRate(
    	IERC20 fromToken,
    	IERC20 toToken,
        uint256 exchangeRate
    ) external onlyRole(GOVERNOR_ROLE) {
        require(exchangeRate > 0, "!zero");
        _exchanges[fromToken][toToken] = exchangeRate;
        emit ExchangeRate(address(fromToken), address(toToken), exchangeRate);
    }

    /**
     * @dev Returns the exchangeInfo.
     */
    function getExchangeRate(IERC20 fromToken, IERC20 toToken) public view virtual returns (
    	uint256 exchangeRate
    ) {
        return _exchanges[fromToken][toToken];
    }

    /**
     * @dev Returns the exchange Amount.
     */
    function getExchangeAmount(IERC20 fromToken,IERC20 toToken, uint256 amount) public view virtual returns (
        uint256 exchangeAmount
    ) {
        return _getExchangeRate(fromToken, toToken, amount);
    }

    function _getExchangeRate(
    	IERC20 fromToken,
    	IERC20 toToken,
    	uint256 amount
    ) internal view returns(uint256) {
        return amount / _exchanges[fromToken][toToken];
    }

    receive() external payable {}
}