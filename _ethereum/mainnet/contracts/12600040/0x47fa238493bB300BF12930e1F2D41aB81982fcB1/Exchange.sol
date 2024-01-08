// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract Exchange is
    AccessControl,
    IERC721Receiver,
    IERC1155Receiver,
    ReentrancyGuard
{
    using SafeMath for uint256;

    struct NftTokenInfo {
        address tokenAddress;
        uint256 id;
        uint256 amount;
    }

    bytes32 public SIGNER_ROLE = keccak256("SIGNER_ROLE");

    event ExchangeMadeErc721(
        address seller,
        address buyer,
        address sellTokenAddress,
        uint256 sellId,
        uint256 sellAmount,
        address buyTokenAddress,
        uint256 buyId,
        uint256 buyAmount,
        address[] feeAddresses,
        uint256[] feeAmounts
    );
    event ExchangeMadeErc1155(
        address seller,
        address buyer,
        address sellTokenAddress,
        uint256 sellId,
        uint256 sellAmount,
        address buyTokenAddress,
        uint256 buyId,
        uint256 buyAmount,
        address[] feeAddresses,
        uint256[] feeAmounts
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _msgSender());
    }

    function makeExchangeERC721(
        bytes32 idOrder,
        address[2] calldata SellerBuyer,
        NftTokenInfo calldata tokenToBuy,
        NftTokenInfo calldata tokenToSell,
        address[] calldata feeAddresses,
    	uint256[] calldata feeAmounts,
        bytes calldata signature
    ) external nonReentrant {
        require(
            tokenToBuy.tokenAddress != address(0) && tokenToBuy.amount == 0,
            "Exchange: Wrong tokenToBuy"
        );
        require(
            tokenToSell.tokenAddress != address(0) && tokenToSell.id == 0,
            "Exchange: Wrong tokenToSell"
        );
        require(
            feeAddresses.length == feeAmounts.length,
            "Exchange: Wrong fees"
        );
        _verifySigner(
            idOrder,
            SellerBuyer,
            tokenToBuy,
            tokenToSell,
            feeAddresses,
            feeAmounts,
            signature
        );

        IERC721(tokenToBuy.tokenAddress).safeTransferFrom(
            SellerBuyer[0],
            SellerBuyer[1],
            tokenToBuy.id
        );

        uint256 tokenToSeller = tokenToSell.amount;
        for (uint256 i = 0; i < feeAddresses.length; i = i.add(1)) {
            tokenToSeller = tokenToSeller.sub(uint256(feeAmounts[i]));
            IERC20(tokenToSell.tokenAddress).transferFrom(
                SellerBuyer[1],
                address(feeAddresses[i]),
                uint256(feeAmounts[i])
            );
        }
        IERC20(tokenToSell.tokenAddress).transferFrom(
            SellerBuyer[1],
            SellerBuyer[0],
            tokenToSeller
        );

        emit ExchangeMadeErc721(
            SellerBuyer[0],
            SellerBuyer[1],
            tokenToBuy.tokenAddress,
            tokenToBuy.id,
            tokenToBuy.amount,
            tokenToSell.tokenAddress,
            tokenToSell.id,
            tokenToSell.amount,
            feeAddresses,
            feeAmounts
        );
    }

    function makeExchangeERC1155(
        bytes32 idOrder,
        address[2] calldata SellerBuyer,
        NftTokenInfo calldata tokenToBuy,
        NftTokenInfo calldata tokenToSell,
        address[] calldata feeAddresses,
    	uint256[] calldata feeAmounts,
        bytes calldata signature
    ) external nonReentrant {
        require(
            tokenToBuy.tokenAddress != address(0),
            "Exchange: Wrong tokenToBuy"
        );
        require(
            tokenToSell.tokenAddress != address(0) && tokenToSell.id == 0,
            "Exchange: Wrong tokenToSell"
        );
        require(
            feeAddresses.length == feeAmounts.length,
            "Exchange: Wrong fees"
        );
        _verifySigner(
            idOrder,
            SellerBuyer,
            tokenToBuy,
            tokenToSell,
            feeAddresses,
            feeAmounts,
            signature
        );

        IERC1155(tokenToBuy.tokenAddress).safeTransferFrom(
            SellerBuyer[0],
            SellerBuyer[1],
            tokenToBuy.id,
            tokenToBuy.amount,
            ""
        );

        uint256 tokenToSeller = tokenToSell.amount;
        for (uint256 i = 0; i < feeAddresses.length; i = i.add(1)) {
            tokenToSeller = tokenToSeller.sub(feeAmounts[i]);
            IERC20(tokenToSell.tokenAddress).transferFrom(
                SellerBuyer[1],
                feeAddresses[i],
                feeAmounts[i]
            );
        }

        IERC20(tokenToSell.tokenAddress).transferFrom(
            SellerBuyer[1],
            SellerBuyer[0],
            tokenToSeller
        );

        emit ExchangeMadeErc1155(
            SellerBuyer[0],
            SellerBuyer[1],
            tokenToBuy.tokenAddress,
            tokenToBuy.id,
            tokenToBuy.amount,
            tokenToSell.tokenAddress,
            tokenToSell.id,
            tokenToSell.amount,
            feeAddresses,
            feeAmounts
        );
    }

    function _verifySigner(
        bytes32 idOrder,
        address[2] calldata SellerBuyer,
        NftTokenInfo calldata tokenToBuy,
        NftTokenInfo calldata tokenToSell,
        address[] calldata feeAddresses,
    	uint256[] calldata feeAmounts,
        bytes calldata signature
    ) private view {
        bytes memory message =
            abi.encodePacked(
                idOrder,
                SellerBuyer[0],
                tokenToBuy.tokenAddress,
                tokenToBuy.id,
                tokenToBuy.amount
            );
        message = abi.encodePacked(
            message,
            tokenToSell.tokenAddress,
            //tokenToSell.id,
            tokenToSell.amount
        );
        message = abi.encodePacked(
            message,
            feeAddresses,
            feeAmounts,
            SellerBuyer[1]
        );
        address messageSigner = ECDSA.recover(keccak256(message), signature);
        require(
            hasRole(SIGNER_ROLE, messageSigner),
            "Exchange: Signer should sign transaction"
        );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
