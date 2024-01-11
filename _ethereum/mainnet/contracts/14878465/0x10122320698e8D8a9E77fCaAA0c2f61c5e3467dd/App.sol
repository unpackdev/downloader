// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./AppType.sol";

library App {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event AppInitialized(uint256 chainId, string appName);
    event TierSwapAmountSet(
        uint256 tierId,
        address swapToken,
        uint256 swapAmount
    );
    event ConfigChanged(
        AppType.AddressConfig addressConfig,
        AppType.UintConfig uintConfig,
        AppType.BoolConfig boolConfig,
        AppType.StringConfig stringConfig,
        address addressValue,
        uint256 uintValue,
        bool boolValue,
        string stringValue
    );
    event WithdrawDAO(
        uint256 chainId,
        address token,
        uint256 amount,
        address account
    );

    function initialize(
        AppType.State storage state,
        address dao,
        address feeWallet,
        uint256 chainId
    ) public {
        state.config.addresses[AppType.AddressConfig.DAO] = dao;
        state.config.addresses[AppType.AddressConfig.FEE_WALLET] = feeWallet;
        state.config.uints[AppType.UintConfig.CHAIN_ID] = chainId;
        state.config.strings[AppType.StringConfig.APP_NAME] = "CreatiVerse";

        emit AppInitialized(
            state.config.uints[AppType.UintConfig.CHAIN_ID],
            state.config.strings[AppType.StringConfig.APP_NAME]
        );
    }

    function setTierSwapAmount(
        AppType.State storage state,
        uint256 tierId,
        address[] calldata swapTokens,
        uint256[] calldata swapAmounts
    ) external {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        for (uint256 i = 0; i < swapTokens.length; i++) {
            state.tierSwapAmounts[tierId][swapTokens[i]] = swapAmounts[i];
            emit TierSwapAmountSet(tierId, swapTokens[i], swapAmounts[i]);
        }
    }

    function changeConfig(
        AppType.State storage state,
        AppType.IConfigKey calldata key,
        AppType.IConfigValue calldata value
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        state.config.addresses[key.addressK] = value.addressV;
        state.config.uints[key.uintK] = value.uintV;
        state.config.bools[key.boolK] = value.boolV;
        state.config.strings[key.stringK] = value.stringV;
        emit ConfigChanged(
            key.addressK,
            key.uintK,
            key.boolK,
            key.stringK,
            value.addressV,
            value.uintV,
            value.boolV,
            value.stringV
        );
    }

    function getConfig(
        AppType.State storage state,
        AppType.AddressConfig addressConfig,
        AppType.UintConfig uintConfig,
        AppType.BoolConfig boolConfig,
        AppType.StringConfig stringConfig
    )
        public
        view
        returns (
            address addressValue,
            uint256 uintValue,
            bool boolValue,
            string memory stringValue
        )
    {
        return (
            state.config.addresses[addressConfig],
            state.config.uints[uintConfig],
            state.config.bools[boolConfig],
            state.config.strings[stringConfig]
        );
    }

    function safeWithdraw(
        AppType.State storage state,
        address token,
        uint256 amount
    ) external {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        if (token == address(0)) {
            payable(state.config.addresses[AppType.AddressConfig.FEE_WALLET])
                .transfer(amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(
                state.config.addresses[AppType.AddressConfig.FEE_WALLET],
                amount
            );
        }

        emit WithdrawDAO(
            state.config.uints[AppType.UintConfig.CHAIN_ID],
            token,
            amount,
            state.config.addresses[AppType.AddressConfig.FEE_WALLET]
        );
    }
}
