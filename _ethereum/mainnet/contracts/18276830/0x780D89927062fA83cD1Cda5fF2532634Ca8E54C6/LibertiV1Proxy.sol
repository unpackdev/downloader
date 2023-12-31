//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./Context.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ILibertiVault.sol";

contract LibertiV1Proxy is Context, Ownable {
    using SafeERC20 for IERC20;
    using Strings for string;
    using Math for uint256;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver; // from
        address dstReceiver; // to
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    address private constant AGGREGATION_ROUTER_V5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    bytes4 private constant SWAP_SELECTOR_V5 = 0x12aa3caf;

    error BadSelector();
    error BadSymbol();
    error BadReceiver();
    error BadReturn();
    error OnlyFullWithdraw();
    error UnevenSwap();

    constructor() Ownable() {
        // solhint-disable-previous-line no-empty-blocks
    }

    function previewWithdraw(
        uint256 amountIn,
        address vaultAddr
    ) external view returns (address[] memory tokens, uint256[] memory amountsOut) {
        ILibertiVault vault = ILibertiVault(vaultAddr);
        uint256 supply = vault.totalSupply();
        uint256 exitFeeAmount = amountIn.mulDiv(vault.exitFee(), 10_000);
        amountIn -= exitFeeAmount;

        address asset = vault.asset();
        address other = vault.other();

        tokens = new address[](2);
        tokens[0] = asset;
        tokens[1] = other;

        amountsOut = new uint256[](2);
        amountsOut[0] = IERC20(asset).balanceOf(vaultAddr).mulDiv(amountIn, supply);
        amountsOut[1] = IERC20(other).balanceOf(vaultAddr).mulDiv(amountIn, supply);
    }

    function withdraw(
        uint256 amountIn,
        address dstToken,
        address vaultAddr,
        uint256 minAmountOut,
        bytes[] calldata data
    ) public returns (uint256 amountOut) {
        ILibertiVault vault = ILibertiVault(vaultAddr);

        IERC20(vaultAddr).safeTransferFrom(_msgSender(), address(this), amountIn);

        address[] memory tokens = new address[](2);
        tokens[0] = vault.asset();
        tokens[1] = vault.other();

        uint256[] memory amountsOut = new uint256[](2);
        (amountsOut[0], amountsOut[1]) = vault.exit();

        for (uint i = 0; i < 2; i++) {
            if (0 < data[i].length) {
                if (bytes4(data[i][:4]) != SWAP_SELECTOR_V5) revert BadSelector();
                (, SwapDescription memory desc, ) = abi.decode(
                    data[i][4:],
                    (address, SwapDescription, bytes)
                );
                if (amountsOut[i] != desc.amount) revert UnevenSwap();
                if (desc.dstReceiver != _msgSender()) revert BadReceiver();
                desc.srcToken.safeIncreaseAllowance(AGGREGATION_ROUTER_V5, desc.amount);
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, bytes memory returndata) = AGGREGATION_ROUTER_V5.call(data[i]);
                if (!success) {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(returndata, 32), mload(returndata))
                    }
                }
                (uint256 returnAmount, ) = abi.decode(returndata, (uint256, uint256));
                amountOut += returnAmount;
            } else {
                // Token is the wanted token, or token amount is not swappable (amount too low, no liquidity)
                if (0 < amountsOut[i]) {
                    IERC20(tokens[i]).safeTransfer(_msgSender(), amountsOut[i]);
                    if (tokens[i] == dstToken) amountOut += amountsOut[i];
                }
            }
        }
        if (amountOut < minAmountOut) revert BadReturn();
    }

    function withdrawWithSymbolCheck(
        uint256 amountIn,
        address dstToken,
        address vaultAddr,
        uint256 minAmountOut,
        string memory vaultSymbol,
        bytes[] calldata data
    ) external returns (uint256) {
        if (!vaultSymbol.equal(ILibertiVault(vaultAddr).symbol())) revert BadSymbol();
        return withdraw(amountIn, dstToken, vaultAddr, minAmountOut, data);
    }

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    function rescueToken(address _token, address _to) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.safeTransfer(_to, token.balanceOf(address(this)));
    }

    error FailedTransfer();

    function rescueEth(address _to) external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
    }
}
