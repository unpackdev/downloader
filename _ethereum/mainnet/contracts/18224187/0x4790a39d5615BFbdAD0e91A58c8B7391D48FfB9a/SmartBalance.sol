// SPDX-License-Identifier: Apache-2.0

/*
     Copyright 2023 Galxe.

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
 */

pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";
import "Pausable.sol";

/**
 * @title SmartBalance
 * @author Galxe
 *
 * SmartBalance contract allows Galxe to charge and keep track of Galxe user balances.
 */
contract SmartBalance is Pausable, Ownable {
    using SafeERC20 for IERC20;

    /* ============ Events ============ */

    event UpdateTreasurer(address indexed newTreasurer);

    event Deposit(
        bytes32 indexed _galxeId,
        address indexed token,
        uint256 _amount,
        address indexed depositor
    );

    event Withdraw(
        bytes32 indexed _galxeId,
        address token,
        uint256 indexed _amount,
        address indexed recipient
    );

    event AllowToken(address indexed token);

    event DisallowToken(address indexed token);

    /* ============ Modifiers ============ */

    modifier onlyTreasurer() {
        _onlyTreasurer();
        _;
    }

    modifier onlyAllowedToken(address token) {
        _onlyAllowedToken(token);
        _;
    }

    function _onlyTreasurer() internal view {
        require(msg.sender == treasurer, "Must be treasurer");
    }

    function _onlyAllowedToken(address token) internal view {
        require(tokenAllowlist[token] == true, "Must be allowed token");
    }

    /* ============ State Variables ============ */

    // Contract factory
    address public factory;

    // Galxe treasurer
    address public treasurer;

    // Galxe ID => token => current balance
    mapping(bytes32 => mapping(address => uint256)) public userTokenBalance;

    // Galxe ID => token => total deposited amount
    mapping(bytes32 => mapping(address => uint256)) public userTotalDeposits;

    // Allowed tokens
    mapping(address => bool) public tokenAllowlist;

    // Token balance
    mapping(address => uint256) public tokenBalance;

    /* ============ Constructor ============ */

    constructor() {
        factory = msg.sender;
    }

    /* ============ Initializer ============ */

    function initialize(address owner, address _treasurer) external {
        require(msg.sender == factory, "Forbidden");
        treasurer = _treasurer;
        transferOwnership(owner);
    }

    /* ============ External Functions ============ */

    function setTreasurer(address _treasurer) external onlyOwner {
        require(
            _treasurer != address(0),
            "Treasurer address must not be null address"
        );
        treasurer = _treasurer;
        emit UpdateTreasurer(_treasurer);
    }

    function allowToken(address _token) external onlyOwner {
        tokenAllowlist[_token] = true;

        emit AllowToken(_token);
    }

    function disallowToken(address _token) external onlyOwner {
        tokenAllowlist[_token] = false;

        emit DisallowToken(_token);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function isTokenAllowed(address _token) public view returns (bool) {
        return tokenAllowlist[_token];
    }

    function balanceOf(
        bytes32 _galxeId,
        address _token
    ) public view returns (uint256) {
        return userTokenBalance[_galxeId][_token];
    }

    /**
     * @notice
     *  Returns accumulated token disposit amount for galxe ID.
     */
    function totalDepositOf(
        bytes32 _galxeId,
        address _token
    ) public view returns (uint256) {
        return userTotalDeposits[_galxeId][_token];
    }

    function deposit(
        bytes32 _galxeId,
        address _token,
        uint256 _amount
    ) external payable whenNotPaused onlyAllowedToken(_token) {
        if (_token == address(0)) {
            _depositNative(_galxeId, _amount);
        } else {
            _depositERC20(_galxeId, _token, _amount);
        }
    }

    function withdrawToken(
        address _token,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        uint256 _amount = tokenBalance[_token];
        require(_amount > 0, "Cannot withdraw a non-positive amount");
        tokenBalance[_token] -= _amount;
        _doWithdraw(_token, _amount, _recipient);
        emit Withdraw(bytes32(0), _token, _amount, _recipient);
    }

    function withdrawToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) external whenNotPaused onlyTreasurer {
        require(_amount > 0, "Cannot withdraw a non-positive amount");
        require(
            tokenBalance[_token] >= _amount,
            "Token amount must be greater than withdraw amount"
        );
        tokenBalance[_token] -= _amount;
        _doWithdraw(_token, _amount, _recipient);
        emit Withdraw(bytes32(0), _token, _amount, _recipient);
    }

    function withdraw(
        bytes32 _galxeId,
        address _token,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        uint256 _amount = userTokenBalance[_galxeId][_token];
        _withdraw(_galxeId, _token, _amount, _recipient);
    }

    function withdraw(
        bytes32 _galxeId,
        address _token,
        uint256 _amount,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        _withdraw(_galxeId, _token, _amount, _recipient);
    }

    function withdrawBatch(
        bytes32 _galxeId,
        address[] calldata _tokens,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; ++i) {
            _amounts[i] = userTokenBalance[_galxeId][_tokens[i]];
        }
        _withdrawBatch(_galxeId, _tokens, _amounts, _recipient);
    }

    function withdrawBatch(
        bytes32 _galxeId,
        address[] calldata _tokens,
        uint256[] memory _amounts,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        _withdrawBatch(_galxeId, _tokens, _amounts, _recipient);
    }


    receive() external payable {
        if (msg.sender == address(this)) {
            return;
        }
        // anonymous transfer: to treasury_manager
        (bool success, ) = treasurer.call{value: msg.value}(
            new bytes(0)
        );
        require(success, "Transfer failed");
    }

    fallback() external payable {
        if (msg.sender == address(this)) {
            return;
        }
        if (msg.value > 0) {
            // call non exist function: send to treasury_manager
            (bool success, ) = treasurer.call{value: msg.value}(new bytes(0));
            require(success, "Transfer failed");
        }
    }

    /* ============ Internal Functions ============ */

    function _depositERC20(
        bytes32 _galxeId,
        address _token,
        uint256 _amount
    ) internal {
        require(
            IERC20(_token).balanceOf(msg.sender) >= _amount,
            "Your token amount must be greater then you are trying to deposit"
        );
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= _amount,
            "Approve tokens first!"
        );
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        _deposit(_galxeId, _token, _amount, msg.sender);
    }

    function _depositNative(
        bytes32 _galxeId,
        uint256 _amount
    ) internal {
        require(
            msg.value >= _amount,
            "Your token amount must be greater then you are trying to deposit"
        );

        (bool success, ) = address(this).call{value: msg.value}(
            new bytes(0)
        );
        require(success, "Deposit native token failed");
        _deposit(_galxeId, address(0), _amount, msg.sender);
    }

    function _deposit(
        bytes32 _galxeId,
        address _token,
        uint256 _amount,
        address _depositor
    ) private {
        userTokenBalance[_galxeId][_token] += _amount;
        userTotalDeposits[_galxeId][_token] += _amount;
        tokenBalance[_token] += _amount;

        emit Deposit(_galxeId, _token, _amount, _depositor);
    }

    function _withdrawBatch(
        bytes32 _galxeId,
        address[] calldata _tokens,
        uint256[] memory _amounts,
        address _recipient
    ) internal {
        require(
            _tokens.length == _amounts.length,
            "Tokens and amounts length mismatch"
        );
        for (uint256 i = 0; i < _amounts.length; ++i) {
            _withdraw(_galxeId, _tokens[i], _amounts[i], _recipient);
        }
    }

    function _withdraw(
        bytes32 _galxeId,
        address _token,
        uint256 _amount,
        address _recipient
    ) internal {
        require(_amount > 0, "Cannot withdraw a non-positive amount");
        require(
            userTokenBalance[_galxeId][_token] >= _amount,
            "Token amount must be greater than withdraw amount"
        );
        userTokenBalance[_galxeId][_token] -= _amount;
        tokenBalance[_token] -= _amount;
        _doWithdraw(_token, _amount, _recipient);
        emit Withdraw(_galxeId, _token, _amount, _recipient);
    }

    function _doWithdraw(address _token, uint256 _amount, address _recipient) private {
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "Contract insufficient balance");
            (bool success, ) = _recipient.call{value: _amount}(
                new bytes(0)
            );
            require(success, "Withdraw native token failed");
        } else {
            IERC20(_token).safeTransfer(_recipient, _amount);
        }
    }
}
