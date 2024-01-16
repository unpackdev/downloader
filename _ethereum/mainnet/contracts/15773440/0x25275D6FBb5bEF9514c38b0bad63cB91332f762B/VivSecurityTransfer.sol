// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Token.sol";

/**
 * The secure transfer contract is used to prevent the wrong destination address during transfer, and the funds on Ethereum cannot be recovered once they are transferred out.
 */
contract VivSecurityTransferBase is Token {
    mapping(address => mapping(address => uint256)) _balances;

    mapping(address => mapping(address => mapping(address => uint256))) _allowances;

    function balanceOf(address _token, address _owner) public view returns (uint256) {
        return _balances[_token][_owner];
    }

    function allowanceOf(
        address _token,
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return _allowances[_token][_owner][_spender];
    }

    /// Only balance of value more than values can call this function.
    error CheckAmount();

    /**
     * Check balance and allowance
     * @param from sender
     * @param to spender
     * @param value amount
     */
    modifier checkAmount(
        address _token,
        address from,
        address to,
        uint256 value
    ) {
        require(from != address(0), "VIV0030");
        require(to != address(0), "VIV1301");
        require(value > 0, "VIV0001");
        require(value <= _balances[_token][from], "VIV0003");
        require(value <= _allowances[_token][from][to], "VIV0004");
        _;
    }
}

/**
 * VIV Eth Security Transfer Contract
 */
contract VivSecurityTransfer is VivSecurityTransferBase {
    using SafeMath for uint256;

    /**
     * Transfer in
     * @param spender The address authorized to spend
     * @param value The amount to send
     */
    function transferIn(
        address spender,
        uint256 value,
        address _token
    ) external payable {
        require(spender != address(0), "VIV0014");
        require(value > 0, "VIV0001");

        _checkTransferIn(_token, value);
        _balances[_token][msg.sender] = _balances[_token][msg.sender].add(value);
        _allowances[_token][msg.sender][spender] = _allowances[_token][msg.sender][spender].add(value);
        _transferFrom(_token, msg.sender, address(this), value);
    }

    /**
     * Transfer out
     * @param sender  The address of the sender
     * @param value The amount to send
     */
    function transferOut(
        address sender,
        uint256 value,
        address _token
    ) external payable checkAmount(_token, sender, msg.sender, value) {
        _balances[_token][sender] = _balances[_token][sender].sub(value);
        _allowances[_token][sender][msg.sender] = _allowances[_token][sender][msg.sender].sub(value);
        _transfer(_token, msg.sender, value);
    }

    /**
     * Cancel transfer in
     * @param spender  The address of the spender
     * @param value The amount to spender
     */
    function cancelTransferIn(
        address spender,
        uint256 value,
        address _token
    ) external payable checkAmount(_token, msg.sender, spender, value) {
        _balances[_token][msg.sender] = _balances[_token][msg.sender].sub(value);
        _allowances[_token][msg.sender][spender] = _allowances[_token][msg.sender][spender].sub(value);
        _transfer(_token, msg.sender, value);
    }
}
