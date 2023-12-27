/*
 * Capital DEX
 *
 * Copyright ©️ 2023 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2023 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Blacklist.sol";
import "./Pause.sol";
import "./TokenManager.sol";
import "./Context.sol";
import "./AccessControl.sol";

/// @title Interface for bridge contract
/// @dev Inherits from interfaces of contract components
interface IBridge is IBlacklist, ITokenManager, IPause {
    /// @dev Data describing the unlock, used in batch_unlock call for ease of parameters passing
    struct UnlockData {
        uint256 id;
        address to;
        IERC20 token;
        uint256 amount;
    }

    /// @notice Tokens were locked in bridge contract
    /// @param id Lock id
    /// @param to Curio parachain address tokens will be bridged to
    /// @param token ERC20 token contract address
    /// @param amount amount of tokens
    event Lock(uint256 id, bytes32 to, IERC20 token, uint256 amount);

    /// @notice Tokens were unlocked from bridge contract
    /// @param id Unlock id
    /// @param to Address tokens will be unlocked to
    /// @param token ERC20 token contract address
    /// @param amount Amount of tokens
    event Unlock(uint256 id, address to, IERC20 token, uint256 amount);

    /// @notice Unlock request with given id have been already executed
    /// @param id Id of unlock request
    error RequestAlreadyProcessed(uint256 id);

    /// @notice Request tokens bridging
    /// @dev Tokens must be previously approved to the contract
    /// @param to Curio parachain address that tokens will be bridged to
    /// @param token ERC20 contract address
    /// @param amount amount of tokens
    function lock(bytes32 to, IERC20 token, uint256 amount) external;

    /// @notice Unlock tokens bridged from Curio parachain
    /// @dev id must be taken from Curio parachain corresponding pallet's event
    /// @param id Unlock request id
    /// @param to Address tokens will be unlocked to
    /// @param token ERC20 contract address
    /// @param amount amount of tokens
    function unlock(uint256 id, address to, IERC20 token, uint256 amount) external;

    /// @notice Unlock tokens bridged from Curio parachain
    /// @dev Do many unlocks at a time
    /// @param data Array of unlocks data
    function batchUnlock(UnlockData[] memory data) external;
}

/// @title Curio parachain <-> Ethereum bridge smart contract
/// @dev Composed of contracts providing additional functionality
contract Bridge is IBridge, Context, Blacklist, TokenManager, Pause {
    /// @notice Identifier of manager role able to manage the contract
    /// @dev Able to pause/unpause contract or specific tokens, blacklist users, manage supported tokens list and do unlocks
    bytes32 public constant managerRole = keccak256("MANAGER_ROLE");

    /// @notice Lock id
    /// @dev Incremented in lock call
    uint256 public outRequestId;

    /// @notice Storage for ids of already processed unlock requests
    mapping(uint256 => bool) public inRequestProcessed;

    /// @dev Deployer is granted admin and manager roles
    constructor() 
        Blacklist(Context._msgSender(), managerRole)
        TokenManager(Context._msgSender(), managerRole)
        Pause(Context._msgSender(), managerRole)
    {
        outRequestId = 0;
        AccessControl._grantRole(AccessControl.DEFAULT_ADMIN_ROLE, Context._msgSender());
        AccessControl._grantRole(managerRole, Context._msgSender());
    }

    /// @inheritdoc IBridge
    function lock(bytes32 to, IERC20 token, uint256 amount) external 
        Pause.whenNotPaused()
        TokenManager.OnlyActiveToken(token)
        Blacklist.NotBlacklistedEth(Context._msgSender())
        Blacklist.NotBlacklistedSub(to)
    {
        token.transferFrom(Context._msgSender(), address(this), amount);
        
        emit Lock(outRequestId++, to, token, amount);
    }

    /// @inheritdoc IBridge
    function unlock(uint256 id, address to, IERC20 token, uint256 amount) public 
        AccessControl.onlyRole(managerRole)
        Pause.whenNotPaused()
    {
        _unlock(id, to, token, amount);
    }

    /// @inheritdoc IBridge
    function batchUnlock(UnlockData[] memory data) external 
        AccessControl.onlyRole(managerRole) 
        Pause.whenNotPaused()
    {
        for(uint256 i = 0; i < data.length; i++) {
            _unlock(data[i].id, data[i].to, data[i].token, data[i].amount);
        }
    }

    function _unlock(uint256 id, address to, IERC20 token, uint256 amount) private 
        TokenManager.OnlyActiveToken(token)
        Blacklist.NotBlacklistedEth(to)
    {
        if(inRequestProcessed[id]) {
            revert RequestAlreadyProcessed(id);
        }

        inRequestProcessed[id] = true;

        token.transfer(to, amount);

        emit Unlock(id, to, token, amount);
    }
}