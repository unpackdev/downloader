//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface ITokensRegistry {
    event TokenAdded(address indexed adder, address indexed token);

    event TokenRemoved(address indexed remover, address indexed token);

    function addToken(address token) external;

    function removeToken(address token) external;

    function hasToken(address token) external view returns (bool);
}
