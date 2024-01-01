// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./UUPSUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ISwapRouter.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";

import "./IFlooring.sol";
import "./OwnedUpgradeable.sol";
import "./CurrencyTransfer.sol";
import "./ERC721Transfer.sol";
import "./Structs.sol";
import "./SafeBox.sol";
import "./Errors.sol";
import "./Constants.sol";
import "./FlooringGetter.sol";

contract FlooringPeriphery is FlooringGetter, OwnedUpgradeable, UUPSUpgradeable, IERC721Receiver {
    error NotUniswapRouter();

    address public immutable uniswapRouter;
    address public immutable WETH9;

    constructor(address flooring, address uniswapV3Router, address _WETH9) FlooringGetter(flooring) {
        uniswapRouter = uniswapV3Router;
        WETH9 = _WETH9;
    }

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Owned_init();
        __UUPSUpgradeable_init();
    }

    function fragmentAndSell(
        address collection,
        uint256[] calldata tokenIds,
        ISwapRouter.ExactInputParams memory swapParam
    ) external returns (uint256 swapOut) {
        uint256 fragmentTokenAmount = tokenIds.length * Constants.FLOOR_TOKEN_AMOUNT;

        address floorToken = fragmentTokenOf(collection);

        /// approve all
        approveAllERC721(collection, address(_flooring));
        approveAllERC20(floorToken, uniswapRouter, fragmentTokenAmount);

        /// transfer tokens into this
        ERC721Transfer.safeBatchTransferFrom(collection, msg.sender, address(this), tokenIds);

        /// fragment
        _flooring.fragmentNFTs(collection, tokenIds, address(this));

        swapOut = ISwapRouter(uniswapRouter).exactInput(swapParam);
    }

    function buyAndClaimExpired(
        address collection,
        uint256[] calldata tokenIds,
        address swapTokenIn,
        ISwapRouter.ExactOutputParams memory swapParam
    ) external payable returns (uint256 tokenCost) {
        uint256 fragmentTokenAmount = tokenIds.length * Constants.FLOOR_TOKEN_AMOUNT;

        address floorToken = fragmentTokenOf(collection);

        approveAllERC20(floorToken, address(_flooring), fragmentTokenAmount);

        tokenCost = swapExactOutput(msg.sender, swapTokenIn, swapParam);

        _flooring.claimExpiredNfts(collection, tokenIds, 0, msg.sender);
    }

    function buyAndClaimVault(
        address collection,
        uint256 claimCnt,
        address swapTokenIn,
        ISwapRouter.ExactOutputParams memory swapParam
    ) external payable returns (uint256 tokenCost) {
        uint256 fragmentTokenAmount = claimCnt * Constants.FLOOR_TOKEN_AMOUNT;

        address floorToken = fragmentTokenOf(collection);

        approveAllERC20(floorToken, address(_flooring), fragmentTokenAmount);

        tokenCost = swapExactOutput(msg.sender, swapTokenIn, swapParam);

        _flooring.claimRandomNFT(collection, claimCnt, 0, msg.sender);
    }

    function swapExactOutput(address payer, address tokenIn, ISwapRouter.ExactOutputParams memory param)
        internal
        returns (uint256 amountIn)
    {
        if (tokenIn == WETH9 && address(this).balance >= param.amountInMaximum) {
            amountIn = ISwapRouter(uniswapRouter).exactOutput{value: param.amountInMaximum}(param);
            IPeripheryPayments(uniswapRouter).refundETH();
            if (address(this).balance > 0) {
                CurrencyTransfer.safeTransfer(CurrencyTransfer.NATIVE, payer, address(this).balance);
            }
        } else {
            approveAllERC20(tokenIn, uniswapRouter, param.amountInMaximum);
            CurrencyTransfer.safeTransferFrom(tokenIn, payer, address(this), param.amountInMaximum);
            amountIn = ISwapRouter(uniswapRouter).exactOutput(param);

            if (param.amountInMaximum > amountIn) {
                CurrencyTransfer.safeTransfer(tokenIn, payer, param.amountInMaximum - amountIn);
            }
        }
    }

    function approveAllERC20(address token, address spender, uint256 desireAmount) private {
        if (desireAmount == 0) {
            return;
        }
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < desireAmount) {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    function approveAllERC721(address collection, address spender) private {
        bool approved = IERC721(collection).isApprovedForAll(address(this), spender);
        if (!approved) {
            IERC721(collection).setApprovalForAll(spender, true);
        }
    }

    function onERC721Received(address, /*operator*/ address, /*from*/ uint256, /*tokenId*/ bytes calldata /*data*/ )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    receive() external payable {
        if (msg.sender != uniswapRouter) revert NotUniswapRouter();
    }
}
