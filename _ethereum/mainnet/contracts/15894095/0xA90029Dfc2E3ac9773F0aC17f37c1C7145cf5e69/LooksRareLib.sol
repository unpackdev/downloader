// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";

import "./ILooksRareAdapter.sol";

library LooksRareLib {
    using SafeERC20 for IERC20;

    address private constant _looksRareExchange =
        0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address private constant _transferSelectorNft =
        0x9Ba628F27aAc9B2D78A9f2Bf40A8a6DF4Ccd9e2c;
    address private constant _royaltyFeeManager =
        0xCBfebA41C3e69d24B5C8b04Ed60C42CC5D883620;

    // All looksrare transfer manager are here.
    address private constant _ERC721Manager =
        0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
    address private constant _ERC1155Manager =
        0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051;
    address private constant _ERC721ManagerNonCompliant =
        0x3e538190635F51435298Ee58a7984961120510a1;

    bytes4 private constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 private constant IID_IERC721 = type(IERC721).interfaceId;

    function buyAssetForEth(
        ILooksRareExchange.TakerOrder calldata takerOrder,
        ILooksRareExchange.MakerOrder calldata makerOrder
    ) external {
        try
            ILooksRareExchange(_looksRareExchange)
                .matchAskWithTakerBidUsingETHAndWETH{value: takerOrder.price}(
                takerOrder,
                makerOrder
            )
        {
            _nftTransfer(
                address(this),
                msg.sender,
                makerOrder.collection,
                makerOrder.tokenId,
                makerOrder.amount
            );
        } catch {
            revert("Buyer takes order failed.");
        }
    }

    function buyAssetForERC20(
        ILooksRareExchange.TakerOrder calldata takerOrder,
        ILooksRareExchange.MakerOrder calldata makerOrder
    ) external {
        // Step 1 - Transfer ERC20 to adapter
        IERC20(makerOrder.currency).safeTransferFrom(
            msg.sender,
            address(this),
            takerOrder.price
        );
        // Step 2 - Adapter approve ERC20 to LooksRareExchange
        IERC20(makerOrder.currency).safeApprove(
            _looksRareExchange,
            takerOrder.price
        );
        // Step 3 - trade
        try
            ILooksRareExchange(_looksRareExchange).matchAskWithTakerBid(
                takerOrder,
                makerOrder
            )
        {
            // Step 4 - Transfer nft to recipient
            _nftTransfer(
                address(this),
                msg.sender,
                makerOrder.collection,
                makerOrder.tokenId,
                makerOrder.amount
            );
        } catch {
            revert("Buyer takes order failed.");
        }
        // Step 5 - revoke approval
        IERC20(makerOrder.currency).safeApprove(_looksRareExchange, 0);
    }

    function takeOfferForERC20(
        ILooksRareExchange.TakerOrder calldata takerOrder,
        ILooksRareExchange.MakerOrder calldata makerOrder
    ) external {
        // Step 1 - Transfer nft to adapter
        address transferManager = _nftTransfer(
            msg.sender,
            address(this),
            makerOrder.collection,
            makerOrder.tokenId,
            makerOrder.amount
        );

        _nftApprove(transferManager, true, makerOrder.collection);

        // Step 3 - trade
        try
            ILooksRareExchange(_looksRareExchange).matchBidWithTakerAsk(
                takerOrder,
                makerOrder
            )
        {
            // Step 4 - Transfer ERC20 to seller
            uint256 finalSellerAmount = takerOrder.price;
            uint256 protocolFeeAmount = _calculateProtocolFee(
                makerOrder.strategy,
                takerOrder.price
            );
            finalSellerAmount -= protocolFeeAmount;
            (, uint256 royaltyFeeAmount) = IRoyaltyFeeManager(
                _royaltyFeeManager
            ).calculateRoyaltyFeeAndGetRecipient(
                    makerOrder.collection,
                    makerOrder.tokenId,
                    takerOrder.price
                );
            finalSellerAmount -= royaltyFeeAmount;
            IERC20(makerOrder.currency).safeTransfer(
                msg.sender,
                finalSellerAmount
            );
        } catch {
            revert("Seller takes offer failed.");
        }
        // Step 5 - revoke approval
        _nftApprove(transferManager, false, makerOrder.collection);
    }

    function _nftTransfer(
        address from,
        address to,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) internal returns (address transferManager) {
        transferManager = ITransferSelectorNFT(_transferSelectorNft)
            .checkTransferManagerForToken(collection);
        // If no transfer manager found, it returns address(0)
        require(
            transferManager != address(0),
            "Transfer: No NFT transfer manager available"
        );

        // prettier-ignore
        if (transferManager == _ERC721Manager || transferManager == _ERC721ManagerNonCompliant) {
            IERC721(collection).transferFrom(from, to, tokenId);
        } else if (transferManager == _ERC1155Manager) {
            // prettier-ignore
            IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "0x");
        } else {
            revert("Unsupported interface");
        }
    }

    function _nftApprove(
        address operator,
        bool approved,
        address collection
    ) internal {
        if (IERC165(collection).supportsInterface(IID_IERC721)) {
            IERC721(collection).setApprovalForAll(operator, approved);
        } else if (IERC165(collection).supportsInterface(IID_IERC1155)) {
            IERC1155(collection).setApprovalForAll(operator, approved);
        }
    }

    function _calculateProtocolFee(address executionStrategy, uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 protocolFee = IExecutionStrategy(executionStrategy)
            .viewProtocolFee();

        return (protocolFee * amount) / 10000;
    }
}
