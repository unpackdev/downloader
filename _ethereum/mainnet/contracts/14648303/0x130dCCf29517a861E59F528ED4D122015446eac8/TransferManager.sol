//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
pragma abicoder v2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ITransferManager.sol";
import "./BpLibrary.sol";
import "./LibOrder.sol";
import "./TransferExecutor.sol";
import "./IERC1155LazyMint.sol";

abstract contract TransferManager is Ownable, ITransferManager {
    using BpLibrary for uint256;

    // Fee recipient
    address payable public feeReceiver;

    function setFeeReceiver(address payable newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
    }

    function doTransfers(
        LibOrder.Order calldata buy,
        LibOrder.Order calldata sell
    ) internal override {
        // Decode data
        (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi
            .decode(sell.data, (address, LibERC1155LazyMint.Mint1155Data));

        // Transfer Royalties to creator.
        uint256 royalty = transferRoyalty(
            sell.paymentToken,
            buy.maker,
            data.royalty.account,
            sell.price,
            data.royalty.value
        );

        // Transfer fee to feeReceiver.
        uint256 fee = transferFee(
            sell.paymentToken,
            buy.maker,
            sell.feeRecipient,
            sell.price,
            sell.makerFee
        );

        // Receivement
        uint256 receivement = sell.price - royalty - fee;

        // Transfer to seller
        transfer(sell.paymentToken, buy.maker, sell.maker, receivement);

        // Allow overshoot for variable-price auctions, refund difference.
        if (sell.paymentToken == address(0)) {
            uint256 diff = msg.value - sell.price;
            if (diff > 0) {
                transfer(address(0), buy.maker, buy.maker, diff);
            }
        }

        // Transfer NFT
        IERC1155LazyMint(token).transferFromOrMint(
            data,
            sell.maker,
            buy.maker,
            1
        );
    }

    function transferRoyalty(
        address token,
        address from,
        address to,
        uint256 price,
        uint256 rate
    ) internal returns (uint256) {
        uint256 fee = BpLibrary.bp(price, rate);

        transfer(token, from, to, fee);

        return fee;
    }

    function transferFee(
        address token,
        address from,
        address to,
        uint256 price,
        uint256 makerFee
    ) internal returns (uint256) {
        if (makerFee == 0) {
            return 0;
        }

        uint256 fee = BpLibrary.bp(price, makerFee);

        transfer(token, from, to, fee);

        return fee;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (amount > 0) {
            IERC20(token).transferFrom(from, to, amount);
        }
    }
}
