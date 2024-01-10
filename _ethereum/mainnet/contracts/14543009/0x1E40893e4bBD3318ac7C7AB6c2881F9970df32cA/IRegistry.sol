// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./IConfig.sol";
import "./IInvestable.sol";

interface IRegistry {
    enum IntegrationType {
        Bridge,
        Farm
    }

    struct Integration {
        bytes11 name;
        IntegrationType integrationType;
        address integration;
    }

    struct AccountPosition {
        IRegistry.Integration integration;
        IInvestable.Position position;
    }

    function config() external view returns (IConfig);

    function integrationExist(address input) external view returns (bool);

    function getIntegrations() external view returns (Integration[] memory);

    function registerIntegrations(Integration[] memory input) external;

    function unregisterIntegrations(Integration[] memory dest) external;

    function portfolio(address user)
        external
        view
        returns (AccountPosition[] memory result);
}
