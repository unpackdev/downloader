//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./LCNFT.sol";

contract LCMarketPlace {
    struct orderDetails {
        uint256 tokenId;
        address buyer;
        address seller;
        uint256 totalPrice;
        uint256 qty;
        uint256 time;
    }
    mapping(address => orderDetails[]) public orderLogs;
    address public contractOwner;

    struct onSaleItem {
        uint256 tokenId;
        address owner;
        bool sold;
        bool onSale;
        uint256 timeOnsale;
        uint256 price;
        uint256 qty;
    }
    mapping(uint256 => onSaleItem) public saleItems;

    address[] public whitelisted;
    uint256 public deployTime;
    LCNFT public nft;

    constructor(address nftCreation) {
        nft = LCNFT(nftCreation);
        contractOwner = msg.sender;
        deployTime = block.timestamp;
    }

    event PutTokenOnSale(
        uint256 tokenId,
        uint256 price,
        uint256 qty,
        address tokenOwner
    );
    event BuyToken(
        uint256 tokenId,
        uint256 qty,
        address buyer,
        uint256 tokenPrice,
        address tokenOwner,
        orderDetails newOrder
    );

    event RemoveTokenFromSale(
        uint256 tokenId,
        address tokenOwner,
        bool isOnSale
    );
    event ChangeSaleTokenStatus(uint256 tokenId, bool isSold);

    modifier checkTokenOwner(uint256 tokenId) {
        require(
            nft.balanceOf(msg.sender, tokenId) != 0,
            "You donot own the token"
        );
        _;
    }
    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "You are not permitted to call this function"
        );
        _;
    }
    modifier tokenNotSoldAlready(uint256 tokenId) {
        require(!saleItems[tokenId].sold, "Token is already sold!");
        _;
    }

    function addWhiteListArray(address[] calldata _addresses)
        external
        onlyOwner
    {
        whitelisted = _addresses;
    }

    function removeTokenFromSale(uint256 tokenId) external returns (bool) {
        require(
            nft.balanceOf(msg.sender, tokenId) != 0,
            "You donot own the token"
        );
        saleItems[tokenId].onSale = false;
        emit RemoveTokenFromSale(tokenId, msg.sender, false);
        //from node side =>nft.setApprovalForAll(address(this),false);
        return true;
    }

    function changeSaleTokenStatus(uint256 tokenId, bool status)
        internal
        tokenNotSoldAlready(tokenId)
        returns (bool)
    {
        require(
            nft.balanceOf(msg.sender, tokenId) != 0,
            "You donot own the token so you cannot change the status"
        );
        saleItems[tokenId].sold = status;
        emit ChangeSaleTokenStatus(tokenId, status);
        return true;
    }

    function putTokenOnSale(
        uint256 tokenId,
        uint256 _qty,
        uint256 value
    ) external checkTokenOwner(tokenId) returns (bool) {
        require(
            nft.balanceOf(msg.sender, tokenId) >= _qty,
            "You have insufficient token qty."
        );
        //node side => nft.setApprovalForAll(msg.sender,true);
        onSaleItem memory newItem = onSaleItem({
            tokenId: tokenId,
            owner: msg.sender,
            sold: false,
            onSale: true,
            timeOnsale: block.timestamp,
            price: value,
            qty: _qty
        });
        saleItems[tokenId] = newItem;
        emit PutTokenOnSale(tokenId, value, _qty, msg.sender);
        return true;
    }

    function buyToken(uint256 tokenId, uint256 _qty)
        external
        payable
        tokenNotSoldAlready(tokenId)
        returns (orderDetails memory)
    {
        if (doesWhitelistPeriodExist()) {
            require(
                doesWhitelistAddrExist(msg.sender),
                "Caller is not whitelisted."
            );
        }

        onSaleItem storage saleItem = saleItems[tokenId];
        // check wether tokens is in buyable list or not!
        require(saleItem.timeOnsale != 0, "Token is not buyable!");

        // onSaleItem storage item = saleItem;
        require(!saleItem.sold, "Token is already sold!");
        require(saleItem.onSale, "Token is not on sale!");
        require(
            nft.isApprovedForAll(saleItem.owner, address(this)),
            "Token is not approved to tranfer!"
        );
        require(
            nft.balanceOf(msg.sender, tokenId) + _qty <= 10,
            "Purchase limit exceeded."
        );

        orderDetails memory newOrder = orderDetails({
            tokenId: tokenId,
            buyer: msg.sender,
            seller: saleItem.owner,
            totalPrice: saleItem.price,
            qty: _qty,
            time: block.timestamp
        });
        orderLogs[msg.sender].push(newOrder);

        require(msg.value >= saleItem.price * _qty, "Insufficient ether value");
        // remove token from saleItems list

        address creator = nft.getCreator(tokenId);
        uint256 royalty = nft.getRoyalty(tokenId, creator);

        uint256 tokenSendToCreator = (msg.value * royalty) / 100;
        uint256 tokenSendToSeller = (msg.value - tokenSendToCreator);

        changeSaleTokenStatus(tokenId, true);
        emit BuyToken(
            tokenId,
            _qty,
            msg.sender,
            saleItem.price,
            saleItem.owner,
            newOrder
        );

        (
            bool isSendToSeller, /*bytes memory data*/

        ) = payable(saleItem.owner).call{value: tokenSendToSeller}("");
        require(isSendToSeller, "Send to seller failed");
        (
            bool isSendToCreator, /*bytes memory data*/

        ) = payable(creator).call{value: tokenSendToCreator}("");
        require(isSendToCreator, "Send to creator failed");

        nft.safeTransferFrom(saleItem.owner, msg.sender, tokenId, _qty, "");

        return newOrder;
    }

    function doesWhitelistAddrExist(address addr) internal view returns (bool) {
        uint256 i;
        uint256 addrLength = whitelisted.length;
        while (i < addrLength) {
            if (addr == whitelisted[i]) return true;
            i += 1;
        }
        return false;
    }

    function doesWhitelistPeriodExist() internal view returns (bool) {
        if (block.timestamp > deployTime + 2 days) return false;
        return true;
    }
}
