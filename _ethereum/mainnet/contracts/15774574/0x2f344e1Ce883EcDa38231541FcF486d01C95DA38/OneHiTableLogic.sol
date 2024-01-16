// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.9;

import "./IOneHiTableLogic.sol";
import "./IOneHiController.sol";
import "./IFractonSwap.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./ERC1155Holder.sol";
import "./Initializable.sol";


contract OneHiTableLogic is IOneHiTableLogic, ERC1155Holder, Initializable {

    address public controller;

    function initialize (address _controller, address fftAddr) public initializer {
        controller = _controller;
        IERC20(fftAddr).approve(_controller, type(uint256).max);
    }

    modifier onlyController() {
        require(msg.sender == controller, "only controller");
        _;
    }

    function swapNFT(address fractonSwapAddr, address fftAddr, address miniNFTAddr, uint256 miniNFTAmount,
        address nftAddr) external onlyController {

        require(IERC20(fftAddr).approve(fractonSwapAddr, type(uint256).max),"_swapMiniNFT: approve to swap is failed");
        require(IFractonSwap(fractonSwapAddr).swapFFTtoMiniNFT(miniNFTAddr, miniNFTAmount), "OneHiTable: swap miniNFT is failed");

        IERC1155(miniNFTAddr).setApprovalForAll(fractonSwapAddr, true);
        IFractonSwap(fractonSwapAddr).swapMiniNFTtoNFT(nftAddr);
    }

    function claimTreasure(address player, address nftAddr, uint256 tokenId) external onlyController returns(bool) {
        IERC721(nftAddr).transferFrom(address(this), player, tokenId);
        return true;
    }

}