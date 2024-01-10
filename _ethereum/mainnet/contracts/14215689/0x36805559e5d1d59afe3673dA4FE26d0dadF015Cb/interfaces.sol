// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./IERC20.sol";

struct TokenInfo {
    address sourceToken;
    address targetToken;
    uint256 amount;
}

struct Position {
    TokenInfo[] supply;
    TokenInfo[] withdraw;
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface ListInterface {
    function accountAddr(uint64) external view returns (address);

    function accountID(address) external view returns (uint64);
}

interface IndexInterface {
    function list() external view returns (address);

    function build(
        address _owner,
        uint256 accountVersion,
        address _origin
    ) external returns (address _account);
}

interface TokenInterface is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}
