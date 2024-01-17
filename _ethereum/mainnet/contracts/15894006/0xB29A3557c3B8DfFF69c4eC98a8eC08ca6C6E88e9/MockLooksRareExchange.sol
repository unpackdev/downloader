// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ILooksRareAdapter.sol";
import "./ITransferManagerNFT.sol";

import "./console.sol";

contract MockLooksRareExchange is ILooksRareExchange, IERC1155Receiver {
    using SafeERC20 for IERC20;

    address private test20;
    address private test721;
    address private test1155;
    address private _royaltyFeeManager;
    ITransferSelectorNFT public transferSelectorNFT;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    constructor(
        address erc20,
        address erc721,
        address erc1155,
        address royaltyFeeManager
    ) {
        test20 = erc20;
        test721 = erc721;
        test1155 = erc1155;
        _royaltyFeeManager = royaltyFeeManager;
    }

    function setTransferSelectorNFT(address _transferSelectorNFT) external {
        transferSelectorNFT = ITransferSelectorNFT(_transferSelectorNFT);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {
        return interfaceId == type(ILooksRareExchange).interfaceId;
    }

    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable {
        // check msg.value == price
        require(
            (makerAsk.isOrderAsk) && (!takerBid.isOrderAsk),
            "Order: Wrong sides"
        );
        require(
            msg.sender == takerBid.taker,
            "Order: Taker must be the sender"
        );
        require(
            msg.value == takerBid.price,
            "MockLooksRareExchange::matchAskWithTakerBidUsingETHAndWETH: Insufficient eth "
        );
        // We don't need to care about buyers
        // transfer nft to adapter
        _transferNFT(
            makerAsk.collection,
            address(this),
            takerBid.taker,
            makerAsk.tokenId,
            makerAsk.amount
        );
    }

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external {
        require(
            (makerAsk.isOrderAsk) && (!takerBid.isOrderAsk),
            "Order: Wrong sides"
        );
        require(
            msg.sender == takerBid.taker,
            "Order: Taker must be the sender"
        );
        // transfer ERC20
        IERC20(makerAsk.currency).safeTransferFrom(
            msg.sender,
            address(this),
            takerBid.price
        );
        // transfer nft
        _transferNFT(
            makerAsk.collection,
            address(this),
            takerBid.taker,
            makerAsk.tokenId,
            makerAsk.amount
        );
    }

    function matchBidWithTakerAsk(
        TakerOrder calldata takerAsk,
        MakerOrder calldata makerBid
    ) external {
        require(
            (!makerBid.isOrderAsk) && (takerAsk.isOrderAsk),
            "Order: Wrong sides"
        );
        require(
            msg.sender == takerAsk.taker,
            "Order: Taker must be the sender"
        );
        // transfer nft from adapter
        _transferNFTForTakesOffer(
            makerBid.collection,
            msg.sender,
            address(this),
            makerBid.tokenId,
            makerBid.amount
        );
        // transfer ERC20 to adapter
        uint256 finalSellerAmount = takerAsk.price;
        uint256 protocolFeeAmount = _calculateProtocolFee(
            makerBid.strategy,
            takerAsk.price
        );
        finalSellerAmount -= protocolFeeAmount;
        (, uint256 royaltyFeeAmount) = IRoyaltyFeeManager(_royaltyFeeManager)
            .calculateRoyaltyFeeAndGetRecipient(
                makerBid.collection,
                makerBid.tokenId,
                takerAsk.price
            );
        finalSellerAmount -= royaltyFeeAmount;
        IERC20(makerBid.currency).safeTransfer(
            takerAsk.taker,
            finalSellerAmount
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

    function _transferNFTForTakesOffer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        address transferManager = transferSelectorNFT
            .checkTransferManagerForToken(tokenAddress);

        // If no transfer manager found, it returns address(0)
        require(
            transferManager != address(0),
            "Transfer: No NFT transfer manager available"
        );
        ITransferManagerNFT(transferManager).transferNonFungibleToken(
            tokenAddress,
            from,
            to,
            tokenId,
            amount
        );
    }

    function _transferNFT(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (IERC165(tokenAddress).supportsInterface(IID_IERC721)) {
            IERC721(tokenAddress).safeTransferFrom(from, to, tokenId, "");
        } else if (IERC165(tokenAddress).supportsInterface(IID_IERC1155)) {
            IERC1155(tokenAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ""
            );
        } else {
            revert("Unsupported interface");
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
