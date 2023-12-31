// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import "./ActionUtil.sol";
import "./FixedPointMathLib.sol";
import "./SafeERC20.sol";

// interfaces
import "./IERC20.sol";
import "./IHashnoteVault.sol";
import "./IMarginEngine.sol";

import "./constants.sol";
import "./errors.sol";
import "./types.sol";

library StructureLib {
    using SafeERC20 for IERC20;

    /**
     * @dev common action types on margin engines defined locally, original enums locations:
     *       - https://github.com/grappafinance/core-cash/blob/master/src/config/enums.sol
     *       - https://github.com/grappafinance/core-physical/blob/master/src/config/enums.sol
     *
     *      These constants are defined to add compatibility between ActionTypes of physical and cash settled margin engines
     *      uint8 values correspond to the order (and value) of the enum entries
     */

    uint8 constant ACTION_COLLATERAL_ADD = 0;
    uint8 constant ACTION_COLLATERAL_REMOVE = 1;
    uint8 constant ACTION_SETTLE_PHYSICAL = 7;
    uint8 constant ACTION_SETTLE_CASH = 8;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event WithdrewCollateral(uint256[] amounts, address indexed manager);

    /**
     * @notice verifies that initial collaterals are present (non-zero)
     * @param collaterals is the array of collaterals passed from initParams in initializer
     */
    function verifyInitialCollaterals(Collateral[] calldata collaterals) external pure {
        unchecked {
            for (uint256 i; i < collaterals.length; ++i) {
                if (collaterals[i].id == 0) revert OV_BadCollateral();
            }
        }
    }

    /**
     * @notice Settles the vaults position(s) in margin account.
     * @param marginEngine is the address of the margin engine contract
     * @param isCashSettled is the flag that should be true if the options are cash settled
     */
    function settleOptions(IMarginEngine marginEngine, bool isCashSettled) external {
        ActionArgs[] memory actions = new ActionArgs[](1);

        actions[0] = ActionArgs({action: isCashSettled ? ACTION_SETTLE_CASH : ACTION_SETTLE_PHYSICAL, data: ""});

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Deposits collateral into the margin account.
     * @param marginEngine is the address of the margin engine contract
     */
    function depositCollateral(IMarginEngine marginEngine, Collateral[] calldata collaterals) external {
        ActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 balance = collateral.balanceOf(address(this));

            if (balance > 0) {
                collateral.safeApprove(address(marginEngine), balance);

                actions = ActionUtil.append(
                    actions,
                    ActionArgs({
                        action: ACTION_COLLATERAL_ADD,
                        data: abi.encode(address(this), uint80(balance), collaterals[i].id)
                    })
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws all vault collateral(s) from the margin account.
     * @param marginEngine is the interface to the the engine contract
     */
    function withdrawAllCollateral(IMarginEngine marginEngine) external {
        // gets the accounts collateral balances
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        ActionArgs[] memory actions = new ActionArgs[](collaterals.length);
        uint256[] memory withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] = ActionArgs({
                action: ACTION_COLLATERAL_REMOVE,
                data: abi.encode(uint80(collaterals[i].amount), address(this), collaterals[i].collateralId)
            });

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);

        emit WithdrewCollateral(withdrawAmounts, msg.sender);
    }

    /**
     * @notice Withdraws some of vault collateral(s) from margin account.
     * @param marginEngine is the interface to the margin engine contract
     */
    function withdrawCollaterals(
        IMarginEngine marginEngine,
        Collateral[] calldata collaterals,
        uint256[] calldata amounts,
        address recipient
    ) external {
        ActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < amounts.length;) {
            if (amounts[i] > 0) {
                actions = ActionUtil.append(
                    actions,
                    ActionArgs({
                        action: ACTION_COLLATERAL_REMOVE,
                        data: abi.encode(uint80(amounts[i]), recipient, collaterals[i].id)
                    })
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws assets based on shares from margin account.
     * @dev used to send assets from the margin account to recipient at the end of each round
     * @param marginEngine is the interface to the margin engine contract
     * @param totalSupply is the total amount of outstanding shares
     * @param withdrawShares the number of shares being withdrawn
     * @param recipient is the destination address for the assets
     */
    function withdrawWithShares(IMarginEngine marginEngine, uint256 totalSupply, uint256 withdrawShares, address recipient)
        external
        returns (uint256[] memory amounts)
    {
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        uint256 collateralLength = collaterals.length;

        amounts = new uint256[](collateralLength);
        ActionArgs[] memory actions = new ActionArgs[](collateralLength);

        for (uint256 i; i < collateralLength;) {
            amounts[i] = FixedPointMathLib.mulDivDown(collaterals[i].amount, withdrawShares, totalSupply);

            unchecked {
                actions[i] = ActionArgs({
                    action: ACTION_COLLATERAL_REMOVE,
                    data: abi.encode(uint80(amounts[i]), recipient, collaterals[i].collateralId)
                });
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);
    }
}
