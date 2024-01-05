pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./UniswapV2Router02.sol";

interface NFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // (not part of the ERC721 spec, added to the 5D.co NFT.sol contract)
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory, string[] memory);
}

interface Redeem {
    struct Series {
        uint256 id;
        uint256 limit;
        uint256 minted;
        uint256 initialPrice;
        int256 priceChange;
        // Only set in `getCollections`.
        uint256 currentPrice;
        uint256 nextPrice;
    }

    struct CollectionFlat {
        uint256 id;
        string title;
        string uriBase;
        uint256 priceChangeTime;
        uint256 initialTimestamp;
        address paymentToken;
        Series[] series;
    }

    function currentPrice(uint256 collectionId, uint256 seriesId)
        external
        view
        returns (uint256);

    function redeem(
        uint256 collectionId,
        uint256 seriesId,
        uint256 amount
    ) external payable;

    function nft() external returns (NFT);

    function getCollections() external view returns (CollectionFlat[] memory);
}

contract SwapAndRedeem is UniswapV2Router02 {
    using SafeMath for uint256;

    Redeem public redeem;
    NFT public nft;

    constructor(
        Redeem _redeem,
        address _factory,
        address _WETH
    ) public UniswapV2Router02(_factory, _WETH) {
        redeem = _redeem;
        nft = redeem.nft();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function forwardNFTsToMsgSender() internal {
        (uint256[] memory tokenIDs, ) = nft.tokensOfOwner(address(this));
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            nft.safeTransferFrom(address(this), msg.sender, tokenIDs[i]);
        }
    }

    function swapAndRedeem(
        // Redeem parameters
        uint256 collectionId,
        uint256 seriesId,
        uint256 amount,
        // Uniswap parameters
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) public payable {
        uint256 price = redeem.currentPrice(collectionId, seriesId);
        uint256 cost = price * amount;

        UniswapV2Router02.swapTokensForExactTokens(
            cost,
            amountInMax,
            path,
            address(this),
            deadline
        );

        IERC20 token = IERC20(path[path.length - 1]);
        token.approve(address(redeem), cost);
        redeem.redeem(collectionId, seriesId, amount);

        forwardNFTsToMsgSender();
    }

    function swapToEthAndRedeem(
        // Redeem parameters
        uint256 collectionId,
        uint256 seriesId,
        uint256 amount,
        // Uniswap parameters
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) public payable {
        uint256 price = redeem.currentPrice(collectionId, seriesId);
        uint256 cost = price * amount;

        UniswapV2Router02.swapTokensForExactETH(
            cost,
            amountInMax,
            path,
            address(this),
            deadline
        );

        redeem.redeem.value(cost)(collectionId, seriesId, amount);

        forwardNFTsToMsgSender();
    }

    function swapFromEthAndRedeem(
        // Redeem parameters
        uint256 collectionId,
        uint256 seriesId,
        uint256 amount,
        // Uniswap parameters
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) public payable {
        uint256 price = redeem.currentPrice(collectionId, seriesId);
        uint256 cost = price * amount;

        UniswapV2Router02.swapETHForExactTokens(
            cost,
            path,
            address(this),
            deadline
        );

        IERC20 token = IERC20(path[path.length - 1]);
        token.approve(address(redeem), cost);
        redeem.redeem(collectionId, seriesId, amount);

        forwardNFTsToMsgSender();
    }

    function wrapAndRedeem(
        // Redeem parameters
        uint256 collectionId,
        uint256 seriesId,
        uint256 amount
    ) public payable {
        uint256 price = redeem.currentPrice(collectionId, seriesId);
        uint256 cost = price * amount;

        IWETH(WETH).deposit{value: cost}();
        if (msg.value > cost) {
            // Return change
            payable(msg.sender).transfer(msg.value.sub(cost));
        }

        IERC20 token = IERC20(WETH);
        token.approve(address(redeem), cost);
        redeem.redeem(collectionId, seriesId, amount);

        forwardNFTsToMsgSender();
    }

    function unwrapAndRedeem(
        // Redeem parameters
        uint256 collectionId,
        uint256 seriesId,
        uint256 amount
    ) public payable {
        uint256 price = redeem.currentPrice(collectionId, seriesId);
        uint256 cost = price * amount;

        IERC20(WETH).transferFrom(msg.sender, address(this), cost);
        IWETH(WETH).withdraw(cost);

        redeem.redeem{value: cost}(collectionId, seriesId, amount);

        forwardNFTsToMsgSender();
    }
}
