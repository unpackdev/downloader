pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";

contract MigrateHelpers is Helpers, Events {
    using SafeERC20 for IERC20;

    function migrateTokens(address newDsa, address[] memory tokens) internal {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == ethAddr) {
                uint ethAmt = address(this).balance;
                payable(newDsa).transfer(ethAmt);
            } else {
                IERC20 tokenContract = IERC20(token);
                uint tokenAmt = tokenContract.balanceOf(address(this));
                if (tokenAmt > 0) tokenContract.safeTransfer(newDsa, tokenAmt);
            }
        }
    }

    function migrateApprovals(
        address newDsa,
        address[] calldata tokens,
        uint[] calldata allowances
    ) internal {
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 tokenContract = IERC20(tokens[i]);
            if (allowances[i] > 0) tokenContract.safeApprove(newDsa, allowances[i]);
        }
    }

    function migrateVaults(address newDsa, uint[] calldata vaults) internal {
        for (uint i = 0; i < vaults.length; i++) {
            require(mcdManager.owns(vaults[i]) == address(this), "not-owner");
            mcdManager.give(vaults[i], newDsa);
        }
    }
}

contract MigrateResolver is MigrateHelpers {
    struct MigrationData {
        address[] migrateTokens;
        address[] allowanceTokens;
        uint256[] allowances;
        uint256[] makerVaults;
        string[] targets;
        bytes[] calldatas;
    }

    /**
     * @dev Create a DSA v2 & migrate assets
     */
    function createAndMigrate(MigrationData calldata data) external payable {
        require(data.targets.length == data.calldatas.length, "len-mismatch");
        require(data.allowanceTokens.length == data.allowances.length, "len-mismatch");

        address newDsa = createV2(address(this));
        AccountInterface dsaContract = AccountInterface(newDsa);

        migrateTokens(newDsa, data.migrateTokens);
        migrateVaults(newDsa, data.makerVaults);
        
        migrateApprovals(newDsa, data.allowanceTokens, data.allowances);

        if (data.targets.length > 0) {
            dsaContract.cast{value: 0}(data.targets, data.calldatas, address(0));
        }
        require(dsaContract.isAuth(msg.sender), "msg.sender-is-not-auth.");

        emit LogCreateAndMigrate(
            address(this),
            newDsa,
            data.migrateTokens,
            data.makerVaults,
            data.targets,
            data.calldatas
        );
    }

    /**
     * @dev Cast migration spells to DSA v2
     */
    function migrate(
        address newDsa,
        MigrationData calldata data
    ) external payable {
        require(data.targets.length == data.calldatas.length, "len-mismatch");
        require(data.allowanceTokens.length == data.allowances.length, "len-mismatch");

        migrateApprovals(newDsa, data.allowanceTokens, data.allowances);

        AccountInterface dsaContract = AccountInterface(newDsa);
        require(dsaContract.isAuth(address(this)), "dsa-is-not-auth.");

        migrateTokens(newDsa, data.migrateTokens);
        migrateVaults(newDsa, data.makerVaults);

        if (data.targets.length > 0) {
            dsaContract.cast{value: 0}(data.targets, data.calldatas, address(0));
        }
        require(dsaContract.isAuth(msg.sender), "msg.sender-is-not-auth.");

        emit LogMigrate(
            address(this),
            newDsa,
            data.migrateTokens,
            data.makerVaults,
            data.targets,
            data.calldatas
        );
    }
}

contract ConnectMigrate is MigrateResolver {
    /**
     * @dev Connector Details.
    */
    function connectorID() public pure returns(uint model, uint id) {
        (model, id) = (1, 102);
    }

    string public constant name = "v1-to-v2-migrate-v1.2";
}
