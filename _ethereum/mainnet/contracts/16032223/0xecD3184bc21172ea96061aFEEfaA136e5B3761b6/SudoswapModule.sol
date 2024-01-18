// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC721.sol";

import "./BaseExchangeModule.sol";
import "./BaseModule.sol";
import "./ISudoswap.sol";

contract SudoswapModule is BaseExchangeModule {
    // --- Fields ---

    ISudoswapRouter public constant SUDOSWAP_ROUTER =
        ISudoswapRouter(0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329);

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- Multiple ETH listings ---

    function buyWithETH(
        ISudoswapPair[] calldata pairs,
        uint256[] calldata nftIds,
        uint256 deadline,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        uint256 pairsLength = pairs.length;
        for (uint256 i; i < pairsLength; ) {
            // Build router data
            ISudoswapRouter.PairSwapSpecific[]
                memory swapList = new ISudoswapRouter.PairSwapSpecific[](1);
            swapList[0] = ISudoswapRouter.PairSwapSpecific({
                pair: pairs[i],
                nftIds: new uint256[](1)
            });
            swapList[0].nftIds[0] = nftIds[i];

            // Fetch the current price quote
            (, , , uint256 price, ) = pairs[i].getBuyNFTQuote(1);

            // Execute fill
            try
                SUDOSWAP_ROUTER.swapETHForSpecificNFTs{value: price}(
                    swapList,
                    address(this),
                    params.fillTo,
                    deadline
                )
            {} catch {
                if (params.revertIfIncomplete) {
                    revert UnsuccessfulFill();
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    // --- Multiple ERC20 listings ---

    function buyWithERC20(
        ISudoswapPair[] calldata pairs,
        uint256[] calldata nftIds,
        uint256 deadline,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the router if needed
        _approveERC20IfNeeded(
            params.token,
            address(SUDOSWAP_ROUTER),
            params.amount
        );

        uint256 pairsLength = pairs.length;
        for (uint256 i; i < pairsLength; ) {
            // Build router data
            ISudoswapRouter.PairSwapSpecific[]
                memory swapList = new ISudoswapRouter.PairSwapSpecific[](1);
            swapList[0] = ISudoswapRouter.PairSwapSpecific({
                pair: pairs[i],
                nftIds: new uint256[](1)
            });
            swapList[0].nftIds[0] = nftIds[i];

            // Fetch the current price quote
            (, , , uint256 price, ) = pairs[i].getBuyNFTQuote(1);

            // Execute fill
            try
                SUDOSWAP_ROUTER.swapERC20ForSpecificNFTs(
                    swapList,
                    price,
                    params.fillTo,
                    deadline
                )
            {} catch {
                if (params.revertIfIncomplete) {
                    revert UnsuccessfulFill();
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    // --- Single ERC721 offer ---

    function sell(
        ISudoswapPair pair,
        uint256 nftId,
        uint256 minOutput,
        uint256 deadline,
        OfferParams calldata params,
        Fee[] calldata fees
    ) external nonReentrant {
        IERC721 collection = pair.nft();

        // Approve the router if needed
        _approveERC721IfNeeded(collection, address(SUDOSWAP_ROUTER));

        // Build router data
        ISudoswapRouter.PairSwapSpecific[]
            memory swapList = new ISudoswapRouter.PairSwapSpecific[](1);
        swapList[0] = ISudoswapRouter.PairSwapSpecific({
            pair: pair,
            nftIds: new uint256[](1)
        });
        swapList[0].nftIds[0] = nftId;

        // Execute fill
        try
            SUDOSWAP_ROUTER.swapNFTsForToken(
                swapList,
                minOutput,
                address(this),
                deadline
            )
        {
            ISudoswapPair.PairVariant variant = pair.pairVariant();

            // Pay fees
            uint256 feesLength = fees.length;
            for (uint256 i; i < feesLength; ) {
                Fee memory fee = fees[i];
                uint8(variant) < 2
                    ? _sendETH(fee.recipient, fee.amount)
                    : _sendERC20(fee.recipient, fee.amount, pair.token());

                unchecked {
                    ++i;
                }
            }

            // Forward any left payment to the specified receiver
            uint8(variant) < 2
                ? _sendAllETH(params.fillTo)
                : _sendAllERC20(params.fillTo, pair.token());
        } catch {
            if (params.revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }

        // Refund any ERC721 leftover
        _sendAllERC721(params.refundTo, collection, nftId);
    }
}
