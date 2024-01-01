/*solhint-disable avoid-low-level-calls */
// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./draft-IERC20Permit.sol";
import "./SafeMath.sol";
import "./ITokenTransferProxy.sol";
import "./IERC20PermitLegacy.sol";

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        address payable beneficiary;
        Utils.Path[] path;
        uint256 feePercent;
        address payable partner;
        uint256 deadline;
    }

    // Data required for cross chain swap in UniswapV2Router
    struct UniswapV2RouterData{
        // Amount that user give to swap 
        uint256 amountIn;
        // Minimal amount that user receive after swap.  
        uint256 amountOutMin;
        // Path of the tokens addresses to swap before DeBridge
        address[] pathBeforeSend;
        // Path of the tokens addresses to swap after DeBridge
        address[] pathAfterSend;
        // Wallet that receive tokens after swap
        address beneficiary;
        // Fee paid to keepers to execute swap in second chain
        uint256 executionFee;
        // Chain id to which tokens are sent
        uint256 chainId;

        uint256 bridge;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        uint256 feePercent;
        address payable partner;
        uint256 deadline;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    // Data required for cross chain swap in SimpleSwap
    struct SimpleDataCrosschain {
        // Path of the tokens addresses to swap before DeBridge
        address[] pathBeforeSend;
        // Path of the tokens addresses to swap after DeBridge
        address[] pathAfterSend;
        // Amount that user give to swap
        uint256 fromAmount;
        // Minimal amount that user will reicive after swap
        uint256 toAmount;
        // Expected amount that user will receive after swap
        uint256 expectedAmount;
        // Addresses of exchanges that will perform swap
        address[] callees;
        // Encoded data to call exchanges
        bytes exchangeData;
        // Start and end indexes of the exchangeData 
        uint256[] startIndexes;
        // Amount of the ether that user send
        uint256[] values;
        // The number of callees used for swap before DeBridge
        uint256 calleesBeforeSend;
        // Address of the wallet that receive tokens
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
        // Fee paid to keepers to execute swap in second chain
        uint256 executionFee;
        // Chain id to which tokens are sent
        uint256 chainId;
        address toApprove;
        uint256 bridge;
    }

    struct ZeroxV4DataCrosschain {
        IERC20[] pathBeforeSend;
        IERC20[] pathAfterSend;
        uint256 fromAmount;
        uint256 amountOutMin;
        address exchangeBeforeSend;
        address exchangeAfterSend;
        bytes payloadBeforeSend;
        bytes payloadAfterSend;
        address payable beneficiary;
        uint256 executionFee;
        uint256 chainId;
        uint256 bridge;
    }

    // Data required for cross chain swap in MultiPath
    struct SellDataCrosschain {
        // Addresses of two tokens from which swap will begin if different chains
        address[] fromToken;
        // Amount that user give to swap
        uint256 fromAmount;
        // Minimal amount that user will reicive after swap
        uint256 toAmountBefore;
        uint256 toAmountAfter;
        address payable beneficiary;
        // Array of Paths that  perform swap before DeBridge
        Utils.Path[] pathBeforeSend;
        // Array of Paths that perform swap after DeBridge
        Utils.Path[] pathAfterSend;
        uint256 feePercent;
        address payable partner;
        uint256 deadlineBefore;
        uint256 deadlineAfter;
    }

    struct MegaSwapSellDataCrosschain {
        address[] fromToken;
        uint256 fromAmount;
        uint256 toAmountBefore;
        uint256 toAmountAfter;
        address payable beneficiary;
        Utils.MegaSwapPath[] pathBeforeSend;
        Utils.MegaSwapPath[] pathAfterSend;
        uint256 feePercent;
        address payable partner;
        uint256 deadlineBefore;
        uint256 deadlineAfter;
    }

    struct Adapter {
        // Address of the adapter that perform swap
        address payable adapter;
        // Percent of tokens to be swapped
        uint256 percent;
        Route[] route;
    }

    struct Route {
        // Index of the router in the adapter
        uint256 index; //Adapter at which index needs to be used
        // Address of the exhcnage that will execute swap
        address targetExchange;
        // Percent of tokens to be swapped
        uint256 percent;
        // Data for the exchange
        bytes payload;
        uint256 networkFee;
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        // Address of the token that user will receive after swap
        address to;
        Adapter[] adapters;
    }

    // Data required for cross chain swap in MultiPath
    struct UniswapV2Fork {
        // Address of the token that user will swap
        address[] tokenIn;

        uint256 amountIn;
        // Minimal amount of tokens that user will receive
        uint256 amountOutMinBefore;
        uint256 amountOutMinAfter;
        // Address of wrapped native token, if user swap native token
        address wethBefore;
        address wethAfter;
        // Number that contains address of the pair, direction and exchange fee
        uint256[] poolsBeforeSend;

        uint256[] poolsAfterSend;
        address beneficiary;
        address partner;
    }

    struct SwapData{
        address fromToken;
        uint256 fromAmount;
        uint256 minAmountOut;
        address weth;
        PathData[] path;
        address partner;
    }

    struct PathData {
        address toToken;
        address exchange;
        uint24 fee;
        uint256 deadline;
        uint160 sqrtPriceLimitX96;
    }

    // struct CrosschainData {
    //     // Chain id to which tokens are sent
    //     uint256 chainId;
    //     //1 - hyphen
    //     //2 - connext
    //     Bridge bridge;
    //     uint256 relayerFee;
    // }

    // enum Bridge {
    //     Hyphen,
    //     Connext
    // }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(
                address(this),
                addressToApprove
            );

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{value: amount, gas: 10000}("");
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account)
        internal
        view
        returns (uint256)
    {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(
                abi.encodePacked(IERC20Permit.permit.selector, permit)
            );
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(
                abi.encodePacked(IERC20PermitLegacy.permit.selector, permit)
            );
            require(success, "Permit failed");
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{value: amount, gas: 10000}("");
            require(result, "Transfer ETH failed");
        }
    }

    function getChainId(uint256 chainId) public view returns (bool) {
        uint256 cid;
        assembly {
            cid := chainid()
        }
        if(chainId == cid) {
            return true;
        } else {
            return false;
        }
    }
}
