// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";
import "./IConfig.sol";
import "./IInvestable.sol";

interface IFarm is IInvestable {
    event BalanceChanged(address indexed integrationAddr, IERC20Metadata indexed underlying, int256 delta);
    event TokenDeployed(address indexed integrationAddr, IERC20Metadata indexed underlying, uint256 amount);
    event TokenWithdrawn(address indexed integrationAddr, IERC20Metadata indexed underlying, uint256 amount);
    struct PositionToken {
        IERC20Metadata underlying;
        address positionToken;
    }

    function positionToken() external view returns (address);

    function numberOfUnderlying() external view returns (uint256);

    function getUnderlyings()
        external
        view
        returns (IERC20Metadata[] memory result);

    function mainToken() external view returns (IERC20Metadata);

    function underlying() external view returns (IERC20Metadata);

    function config() external view returns (IConfig);

    function deployToken(IERC20Metadata u, uint256 amountIn18) external;

    function deployTokenAll(IERC20Metadata u) external;

    function withdrawTokenAll(IERC20Metadata u) external;

    function withdrawToken(IERC20Metadata u, uint256 underlyingAmount) external;
}
