// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./INFTPoolInterface.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./TransferHelper.sol";

contract USwapDgNFT is ERC721Holder, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    address public immutable tokenAddress;
    address public immutable nftAddress;
    IUniswapV2Router02 private swapRouter;
    INFTPoolInterface private nftPool;

    uint256 private unlocked = 1;

    constructor(address _tokenAddress, address _nftAddress, address _swapRouter, address _nftPool){
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
        swapRouter = IUniswapV2Router02(_swapRouter);
        nftPool = INFTPoolInterface(_nftPool);
    }

    modifier lock() {
        require(unlocked == 1, 'SwapNFT: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    event ETH2NFT(
        address indexed receiver,
        uint256[] nftIds
    );

    event NFT2ETH(
        address indexed receiver,
        uint256[] nftIds
    );

    receive() external payable {
        assert(msg.sender == swapRouter.WETH()); // only accept ETH via fallback from the WETH contract
    }

    function swapETH2NFT(
        uint256 amount,
        uint256[] memory nfts,
        uint256 deadline) lock external virtual payable returns (uint256[] memory) {
        IWETH(swapRouter.WETH()).deposit{value: msg.value}();
        TransferHelper.safeApprove(swapRouter.WETH(), address(swapRouter), msg.value);
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = tokenAddress;
        uint256[] memory amounts = swapRouter.swapTokensForExactTokens(amount, msg.value, path, address(this), deadline);

        TransferHelper.safeApprove(tokenAddress, address(nftPool), amount);
        uint256[] memory ids = nftPool.token2Nft(amount, nfts);

        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < ids.length; i++) {
            nft.safeTransferFrom(address(this), msg.sender, ids[i]);
        }

        if (msg.value > amounts[0]) {
            uint256 ethAmount = msg.value - amounts[0];
            IWETH(swapRouter.WETH()).withdraw(ethAmount);
            TransferHelper.safeTransferETH(msg.sender, ethAmount);
            TransferHelper.safeApprove(swapRouter.WETH(), address(swapRouter), 0);
        }
        emit ETH2NFT(msg.sender, ids);
        return ids;
    }

    function swapNft2ETH(uint256 amountOutMin, uint256[] memory nfts, uint256 deadline) lock external virtual payable {
        require(nfts.length > 0 && nfts.length <= 50, '0 < nfts <= 50');
        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < nfts.length; i++) {
            nft.safeTransferFrom(msg.sender, address(this), nfts[i]);
        }
        nft.setApprovalForAll(address(nftPool), true);
        uint256 amount = nftPool.nft2Token(nfts);
        nft.setApprovalForAll(address(nftPool), false);

        TransferHelper.safeApprove(tokenAddress, address(swapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = swapRouter.WETH();
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount,
            amountOutMin, path, msg.sender, deadline);

        emit NFT2ETH(msg.sender, nfts);
    }
}
