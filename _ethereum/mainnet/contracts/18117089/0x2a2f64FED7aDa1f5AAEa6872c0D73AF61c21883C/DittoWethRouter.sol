// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoRouter.sol";
import "./IDittoWethRouter.sol";
import "./IWeth9.sol";
import "./DittoRouter.sol";
import "./RouterStructs.sol";
import "./SwapArgs.sol";

import "./IERC721.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./IDittoPool.sol";
import "./ILpNft.sol";
import "./CurveErrorCode.sol";

contract DittoWethRouter is IDittoWethRouter, DittoRouter {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address payable;

    IWeth9 private constant _weth = IWeth9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoWethRouterIncorrectInputAmount();
    error DittoWethRouterPlainSendOfEthNotAllowed();
    error DittoWethRouterOutputAmountTooLow();
    error DittoWethRouterNotApprovedPool();
    error DittoWethRouterNotAuthorizedToManipulateLpId();
    error DittoWethRouterNotImplemented();
    error DittoWethRouterNotWethPool();

    constructor(ILpNft lpNft_) DittoRouter(lpNft_) { }

    // ***************************************************************
    // * ======= FUNCTIONS TO MARKET MAKE: ADD LIQUIDITY =========== *
    // ***************************************************************

    ///@inheritdoc IDittoWethRouter
    function createLiquidity(
        IDittoPool dittoPool_,
        address lpRecipient_,
        uint256[] calldata nftIdList_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external payable nonReentrant returns (uint256 lpId) {
        _obtainLiquidity(dittoPool_, nftIdList_);
        _setApprovals(dittoPool_);

        lpId = dittoPool_.createLiquidity(lpRecipient_, nftIdList_, msg.value, permitterData_, referrer_);
    }

    ///@inheritdoc IDittoWethRouter
    function addLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external payable nonReentrant {
        IDittoPool dittoPool = _requireLpIdValid(lpId_);
        _obtainLiquidity(dittoPool, nftIdList_);
        _setApprovals(dittoPool);

        dittoPool.addLiquidity(lpId_, nftIdList_, msg.value, permitterData_, referrer_);
    }

    // ***************************************************************
    // * ===== FUNCTIONS TO MARKET MAKE: REMOVE LIQUIDITY ========== *
    // ***************************************************************

    ///@inheritdoc IDittoWethRouter
    function pullLiquidity(
        address payable withdrawalAddress_,
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenWithdrawAmount_
    ) external nonReentrant {
        IDittoPool dittoPool = _requireLpIdValid(lpId_);
        dittoPool.pullLiquidity(address(this), lpId_, nftIdList_, tokenWithdrawAmount_);
        _wethWithdraw(tokenWithdrawAmount_, withdrawalAddress_);
        _transferNfts(dittoPool.nft(), address(this), withdrawalAddress_, nftIdList_);
    }

    // ***************************************************************
    // * ================ TRADING TOKENS FOR STUFF ================= *
    // ***************************************************************

    ///@inheritdoc IDittoRouter
    ///@dev unimplemented on WethRouter, use swapEthForNfts instead
    function swapTokensForNfts(
        Swap[] calldata,
        uint256,
        address,
        uint256
    ) external virtual override(IDittoRouter, DittoRouter) returns (uint256) {
        revert DittoWethRouterNotImplemented();
    }

    ///@inheritdoc IDittoWethRouter
    function swapEthForNfts(
        Swap[] calldata swapList,
        address nftRecipient,
        uint256 deadline
    ) external payable nonReentrant checkDeadline(deadline) returns (uint256 remainingValue) {
        _wethDeposit(msg.value);

        remainingValue = _swapListWethForNfts(swapList, msg.value, nftRecipient);

        _wethWithdraw(remainingValue, msg.sender);
    }

    ///@inheritdoc IDittoRouter
    ///@dev unimplemented on WethRouter, use robustSwapEthForNfts instead
    function robustSwapTokensForNfts(
        RobustSwap[] calldata,
        uint256,
        address,
        uint256
    ) public virtual override(IDittoRouter, DittoRouter) returns (uint256) {
        revert DittoWethRouterNotImplemented();
    }

    ///@inheritdoc IDittoWethRouter
    function robustSwapEthForNfts(
        RobustSwap[] calldata swapList,
        address nftRecipient,
        uint256 deadline
    ) external payable nonReentrant checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = _robustSwapEthForNfts(swapList, nftRecipient);
    }

    ///@inheritdoc IDittoRouter
    ///@dev unimplemented on WethRouter, use robustSwapEthForNfts instead
    function robustSwapTokensForNftsAndNftsForTokens(RobustComplexSwap calldata)
        external
        virtual
        override(IDittoRouter, DittoRouter)
        returns (uint256, uint256)
    {
        revert DittoWethRouterNotImplemented();
    }

    ///@inheritdoc IDittoWethRouter
    function robustSwapEthForNftsAndNftsForTokens(RobustComplexSwap calldata params)
        external
        payable
        virtual
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        if (params.inputAmount != msg.value) {
            revert DittoWethRouterIncorrectInputAmount();
        }
        remainingValue = _robustSwapEthForNfts(params.tokenToNftTrades, params.nftRecipient);
        outputAmount = _robustSwapNftsForTokens(params.nftToTokenTrades, params.tokenRecipient);
    }

    // ***************************************************************
    // * ================= TRADING NFTs FOR STUFF ================== *
    // ***************************************************************

    ///@inheritdoc IDittoRouter
    function swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    )
        external
        virtual
        override(IDittoRouter, DittoRouter)
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 outputAmount)
    {
        outputAmount = _swapNftsForTokens(swapList, minOutput);
        _wethWithdraw(outputAmount, tokenRecipient);
    }

    ///@inheritdoc IDittoRouter
    function swapNftsForSpecificNftsThroughTokens(
        ComplexSwap calldata,
        uint256,
        uint256,
        address,
        uint256
    ) external virtual override(IDittoRouter, DittoRouter) returns (uint256) {
        revert DittoWethRouterNotImplemented();
    }

    ///@inheritdoc IDittoWethRouter
    function swapNftsForSpecificNftsThroughEth(
        ComplexSwap calldata trade,
        uint256 minOutput,
        address outputRecipient,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 outputAmount)
    {
        // Swap Nfts for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNftsForTokens(trade.nftToTokenTrades, 0);

        // Add extra value to buy Nfts
        _wethDeposit(msg.value);
        outputAmount += msg.value;

        // Swap Weth for specific Nfts
        // input tokens are taken from address(this)
        outputAmount = _swapListWethForNfts(trade.tokenToNftTrades, outputAmount, outputRecipient);
        if (outputAmount < minOutput) {
            revert DittoWethRouterOutputAmountTooLow();
        }
        _wethWithdraw(outputAmount, outputRecipient);
    }

    ///@inheritdoc IDittoRouter
    function robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient,
        uint256 deadline
    )
        public
        virtual
        override(IDittoRouter, DittoRouter)
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 outputAmount)
    {
        outputAmount = _robustSwapNftsForTokens(swapList, tokenRecipient);
    }

    /**
     * @notice Pull Liquidity requires the router to receive ether, from the WETH contract, as an intermediary
     */
    receive() external payable {
        if (msg.sender != address(_weth)) {
            revert DittoWethRouterPlainSendOfEthNotAllowed();
        }
    }

    /**
     * @notice Pull Liquidity requires the router to receive NFTs as an intermediary
     */
    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        if (!_lpNft.isApprovedDittoPool(operator)) {
            revert DittoRouterNotApprovedPool();
        }

        return this.onERC721Received.selector;
    }

    // ***************************************************************
    // * ================= RESTRICTED FUNCTIONS ==================== *
    // ***************************************************************

    ///@inheritdoc IDittoRouter
    function poolTransferErc20From(
        ERC20 token,
        address,
        address to,
        uint256 amount
    ) external override(IDittoRouter, DittoRouter) {
        _requireWethOnly(address(token));
        // verify caller is a trusted pair contract
        if (!_lpNft.isApprovedDittoPool(msg.sender)) {
            revert DittoWethRouterNotApprovedPool();
        }

        // transfer tokens to pair
        token.safeTransfer(to, amount);
    }

    // ***************************************************************
    // * ================ INTERNAL HELPER FUNCTIONS ================ *
    // ***************************************************************

    ///@notice see IDittoWethRouter.robustSwapEthForNfts
    function _robustSwapEthForNfts(
        RobustSwap[] calldata swapList,
        address nftRecipient
    ) internal returns (uint256 remainingValue) {
        _wethDeposit(msg.value);
        remainingValue = msg.value;
        uint256 poolCost;
        CurveErrorCode cError;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        RobustSwap calldata swap;
        for (uint256 i; i < numSwaps;) {
            swap = swapList[i];
            // Calculate actual cost per swap
            (cError,,, poolCost,) = swap.pool.getBuyNftQuote(swap.nftIds.length, swap.swapData);

            // If within our maxCost and no error, proceed
            if (poolCost <= swap.maxCost && cError == CurveErrorCode.OK) {
                remainingValue -=
                    _swapWethForNfts(swap.pool, swap.nftIds, poolCost, address(this), nftRecipient, swap.swapData);
            }

            unchecked {
                ++i;
            }
        }

        _wethWithdraw(remainingValue, msg.sender);
    }

    /// @notice internal function stack too deep issues
    function _swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput
    ) internal returns (uint256 outputAmount) {
        // Do swaps
        uint256 numSwaps = swapList.length;
        NftInSwap calldata swap;
        for (uint256 i; i < numSwaps;) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            swap = swapList[i];
            outputAmount += _swapNftsForWeth(
                swap.pool, swap.nftIds, swap.lpIds, 0, msg.sender, address(this), swap.permitterData, swap.swapData
            );
            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        if (outputAmount < minOutput) {
            revert DittoWethRouterOutputAmountTooLow();
        }
    }

    function _robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient
    ) internal override returns (uint256 outputAmount) {
        uint256 numSwaps = swapList.length;
        // Try doing each swap
        for (uint256 i; i < numSwaps;) {
            outputAmount += _robustSwapNftsForTokensIteration(swapList[i]);
            unchecked {
                ++i;
            }
        }
        _wethWithdraw(outputAmount, tokenRecipient);
    }

    /**
     * @notice Internal function to check that the token is Weth
     * @param token the token to check
     */
    function _requireWethOnly(address token) internal pure {
        if (token != address(_weth)) {
            revert DittoWethRouterNotWethPool();
        }
    }

    /**
     * @notice Weth Deposit with amount check for saving gas
     * @param amount the amount of Weth to deposit
     */
    function _wethDeposit(uint256 amount) internal {
        if (amount > 0) {
            _weth.deposit{ value: amount }();
        }
    }

    /**
     * @notice Weth Withdraw with amount check for saving gas
     * @param amount the amount of Weth to withdraw
     */
    function _wethWithdraw(uint256 amount, address recipient) internal {
        if (amount > 0) {
            _weth.withdraw(amount);
            payable(recipient).safeTransferETH(amount);
        }
    }

    /**
     * @notice Internal function gets the dittoPool for an Lp Position and checks that msg.sender is permitted
     * @param lpId_ the id of the lp position
     * @return dittoPool the dittoPool for the lp position
     */
    function _requireLpIdValid(uint256 lpId_) internal view returns (IDittoPool dittoPool) {
        address lpNftOwner;
        (dittoPool, lpNftOwner) = _lpNft.getPoolAndOwnerForLpId(lpId_);
        _requireWethOnly(address(dittoPool.token()));

        if (lpNftOwner != msg.sender && !_lpNft.isApproved(msg.sender, lpId_)) {
            revert DittoWethRouterNotAuthorizedToManipulateLpId();
        }
    }

    /**
     * @notice Transfer the NFTs to the clone, so that it can create the factory which will send them to the pair.
     *
     * @param nft_ address of the NFT collection
     * @param from_ address to transfer from
     * @param to_ address to transfer to
     * @param nftIdList_ array of token IDs for the NFT to transfer
     */
    function _transferNfts(
        IERC721 nft_,
        address from_,
        address to_,
        uint256[] calldata nftIdList_
    ) internal {
        uint256 countTokenIds = nftIdList_.length;
        uint256 tokenId;
        for (uint256 i = 0; i < countTokenIds;) {
            tokenId = nftIdList_[i];
            nft_.transferFrom(from_, to_, tokenId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set router approvals on NFT and Token contracts for a given ditto pool
     * @param dittoPool_ the ditto pool to set approvals for
     * @dev Weth approval is set to uint256 max
     */
    function _setApprovals(IDittoPool dittoPool_) internal {
        if (!_lpNft.isApprovedDittoPool(address(dittoPool_))) {
            revert DittoWethRouterNotApprovedPool();
        }
        IERC721 nft = dittoPool_.nft();
        if (nft.isApprovedForAll(address(this), address(dittoPool_)) == false) {
            nft.setApprovalForAll(address(dittoPool_), true);
        }
        if (_weth.allowance(address(this), address(dittoPool_)) < type(uint248).max) {
            ERC20(address(_weth)).safeApprove(address(dittoPool_), type(uint256).max);
        }
    }

    /**
     * @notice Pull the liquidity from the msg.sender into the router so the router can deposit it into the DittoPool
     * @param dittoPool_ address of the DittoPool to deposit liquidity into
     * @param nftIdList_ array of token IDs to deposit liquidity with
     */
    function _obtainLiquidity(IDittoPool dittoPool_, uint256[] calldata nftIdList_) internal {
        _requireWethOnly(address(dittoPool_.token()));

        // Deposit ETH into WETH owned by address(this)
        _wethDeposit(msg.value);
        // Transfer NFTs from msg.sender to address(this)
        _transferNfts(dittoPool_.nft(), msg.sender, address(this), nftIdList_);
    }

    /**
     * @notice see IDittoRouter.robustSwapNftsForTokens: this is an internal function to avoid stack too deep errors
     * @param swap The swap to perform
     * @return outputAmount The number of tokens that the recipient will get, or zero if the swap does not meet conditions
     */
    function _robustSwapNftsForTokensIteration(RobustNftInSwap calldata swap)
        internal
        returns (uint256 outputAmount)
    {
        (CurveErrorCode cError, uint256 poolOutput) =
            _getSellQuoteThrowAwayUnneeded(swap.pool, swap.nftIds.length, swap.swapData);

        // If at least equal to our minOutput, proceed
        if (cError == CurveErrorCode.OK && poolOutput >= swap.minOutput) {
            // Do the swap and update outputAmount with how many tokens we got
            outputAmount = _swapNftsForWeth(
                swap.pool, swap.nftIds, swap.lpIds, 0, msg.sender, address(this), swap.permitterData, swap.swapData
            );
        }
    }

    /**
     * @notice Wrapper for swapNftsForTokens with Weth token type check
     * @param pool_ The DittoPool to swap NFTs for WETH in
     * @param nftIds_ The NFT IDs to swap
     * @param lpIds_ The LP IDs to use as counterparties for the trade
     * @param minExpectedTokenOutput_ The minimum amount of WETH to receive, otherwise swap fails
     * @param nftSender_ The address to transfer the NFTs from
     * @param tokenRecipient_ The address to send the WETH to
     * @param permitterData_ The permit data for the NFTs to check if they are allowed in the pool
     * @return outputAmount the amount of WETH received from this swap
     */
    function _swapNftsForWeth(
        IDittoPool pool_,
        uint256[] calldata nftIds_,
        uint256[] calldata lpIds_,
        uint256 minExpectedTokenOutput_,
        address nftSender_,
        address tokenRecipient_,
        bytes calldata permitterData_,
        bytes calldata swapData_
    ) internal returns (uint256 outputAmount) {
        _requireWethOnly(address(pool_.token()));

        outputAmount = pool_.swapNftsForTokens(SwapNftsForTokensArgs({
            nftIds: nftIds_, 
            lpIds: lpIds_,
            minExpectedTokenOutput: minExpectedTokenOutput_, 
            nftSender: nftSender_,
            tokenRecipient: tokenRecipient_,
            permitterData: permitterData_,
            swapData: swapData_
        }));
    }

    /**
     * @notice Wrapper for swapTokensForNfts with Weth token type check
     * @param pool The pool to use for trading
     * @param nftIds The NFTs to trade
     * @param maxTokenInput_ The maximum amount of WETH to spend
     * @param tokenSender_ The address to send the WETH from
     * @param nftRecipient_ The address to send the NFTs to
     * @return remainingValue The amount of WETH remaining after this function executes
     */
    function _swapWethForNfts(
        IDittoPool pool,
        uint256[] calldata nftIds,
        uint256 maxTokenInput_,
        address tokenSender_,
        address nftRecipient_,
        bytes calldata swapData_
    ) internal returns (uint256 remainingValue) {
        _requireWethOnly(address(pool.token()));

        remainingValue = pool.swapTokensForNfts(SwapTokensForNftsArgs({
            nftIds: nftIds, 
            maxExpectedTokenInput: maxTokenInput_,
            tokenSender: tokenSender_,
            nftRecipient: nftRecipient_,
            swapData: swapData_
        }));
    }

    /**
     * @notice helper function for swapEthForNfts & swapNftsForSpecificNftsThroughEth to share logic
     * @param swapList_ The list of trades to perform, WETH->NFTs
     * @param nftRecipient_ The address to send the NFTs to
     * @param remainingValue_ The amount of WETH remaining to spend before this function executes
     * @return remainingValue The amount of WETH remaining after this function executes
     */
    function _swapListWethForNfts(
        Swap[] calldata swapList_,
        uint256 remainingValue_,
        address nftRecipient_
    ) internal returns (uint256 remainingValue) {
        remainingValue = remainingValue_;

        // Do swaps
        uint256 numSwaps = swapList_.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            Swap calldata swap = swapList_[i];
            remainingValue -= _swapWethForNfts(
                swap.pool, swap.nftIds, remainingValue, address(this), nftRecipient_, swap.swapData
            );

            unchecked {
                ++i;
            }
        }
    }
}
