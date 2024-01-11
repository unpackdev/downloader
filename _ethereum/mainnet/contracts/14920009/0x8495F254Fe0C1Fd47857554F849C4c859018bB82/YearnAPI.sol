// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "IERC20.sol";

interface VaultAPI is IERC20 {
    function decimals() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);
}

interface RegistryAPI {
    function governance() external view returns (address);

    function latestVault(address token) external view returns (VaultAPI);

    function numVaults(address token) external view returns (uint256);

    function vaults(address token, uint256 deploymentId)
        external
        view
        returns (VaultAPI);
}
