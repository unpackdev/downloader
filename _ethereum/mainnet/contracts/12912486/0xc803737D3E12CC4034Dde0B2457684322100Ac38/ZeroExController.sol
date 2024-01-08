// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IWallet.sol";

contract ZeroExController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line
    IWallet public immutable WALLET;

    constructor(IWallet wallet) public {
        WALLET = wallet;
    }

    function deploy(bytes calldata data) external {
        (address[] memory tokens, uint256[] memory amounts) =
            abi.decode(data, (address[], uint256[]));
        uint256 tokensLength = tokens.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            _approve(IERC20(tokens[i]), amounts[i]);
        }
        WALLET.deposit(tokens, amounts);
    }

    function withdraw(bytes calldata data) external {
        (address[] memory tokens, uint256[] memory amounts) =
            abi.decode(data, (address[], uint256[]));
        WALLET.withdraw(tokens, amounts);
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(WALLET));
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(address(WALLET), type(uint256).max.sub(currentAllowance));
        }
    }
}
