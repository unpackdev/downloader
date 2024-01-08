// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorERC20ProxyStorageEvents {
    /// @notice Emitted when a new proxy is initialized
    event NewProxy(address indexed proxy, address indexed operator);
}

interface IMirrorERC20ProxyStorage {
    function operator() external view returns (address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Register new proxy and initialize metadata
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(
        address sender,
        address spender,
        uint256 value
    ) external returns (bool);

    function transfer(
        address sender,
        address to,
        uint256 value
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function mint(
        address sender,
        address to,
        uint256 amount
    ) external;

    function setOperator(address sender, address newOperator) external;
}
