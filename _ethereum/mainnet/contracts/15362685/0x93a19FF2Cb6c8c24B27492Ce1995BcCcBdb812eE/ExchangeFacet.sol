// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./IERC721A.sol";
import "./IExchange.sol";
import "./BaseContract.sol";
import "./Attributes.sol";


contract ExchangeFacet is BaseContract, IExchange {



    function tokenOrderLength(uint256 id) external override view returns (uint256) {
        return getState().orderHashByToken[id].length;
    }

    function sellerOrderLength(address seller) external override view returns (uint256) {
        return getState().orderHashBySeller[seller].length;
    }

    function getOrderHashByToken(uint256 tokenId, uint256 index) external override view returns (bytes32) {
        return getState().orderHashByToken[tokenId][index];
    }

    function getOrderHashBySeller(address seller, uint256 index) external override view returns (bytes32) {
        return getState().orderHashBySeller[seller][index];
    }

    function getOrderInfo(bytes32 orderHash) external override view returns (ExchangeOrder memory) {
        return getState().orderInfo[orderHash];
    }

    function getCurrentPrice(bytes32 order) external override view returns (uint256) {
        ExchangeOrder storage o = getState().orderInfo[order];
        return o.price;
    }

    function sell(uint256 id, uint256 price) external override {
        _makeOrder(id, price);
    }

    function batchSell(uint256[] memory tokenIds, uint256[] memory prices) external override {
        require(tokenIds.length == prices.length, "ExchangeFacet: batch sell parameter asymmetry");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _makeOrder(tokenIds[i], prices[i]);
        }
    }

    function _makeOrder(uint256 _tokenId, uint256 _price) internal {
        bytes32 hash = _hash(_tokenId, msg.sender);
        getState().orderInfo[hash] = ExchangeOrder(msg.sender, _tokenId, _price, block.timestamp, 0, address(0), false);
        getState().orderHashByToken[_tokenId].push(hash);
        getState().orderHashBySeller[msg.sender].push(hash);

        address owner = IERC721A(address(this)).ownerOf(_tokenId);
        require(owner == msg.sender, "ExchangeFacet: batch sell parameter asymmetry");
        getState().operatorApprovals[owner][address(this)] = true;
        //check if seller has a right to transfer the NFT token. safeTransferFrom.
        // The caller here is the caller of the transaction contract,
        // not the caller of the NFT contract transfer function, and the caller of the transfer function is the transaction contract
        IERC721A(address(this)).safeTransferFrom(msg.sender, address(this), _tokenId);

        getState().operatorApprovals[owner][address(this)] = false;

        emit MakeOrder(_tokenId, hash, msg.sender);
    }

    function _hash(uint256 _id, address _seller) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, address(this), _id, _seller));
    }

    function buyItNow(bytes32 orderHash) external payable override {
        ExchangeOrder storage o = getState().orderInfo[orderHash];
        require(o.seller != msg.sender, "ExchangeFacet: Can not bid to your order");
        require(o.isSold == false, "ExchangeFacet: Already sold");

        uint256 currentPrice = o.price;
        require(msg.value >= currentPrice, "ExchangeFacet: price error");

        o.isSold = true; //reentrancy proof
        o.buy = msg.sender;
        o.endBlockTimestamp = block.timestamp;

        (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(address(this)).royaltyInfo(o.tokenId, currentPrice);

        payable(o.seller).transfer(currentPrice - royaltyAmount);
        payable(royaltyReceiver).transfer(royaltyAmount);
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

        IERC721A(address(this)).safeTransferFrom(address(this), msg.sender, o.tokenId);

        emit Claim(o.tokenId, orderHash, o.seller, msg.sender, currentPrice);
    }

    function cancelOrder(bytes32 orderHash) external override {
        ExchangeOrder storage o = getState().orderInfo[orderHash];
        require(o.seller == msg.sender, "ExchangeFacet: Access denied");
        require(o.isSold == false, "ExchangeFacet: Already sold");

        uint256 tokenId = o.tokenId;
        o.endBlockTimestamp = 0; //0 endBlockTimestamp means the order was canceled.
        o.isSold == true;

        IERC721A(address(this)).safeTransferFrom(address(this), msg.sender, tokenId);
        emit CancelOrder(tokenId, orderHash, msg.sender);
    }
}
