//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./Context.sol";
import "./SafeERC20.sol";
import "./Strings.sol";

import "./ILibertiV2Vault.sol";

/**
 * @dev The LibertiV2Proxy contract should not be confused with an Upgradeable proxy.
 * Its primary purpose is to act as a proxy for interacting with a vault instance,
 * facilitating deposits into the vault within a decentralized application.
 * However, there can be inconvenience when a user lacks the necessary tokens
 * to match the vault's asset composition. This is where the proxy contract serves
 * as a valuable aid: the user deposits one asset, and the proxy automatically
 * swaps a portion of that asset into the required tokens. Subsequently, the proxy
 * deposits these assets into the vault and returns the LP token of the vault to the depositor.
 *
 * Currently, Libertify exclusively offers vaults that consist of two assets:
 * an ERC20 token (such as WETH, MANA, SNX, etc.) and a stablecoin (like USDT).
 *
 * We anticipate replacing this proxy contract in the future to accommodate new features.
 * This evolution will enable more protocols to assist in swapping assets into the required
 * vault assets while also exposing data to our backend and frontend interfaces.
 *
 * The functions `deposit` and `withdraw` have been encapsulated within `depositWithSymbolCheck`
 * and `withdrawWithSymbolCheck`. These specialized functions are specifically designed for use with
 * the Ledger plugin. They serve the purpose of displaying the asset symbol that a user is securing
 * during deposit and likewise, the symbol of the asset being redeemed during withdrawal.
 */

contract LibertiV2Proxy is Context {
    using SafeERC20 for IERC20;
    using Strings for string;

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
    address private constant ONE_INCH_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address private immutable WETH_ADDR;

    error BadConstructor();
    error BadReceiver();
    error BadReturn();
    error BadSymbol();
    error BadSwap();
    error BadToken();
    error BadValue();
    error UnevenSwap();

    constructor(address _wethAddr) {
        if (address(0) == _wethAddr) revert BadConstructor();
        WETH_ADDR = _wethAddr;
    }

    function depositWithSymbolCheck(
        uint256 amountIn,
        address srcToken,
        address vaultAddr,
        string memory vaultSymbol,
        bytes[] calldata data
    ) external payable returns (uint256) {
        if (!vaultSymbol.equal(ILibertiV2Vault(vaultAddr).symbol())) revert BadSymbol();
        return deposit(amountIn, srcToken, vaultAddr, data);
    }

    function withdrawWithSymbolCheck(
        uint256 amountIn,
        address dstToken,
        address vaultAddr,
        uint256 minAmountOut,
        string memory vaultSymbol,
        bytes[] calldata data
    ) external returns (uint256) {
        if (!vaultSymbol.equal(ILibertiV2Vault(vaultAddr).symbol())) revert BadSymbol();
        return withdraw(amountIn, dstToken, vaultAddr, minAmountOut, data);
    }

    /**
     * @dev Same as withdraw. Consumes an EIP-2612 signature to approve spending of LP tokens by the vault.
     */
    function withdraw(
        uint256 amountIn,
        address dstToken,
        address vaultAddr,
        uint256 minAmountOut,
        bytes[] calldata data,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        ILibertiV2Vault vault = ILibertiV2Vault(vaultAddr);
        vault.permit(_msgSender(), address(this), amountIn, deadline, v, r, s);
        return withdraw(amountIn, dstToken, vaultAddr, minAmountOut, data);
    }

    function previewWithdraw(
        uint256 amountIn,
        address vaultAddr
    ) external view returns (address[] memory tokens, uint256[] memory amountsOut) {
        ILibertiV2Vault vault = ILibertiV2Vault(vaultAddr);
        tokens = vault.getTokens();
        amountsOut = vault.getAmountsOut(amountIn);
    }

    function deposit(
        uint256 amountIn,
        address srcToken,
        address vaultAddr,
        bytes[] calldata data
    ) public payable returns (uint256) {
        ILibertiV2Vault vault = ILibertiV2Vault(vaultAddr);
        address[] memory tokens = vault.getTokens();
        uint256[] memory maxAmountsIn = new uint256[](2);

        /**
         * @dev The data array always contains two elements. These elements can either be null or calldata for a swap on 1inch.
         *
         * When depositing the native currency of the blockchain, the backend will generate calldata for one or two trading routes:
         *   - The first route is to swap a portion or the full amount of the native currency into the target asset.
         *   - The second route involves swapping some of the amount into the stablecoin.
         *
         * When depositing an ERC20 token, the backend will generate calldata for a single route if a portion or the full amount
         * of the asset needs to be converted into the stablecoin.
         */
        if (ONE_INCH_ETH_ADDRESS == srcToken) {
            if (amountIn != msg.value) revert BadValue();
            if (2 < data.length) revert BadSwap();
            for (uint256 i = 0; i < data.length; i++) {
                (, SwapDescription memory desc, ) = abi.decode(
                    data[i][4:],
                    (address, SwapDescription, bytes)
                );
                if (desc.dstReceiver != address(this)) revert BadReceiver();
                if ((WETH_ADDR != address(desc.dstToken)) && (tokens[1] != address(desc.dstToken)))
                    revert BadToken();
                if (ONE_INCH_ETH_ADDRESS == address(desc.srcToken)) {
                    // solhint-disable-next-line avoid-low-level-calls
                    (bool success, bytes memory returndata) = AGGREGATION_ROUTER_V5.call{
                        value: desc.amount
                    }(data[i]);
                    if (!success) {
                        // solhint-disable-next-line no-inline-assembly
                        assembly {
                            revert(add(returndata, 32), mload(returndata))
                        }
                    }
                    (uint256 returnAmount, ) = abi.decode(returndata, (uint256, uint256));
                    if (WETH_ADDR == address(desc.dstToken)) {
                        maxAmountsIn[0] += returnAmount;
                    } else {
                        maxAmountsIn[1] += returnAmount;
                    }
                } else {
                    revert BadToken();
                }
            }
        } else {
            // If a swap is required it will be necessarily in the first element of the array
            IERC20(srcToken).safeTransferFrom(_msgSender(), address(this), amountIn);
            if (0 == data.length) {
                maxAmountsIn[0] = amountIn;
                maxAmountsIn[1] = 0;
            } else {
                if (1 != data.length) revert BadSwap();
                (, SwapDescription memory desc, ) = abi.decode(
                    data[0][4:],
                    (address, SwapDescription, bytes)
                );
                if (desc.dstReceiver != address(this)) revert BadReceiver();
                if ((tokens[0] != address(desc.srcToken)) || (tokens[1] != address(desc.dstToken)))
                    revert BadToken();
                desc.srcToken.safeIncreaseAllowance(AGGREGATION_ROUTER_V5, desc.amount);
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, bytes memory returndata) = AGGREGATION_ROUTER_V5.call(data[0]);
                if (!success) {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(returndata, 32), mload(returndata))
                    }
                }
                (uint256 returnAmount, ) = abi.decode(returndata, (uint256, uint256));
                maxAmountsIn[0] = amountIn - desc.amount;
                maxAmountsIn[1] = returnAmount;
            }
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            if (0 < maxAmountsIn[i])
                IERC20(tokens[i]).safeIncreaseAllowance(vaultAddr, maxAmountsIn[i]);
        }
        (uint256 amountOut, uint256[] memory amountsIn) = vault.deposit(maxAmountsIn, _msgSender());
        // Transfer surplus to user
        for (uint256 i = 0; i < tokens.length; i++) {
            if (maxAmountsIn[i] > amountsIn[i])
                IERC20(tokens[i]).safeTransfer(_msgSender(), maxAmountsIn[i] - amountsIn[i]);
        }
        return amountOut;
    }

    /**
     * @dev Users have the flexibility to withdraw in the native currency of the blockchain. In this case,
     * the backend will include one or two 1inch routes within the data array. The first route facilitates
     * the exchange of the blockchain's wrapped token into the native currency, and the second route handles
     * the conversion of the stablecoin into the native currency. It's important to highlight that while
     * the balances of both the asset and stablecoin in the vault can be null, not all balances can be null.
     */
    function withdraw(
        uint256 amountIn,
        address dstToken,
        address vaultAddr,
        uint256 minAmountOut,
        bytes[] calldata data
    ) public returns (uint256 amountOut) {
        ILibertiV2Vault vault = ILibertiV2Vault(vaultAddr);
        address[] memory tokens = vault.getTokens();
        uint256[] memory amountsOut = vault.withdraw(amountIn, address(this), _msgSender());
        for (uint256 i = 0; i < data.length; i++) {
            if (0 < data[i].length) {
                (, SwapDescription memory desc, ) = abi.decode(
                    data[i][4:],
                    (address, SwapDescription, bytes)
                );
                if (amountsOut[i] != desc.amount) revert UnevenSwap();
                if (desc.dstReceiver != _msgSender()) revert BadReceiver();
                if (
                    !vault.isBoundTokens(address(desc.srcToken)) ||
                    (dstToken != address(desc.dstToken))
                ) revert BadToken();
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
                // Token is the wanted token, or token amount is not swappable (too low, no liquidity...)
                if (0 < amountsOut[i]) {
                    IERC20(tokens[i]).safeTransfer(_msgSender(), amountsOut[i]);
                    if (tokens[i] == dstToken) amountOut += amountsOut[i];
                }
            }
        }
        if (amountOut < minAmountOut) revert BadReturn();
    }
}
