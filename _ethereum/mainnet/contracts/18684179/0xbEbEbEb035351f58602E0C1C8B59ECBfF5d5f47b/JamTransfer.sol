// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./JamOrder.sol";
import "./BMath.sol";
import "./IERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";

/// @title JamTransfer
/// @notice Functions for transferring tokens from SettlementContract
abstract contract JamTransfer {

    event NativeTransfer(address indexed receiver, uint256 amount);
    using SafeERC20 for IERC20;

    /// @dev Transfer tokens from this contract to receiver
    /// @param tokens tokens' addresses
    /// @param amounts tokens' amounts
    /// @param nftIds NFTs' ids
    /// @param tokenTransferTypes command sequence of transfer types
    /// @param receiver address
    function transferTokensFromContract(
        address[] calldata tokens,
        uint256[] memory amounts,
        uint256[] calldata nftIds,
        bytes calldata tokenTransferTypes,
        address receiver,
        uint16 fillPercent,
        bool transferExactAmounts
    ) internal {
        uint nftInd;
        for (uint i; i < tokens.length; ++i) {
            if (tokenTransferTypes[i] == Commands.SIMPLE_TRANSFER) {
                uint tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
                uint partialFillAmount = BMath.getPercentage(amounts[i], fillPercent);
                require(tokenBalance >= partialFillAmount, "INVALID_OUTPUT_TOKEN_BALANCE");
                IERC20(tokens[i]).safeTransfer(receiver, transferExactAmounts ? partialFillAmount : tokenBalance);
            } else if (tokenTransferTypes[i] == Commands.NATIVE_TRANSFER){
                require(tokens[i] == JamOrder.NATIVE_TOKEN, "INVALID_NATIVE_TOKEN");
                uint tokenBalance = address(this).balance;
                uint partialFillAmount = BMath.getPercentage(amounts[i], fillPercent);
                require(tokenBalance >= partialFillAmount, "INVALID_OUTPUT_NATIVE_BALANCE");
                (bool sent, ) = payable(receiver).call{value: transferExactAmounts ?  partialFillAmount : tokenBalance}("");
                require(sent, "FAILED_TO_SEND_ETH");
                emit NativeTransfer(receiver, transferExactAmounts ? partialFillAmount : tokenBalance);
            } else if (tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER) {
                uint tokenBalance = IERC721(tokens[i]).balanceOf(address(this));
                require(amounts[i] == 1 && tokenBalance >= 1, "INVALID_OUTPUT_ERC721_AMOUNT");
                IERC721(tokens[i]).safeTransferFrom(address(this), receiver, nftIds[nftInd++]);
            } else if (tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER) {
                uint tokenBalance = IERC1155(tokens[i]).balanceOf(address(this), nftIds[nftInd]);
                require(tokenBalance >= amounts[i], "INVALID_OUTPUT_ERC1155_BALANCE");
                IERC1155(tokens[i]).safeTransferFrom(
                    address(this), receiver, nftIds[nftInd++], transferExactAmounts ?  amounts[i] : tokenBalance, ""
                );
            } else {
                revert("INVALID_TRANSFER_TYPE");
            }
        }
        require(nftInd == nftIds.length, "INVALID_BUY_NFT_IDS_LENGTH");
    }

    /// @dev Transfer native tokens to receiver from this contract
    /// @param receiver address
    /// @param amount amount of native tokens
    function transferNativeFromContract(address receiver, uint256 amount) public {
        (bool sent, ) = payable(receiver).call{value: amount}("");
        require(sent, "FAILED_TO_SEND_ETH");
    }

    /// @dev Calculate new amounts of tokens if solver transferred excess to contract during settleBatch
    /// @param curInd index of current order
    /// @param orders array of orders
    /// @param fillPercents[] fill percentage
    /// @return array of new amounts
    function calculateNewAmounts(
        uint256 curInd,
        JamOrder.Data[] calldata orders,
        uint16[] memory fillPercents
    ) internal returns (uint256[] memory) {
        JamOrder.Data calldata curOrder = orders[curInd];
        uint256[] memory newAmounts = new uint256[](curOrder.buyTokens.length);
        uint16 curFillPercent = fillPercents.length == 0 ? BMath.HUNDRED_PERCENT : fillPercents[curInd];
        for (uint i; i < curOrder.buyTokens.length; ++i) {
            if (curOrder.buyTokenTransfers[i] == Commands.SIMPLE_TRANSFER || curOrder.buyTokenTransfers[i] == Commands.NATIVE_TRANSFER) {
                uint256 fullAmount;
                for (uint j = curInd; j < orders.length; ++j) {
                    for (uint k; k < orders[j].buyTokens.length; ++k) {
                        if (orders[j].buyTokens[k] == curOrder.buyTokens[i]) {
                            fullAmount += orders[j].buyAmounts[k];
                            require(fillPercents.length == 0 || curFillPercent == fillPercents[j], "DIFF_FILL_PERCENT_FOR_SAME_TOKEN");
                        }
                    }
                }
                uint256 tokenBalance = curOrder.buyTokenTransfers[i] == Commands.NATIVE_TRANSFER ?
                    address(this).balance : IERC20(curOrder.buyTokens[i]).balanceOf(address(this));
                // if at least two takers buy same token, we need to divide the whole tokenBalance among them.
                // for edge case with newAmounts[i] overflow, solver should submit tx with transferExactAmounts=true
                newAmounts[i] = BMath.getInvertedPercentage(tokenBalance * curOrder.buyAmounts[i] / fullAmount, curFillPercent);
                if (newAmounts[i] < curOrder.buyAmounts[i]) {
                    newAmounts[i] = curOrder.buyAmounts[i];
                }
            } else {
                newAmounts[i] = curOrder.buyAmounts[i];
            }
        }
        return newAmounts;
    }


    /// @dev Check if there are duplicate tokens
    /// @param tokens tokens' addresses
    /// @param nftIds NFTs' ids
    /// @param tokenTransferTypes command sequence of transfer types
    /// @return true if there are duplicate tokens
    function hasDuplicate(
        address[] calldata tokens, uint256[] calldata nftIds, bytes calldata tokenTransferTypes
    ) internal pure returns (bool) {
        if (tokens.length == 0) {
            return false;
        }
        uint curNftInd;
        for (uint i; i < tokens.length - 1; ++i) {
            uint tmpNftInd = curNftInd;
            for (uint j = i + 1; j < tokens.length; ++j) {
                if (tokenTransferTypes[j] == Commands.NFT_ERC721_TRANSFER || tokenTransferTypes[j] == Commands.NFT_ERC1155_TRANSFER){
                    ++tmpNftInd;
                }
                if (tokens[i] == tokens[j]) {
                    if (tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER ||
                        tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER){
                        if (nftIds[curNftInd] == nftIds[tmpNftInd]){
                            return true;
                        }
                    } else {
                        return true;
                    }
                }
            }
            if (tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER || tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER){
                ++curNftInd;
            }
        }
        return false;
    }
}
