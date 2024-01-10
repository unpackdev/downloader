// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./XCC.sol";
import "./IRegistry.sol";
import "./IConfig.sol";

contract Registry is
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    IRegistry
{
    using XCC for Integration[];
    IConfig public override config;
    mapping(uint256 => Integration[]) public integration;

    function _initialize(IConfig c) external initializer {
        // bound
        config = c;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getIntegrations(uint256 chainID)
        external
        view
        override
        returns (Integration[] memory)
    {
        return integration[chainID];
    }

    function registerIntegrations(Integration[] memory input, uint256 chainId)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // bound
        require(input.length < type(uint8).max, "RG2");
        for (uint8 i; i < input.length; i++) {
            (bool exist, , ) = integration[chainId].findIntegration(
                input[i].integration
            );
            require(!exist, "RG3");
        }
        for (uint8 j; j < input.length; j++) {
            integration[chainId].push(input[j]);
        }
    }

    function unregisterIntegrations(Integration[] memory input, uint256 chainId)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(input.length < type(uint8).max, "RG4");
        for (uint8 i; i < input.length; i++) {
            (bool exist, uint8 index, ) = integration[chainId].findIntegration(
                input[i].integration
            );
            if (!exist) continue;
            integration[chainId][index] = integration[chainId][
                integration[chainId].length - 1
            ];
            integration[chainId].pop();
        }
    }

    function portfolio(address user, uint256 chainId)
        external
        view
        returns (AccountPosition[] memory result)
    {
        IRegistry.Integration[] memory itrxn = config
            .registry()
            .getIntegrations(chainId);
        AccountPosition[] memory temp = new AccountPosition[](itrxn.length);
        uint8 count;
        for (uint8 i; i < itrxn.length; i++) {
            if (itrxn[i].integrationType != IRegistry.IntegrationType.Farm) {
                continue;
            }
            count++;
            temp[i].integration = itrxn[i];
            temp[i].position = IFarm(itrxn[i].integration).position(user);
        }
        result = new AccountPosition[](count);
        for (uint8 j; j < count; j++) {
            result[j] = temp[j];
        }
    }
}
