// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorERC20FactoryEvents {
    event ERC20ProxyDeployed(
        address proxy,
        string name,
        string symbol,
        address operator
    );
}

interface IMirrorERC20Factory {
    /// @notice Deploy a new proxy
    function create(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address erc20Proxy);
}
