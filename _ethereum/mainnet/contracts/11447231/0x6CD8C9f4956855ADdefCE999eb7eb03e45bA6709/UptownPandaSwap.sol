// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./UptownPandaSwapToken.sol";

contract UptownPandaSwap is Ownable {
    using SafeMath for uint256;

    UptownPandaSwapToken private swapToken;
    bool private isEthSent;
    uint256 public totalEthSupply;
    uint256 public totalUpsSupply;
    uint256 public ethsPerUp;

    constructor(address swapTokenAddress) public {
        swapToken = UptownPandaSwapToken(swapTokenAddress);
        isEthSent = false;
    }

    modifier ethNotSent() {
        require(!isEthSent, "Eth was already sent!");
        _;
    }

    modifier ethSent() {
        require(isEthSent, "Eth has not been sent yet!");
        _;
    }

    modifier approvedOnSwapToken() {
        require(
            _msgSender() != address(this) && swapToken.isApprovedForAll(_msgSender(), address(this)),
            "Swap contract not approved to handle your swap tokens."
        );
        _;
    }

    receive() external payable onlyOwner ethNotSent {
        isEthSent = true;
        totalEthSupply = msg.value;
        totalUpsSupply = getTotalUpsSupply();
    }

    function withdraw() external onlyOwner ethSent {
        isEthSent = false;
        (bool success, ) = _msgSender().call{ value: address(this).balance }("");
        require(success, "Failed to withdraw ETHs");
    }

    function swap() external approvedOnSwapToken ethSent {
        if (totalUpsSupply == 0 || address(this).balance == 0) {
            return;
        }

        uint256 senderSwapTokensCount = swapToken.balanceOf(_msgSender());
        if (senderSwapTokensCount == 0) {
            return;
        }

        uint256 senderUpsBalance = 0;
        uint256[] memory tokenIdsToBurn = new uint256[](senderSwapTokensCount);
        for (uint256 i = 0; i < senderSwapTokensCount; i++) {
            uint256 tokenId = swapToken.tokenOfOwnerByIndex(_msgSender(), i);
            senderUpsBalance = senderUpsBalance.add(swapToken.swapTokens(tokenId));
            tokenIdsToBurn[i] = tokenId;
        }
        for (uint256 i = 0; i < tokenIdsToBurn.length; i++) {
            swapToken.burn(tokenIdsToBurn[i]);
        }
        if (senderUpsBalance == 0) {
            return;
        }

        uint256 ethToWithdraw =
            Math.min(senderUpsBalance.mul(totalEthSupply).div(totalUpsSupply), address(this).balance);
        (bool success, ) = _msgSender().call{ value: ethToWithdraw }("");
        require(success, "Failed to withdraw ETHs");
    }

    function getTotalUpsSupply() private view returns (uint256) {
        uint256 totalSwapTokensSupply = swapToken.totalSupply();
        uint256 result = 0;
        for (uint256 i = 0; i < totalSwapTokensSupply; i++) {
            result = result.add(swapToken.swapTokens(swapToken.tokenByIndex(i)));
        }
        return result;
    }
}
