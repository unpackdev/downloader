// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Events {
    /// @notice Emitted when stETH is deposited from vault to protocols.
    event LogVaultToProtocolDeposit(
        uint8 indexed protocol,
        uint256 depositAmount
    );

    /// @notice Emitted whenever stETH is deposited from protocol
    /// to vault to craete withdrawal vaialability.
    event LogFillVaultAvailability(
        uint8 indexed protocol,
        uint256 withdrawAmount
    );

    /// @notice Emitted whenever ideal Weth DSA balance is swapped to stETH.
    event LogWethSweep(uint256 wethAmount);

    /// @notice Emitted whenever ideal Eth DSA balance is swapped to stETH.
    event LogEthSweep(uint256 ethAmount);

    /// @notice Emitted whenever revenue is collected.
    event LogCollectRevenue(uint256 amount, address indexed to);

    /// @notice Emitted whenever exchange price is updated.
    event LogUpdateExchangePrice(
        uint256 indexed exchangePriceBefore,
        uint256 indexed exchangePriceAfter
    );
}
