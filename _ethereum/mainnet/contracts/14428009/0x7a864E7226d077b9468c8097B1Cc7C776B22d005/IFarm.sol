// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./IERC20MetadataUpgradeable.sol";
import "./IConfig.sol";
import "./IInvestable.sol";

interface IFarm is IInvestable {
    event TokenDeployed(
        address indexed onBehalfOf,
        IERC20MetadataUpgradeable indexed underlying,
        uint256 amount
    );
    event NativeDeployed(address indexed onBehalfOf, uint256 amount);
    event TokenWithdrawn(
        address indexed onBehalfOf,
        IERC20MetadataUpgradeable indexed underlying,
        uint256 amount
    );
    event NativeWithdrawn(address indexed onBehalfOf, uint256 amount);
    struct PositionToken {
        UnderlyingAsset underlying;
        address positionToken;
    }

    function getUnderlyingSupported()
        external
        view
        returns (UnderlyingAsset[] memory);

    function positionToken(IERC20MetadataUpgradeable underlying)
        external
        view
        returns (address);

    function underlyingSupported(uint256 index)
        external
        view
        returns (
            bytes11 name,
            uint8 decimals,
            IERC20MetadataUpgradeable underlying
        );

    function config() external view returns (IConfig);

    function deployNative() external payable;

    function deployToken(
        uint256 amountIn18,
        IERC20MetadataUpgradeable underlying
    ) external;

    function deployTokenAll(IERC20MetadataUpgradeable underlying) external;

    function withdrawNative() external payable;

    function withdrawTokenAll(IERC20MetadataUpgradeable underlying) external;

    function withdrawToken(
        IERC20MetadataUpgradeable underlying,
        uint256 underlyingAmount
    ) external;
}
