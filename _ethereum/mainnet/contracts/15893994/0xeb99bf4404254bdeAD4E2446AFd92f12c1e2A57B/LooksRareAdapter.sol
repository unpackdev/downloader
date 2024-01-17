// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./SecurityBaseFor8.sol";
import "./ILooksRareAdapter.sol";
import "./IApproveProxy.sol";

contract LooksRareAdapter is
    ILooksRareAdapter,
    ReentrancyGuard,
    ERC1155Holder,
    ERC721Holder,
    SecurityBaseFor8
{
    using SafeERC20 for IERC20;

    address public _looksRareExchange;
    address public _transferSelectorNft;
    address public _royaltyFeeManager;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    address public _aggregator;
    bool private _initialized;

    //OKX union approve address
    address public approveProxyAddr;

    event SetNewAggregator(address newAggregator);

    function init(
        address looksRareExchange,
        address transferSelectorNft,
        address royaltyFeeManager,
        address newOwner
    ) external {
        require(!_initialized, "Already initialized");
        _initialized = true;
        // ownable upgrade
        _transferOwnership(newOwner);

        _looksRareExchange = looksRareExchange;
        _transferSelectorNft = transferSelectorNft;
        _royaltyFeeManager = royaltyFeeManager;
    }

    function setConfig(
        address looksRareExchange,
        address transferSelectorNft,
        address royaltyFeeManager
    ) external onlyOwner {
        _looksRareExchange = looksRareExchange;
        _transferSelectorNft = transferSelectorNft;
        _royaltyFeeManager = royaltyFeeManager;
    }

    modifier onlyAggregator() {
        require(msg.sender == _aggregator, "the caller is not aggregator.");
        _;
    }

    function setAggregator(address aggregator) external onlyOwner {
        _aggregator = aggregator;
        emit SetNewAggregator(aggregator);
    }

    function buyAssetsForEth(
        ILooksRareExchange.TakerOrder[] calldata takerOrders,
        ILooksRareExchange.MakerOrder[] calldata makerOrders,
        address recipient
    ) external payable nonReentrant onlyAggregator {
        for (uint256 i = 0; i < takerOrders.length; i++) {
            _buyAssetForEth(takerOrders[i], makerOrders[i], recipient);
        }
    }

    function _buyAssetForEth(
        ILooksRareExchange.TakerOrder calldata takerOrder,
        ILooksRareExchange.MakerOrder calldata makerOrder,
        address recipient
    ) internal {
        try
            ILooksRareExchange(_looksRareExchange)
                .matchAskWithTakerBidUsingETHAndWETH{value: takerOrder.price}(
                takerOrder,
                makerOrder
            )
        {
            _nftTransfer(
                address(this),
                recipient,
                makerOrder.collection,
                makerOrder.tokenId,
                makerOrder.amount
            );
        } catch {
            revert("Buyer takes order failed.");
        }
    }

    function buyAssetForERC20(
        ILooksRareExchange.TakerOrder[] calldata takerOrders,
        ILooksRareExchange.MakerOrder[] calldata makerOrders,
        address buyer
    ) external nonReentrant onlyAggregator {
        for (uint256 i = 0; i < takerOrders.length; i++) {
            _buyAssetForERC20(takerOrders[i], makerOrders[i], buyer);
        }
    }

    function _buyAssetForERC20(
        ILooksRareExchange.TakerOrder calldata takerOrder,
        ILooksRareExchange.MakerOrder calldata makerOrder,
        address buyer
    ) internal {
        // Step 1 - Transfer ERC20 to adapter
        address approveAddr = IApproveProxy(approveProxyAddr).tokenApprove();
        //new proxy address has approved
        uint256 unionSpendAmount = IERC20(makerOrder.currency).allowance(buyer, approveAddr);
        uint256 adapterSpendAmount = IERC20(makerOrder.currency).allowance(buyer, address(this));

        //compatibility old version
        if(adapterSpendAmount>=takerOrder.price){

            IERC20(makerOrder.currency).safeTransferFrom(
                buyer,
                address(this),
                takerOrder.price
            );

        }else if(unionSpendAmount>=takerOrder.price){
            //use union approve proxy
            IApproveProxy(approveProxyAddr).claimTokens(
                makerOrder.currency,
                    buyer,
                address(this),
                    takerOrder.price
            );
        }else{
            revert("approve address error!");
        }

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
                buyer,
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
        ILooksRareExchange.TakerOrder[] calldata takerOrders,
        ILooksRareExchange.MakerOrder[] calldata makerOrders,
        address seller
    ) external nonReentrant onlyAggregator {
        for (uint256 i = 0; i < takerOrders.length; i++) {
            _takeOfferForERC20(takerOrders[i], makerOrders[i], seller);
        }
    }

    function _takeOfferForERC20(
        ILooksRareExchange.TakerOrder calldata takerOrder,
        ILooksRareExchange.MakerOrder calldata makerOrder,
        address seller
    ) internal {
        // Step 1 - Transfer nft to adapter
        _nftTransfer(
            seller,
            address(this),
            makerOrder.collection,
            makerOrder.tokenId,
            makerOrder.amount
        );

        // Step 2 - Adapter approve nft to transferManager
        address transferManager = ITransferSelectorNFT(_transferSelectorNft)
            .checkTransferManagerForToken(makerOrder.collection);
        // If no transfer manager found, it returns address(0)
        require(
            transferManager != address(0),
            "Transfer: No NFT transfer manager available"
        );
        _nftApprove(
            transferManager,
            true,
            makerOrder.collection,
            makerOrder.tokenId
        );

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
            IERC20(makerOrder.currency).safeTransfer(seller, finalSellerAmount);
        } catch {
            revert("Seller takes offer failed.");
        }
        // Step 5 - revoke approval
        _nftApprove(
            transferManager,
            false,
            makerOrder.collection,
            makerOrder.tokenId
        );
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

    function _nftTransfer(
        address from,
        address to,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (IERC165(collection).supportsInterface(IID_IERC721)) {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        } else if (IERC165(collection).supportsInterface(IID_IERC1155)) {
            // prettier-ignore
            IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "0x");
        } else {
            revert("Unsupported interface");
        }
    }

    function _nftApprove(
        address operator,
        bool approved,
        address collection,
        uint256 tokenId
    ) internal {
        if (IERC165(collection).supportsInterface(IID_IERC721)) {
            if (approved) {
                IERC721(collection).approve(operator, tokenId);
            } else {
                IERC721(collection).setApprovalForAll(operator, false);
            }
        }
        if (IERC165(collection).supportsInterface(IID_IERC1155)) {
            // prettier-ignore
            IERC1155(collection).setApprovalForAll(operator, approved);
        }
    }

    function withdrawNFT(
        address collection,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _nftTransfer(address(this), to, collection, tokenId, amount);
    }

    function setupApproveProxy(address _approveProxyAddr) external onlyOwner {
        approveProxyAddr = _approveProxyAddr;
    }
}
