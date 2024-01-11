//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./Counters.sol";

contract TokenListManager is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _erc20Id;
    Counters.Counter private _erc1155Id;

    /**
     * @dev ERC20 Tokens registry.
     */
    mapping(address => uint256) public allowedErc20tokens;

    /**
     * @dev ERC1155 Tokens registry.
     */
    mapping(address => uint256) public allowedErc1155tokens;

    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    /**
     * @dev Grants the contract deployer the default admin role.
     *
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Grants TOKEN_MANAGER_ROLE to `_manager`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRegistryManager(address _manager) external {
        grantRole(TOKEN_MANAGER_ROLE, _manager);
    }

    /**
     * @dev Registers a new ERC20 to be allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function registerERC20Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");

        emit RegisterERC20Token(_token);
        _erc20Id.increment();
        allowedErc20tokens[_token] = _erc20Id.current();
    }

    /**
     * @dev Registers a new ERC1155 to be allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function registerERC1155Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");
        emit RegisterERC1155Token(_token);
        _erc1155Id.increment();
        allowedErc1155tokens[_token] = _erc1155Id.current();
    }

    /**
     * @dev unRegisterERC20Token a new ERC20 allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function unRegisterERC20Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");
        emit unRegisterERC20(_token);
        delete allowedErc20tokens[_token];
    }

    /**
     * @dev unRegisterERC1155Token a new ERC1155 allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function unRegisterERC1155Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");
        emit unRegisterERC1155(_token);
        delete allowedErc1155tokens[_token];
    }

    /**
     *   @dev check if sender has admin role
     */
    modifier isAdmin() {
        require(hasRole(TOKEN_MANAGER_ROLE, _msgSender()), "must have dOTC Admin role");
        _;
    }

    /**
     * @dev Emitted when `erc20Asset` is registered.
     */
    event RegisterERC20Token(address indexed token);

    /**
     * @dev Emitted when `erc1155Asset` is registered.
     */
    event RegisterERC1155Token(address indexed token);

    /**
     * @dev Emitted when `erc1155Asset` is unRegistered.
     */
    event unRegisterERC1155(address indexed token);

    /**
     * @dev Emitted when `erc20Asset` is unRegistered.
     */
    event unRegisterERC20(address indexed token);
}
