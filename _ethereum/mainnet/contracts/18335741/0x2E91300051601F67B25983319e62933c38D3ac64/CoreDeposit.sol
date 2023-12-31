// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreDepositV1.sol";
import "./Context.sol";
import "./DefinitiveAssets.sol";

import "./DefinitiveErrors.sol";

abstract contract CoreDeposit is ICoreDepositV1, Context {
    using DefinitiveAssets for IERC20;

    function deposit(uint256[] calldata amounts, address[] calldata assetAddresses) external payable virtual;

    function _deposit(uint256[] calldata amounts, address[] calldata erc20Tokens) internal virtual {
        _depositERC20(amounts, erc20Tokens);

        emit Deposit(_msgSender(), erc20Tokens, amounts);
    }

    function _depositERC20(uint256[] calldata amounts, address[] calldata erc20Tokens) internal {
        uint256 amountsLength = amounts.length;
        if (amountsLength != erc20Tokens.length) {
            revert InvalidInputs();
        }

        for (uint256 i; i < amountsLength; ) {
            IERC20(erc20Tokens[i]).safeTransferFrom(_msgSender(), address(this), amounts[i]);
            unchecked {
                ++i;
            }
        }
    }
}
