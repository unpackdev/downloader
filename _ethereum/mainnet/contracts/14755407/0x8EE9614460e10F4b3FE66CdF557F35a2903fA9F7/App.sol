// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

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
    event WithdrawAdmin(
        uint256 chainId,
        address token,
        uint256 amount,
        address account
    );

    function initialize(AppType.State storage state) external {
        state.config.addresses[AppType.AddressConfig.ADMIN] = msg.sender;
        state.config.addresses[
            AppType.AddressConfig.FEE_WALLET
        ] = 0xb07De92Cb6332B69D478026Ea563a2DC1661c73F;
        state.config.uints[AppType.UintConfig.CHAIN_ID] = 0x1;
        state.config.strings[
            AppType.StringConfig.APP_NAME
        ] = "Gallery Chosun Collection";

        state.tierSwapAmounts[1][address(0)] = 5e16;

        emit AppInitialized(
            state.config.uints[AppType.UintConfig.CHAIN_ID],
            state.config.strings[AppType.StringConfig.APP_NAME]
        );
    }

    function setTierSwapAmount(
        AppType.State storage state,
        uint256 tierId,
        address swapToken,
        uint256 swapAmount
    ) external {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.ADMIN],
            "E001"
        );

        state.tierSwapAmounts[tierId][swapToken] = swapAmount;
        emit TierSwapAmountSet(tierId, swapToken, swapAmount);
    }

    function changeConfig(
        AppType.State storage state,
        AppType.IConfigKey calldata key,
        AppType.IConfigValue calldata value
    ) external {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.ADMIN],
            "E001"
        );

        require(
            key.addressK != AppType.AddressConfig.ADMIN ||
                value.addressV == address(0),
            "E008"
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
        external
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
            msg.sender == state.config.addresses[AppType.AddressConfig.ADMIN] ||
                msg.sender ==
                state.config.addresses[AppType.AddressConfig.FEE_WALLET],
            "E009"
        );

        require(
            state.config.addresses[AppType.AddressConfig.FEE_WALLET] !=
                address(0),
            "E010"
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

        emit WithdrawAdmin(
            state.config.uints[AppType.UintConfig.CHAIN_ID],
            token,
            amount,
            state.config.addresses[AppType.AddressConfig.FEE_WALLET]
        );
    }
}
