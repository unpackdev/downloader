// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.18;

import "./VArray.sol";
import "./IIndexToken.sol";
import "./Common.sol";
import "./IVault.sol";
import "./FixedPoint.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IIssuance.sol";

contract Issuance is IIssuance {
    using VerifiableAddressArray for VerifiableAddressArray.VerifiableArray;
    using SafeERC20 for IERC20;

    IVault public immutable vault;

    uint256 public reentrancyLock = 1;

    modifier invariantCheck() {
        _;
        vault.invariantCheck();
    }

    modifier reentrancyGuard() {
        if (reentrancyLock > 1) revert IssuanceReentrant();
        reentrancyLock = 2;
        _;
        reentrancyLock = 1;
    }

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    /// @notice Issue index tokens
    /// @param amount The amount of index tokens to issue
    /// @dev requires approval of underlying tokens
    /// @dev reentrancy guard in case callback in tokens
    function issue(uint256 amount) external invariantCheck reentrancyGuard {
        TokenInfo[] memory tokens = vault.virtualUnits();

        if (tokens.length == 0) revert IssuanceNoTokens();

        for (uint256 i; i < tokens.length; ) {
            uint256 underlyingAmount = fmul(tokens[i].units + 1, amount) + 1;

            IERC20(tokens[i].token).safeTransferFrom(
                msg.sender,
                address(vault),
                underlyingAmount
            );

            unchecked {
                ++i;
            }
        }

        vault.invokeMint(msg.sender, amount);
    }

    /// @notice Redeem index tokens
    /// @param amount The amount of index tokens to redeem
    /// @dev reentrancy guard in case callback in tokens
    function redeem(uint256 amount) external invariantCheck reentrancyGuard {
        TokenInfo[] memory tokens = vault.virtualUnits();

        if (tokens.length == 0) revert IssuanceNoTokens();

        IVault.InvokeERC20Args[] memory args = new IVault.InvokeERC20Args[](
            tokens.length
        );

        for (uint256 i; i < tokens.length; ) {
            uint256 underlyingAmount = fmul(tokens[i].units, amount);

            args[i] = IVault.InvokeERC20Args({
                token: tokens[i].token,
                to: msg.sender,
                amount: underlyingAmount
            });

            unchecked {
                ++i;
            }
        }

        vault.invokeBurn(msg.sender, amount);

        vault.invokeERC20s(args);
    }
}
