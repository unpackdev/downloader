// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./IERC1155.sol";

contract NftReseller is Ownable {
    struct Listing {
        address payable seller;
        address tokenContract;
        uint256 tokenId;
        bool active;
        uint256 price;
        uint256 balance;
    }

    struct BuyRestriction {
        address tokenContract;
        uint256 tokenId;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => BuyRestriction) public restrictions;

    uint256 currentListingId = 0;

    function createListing(address payable _seller, address _tokenContract, uint256 _tokenId, uint256 _price) public {
        IERC1155 token = IERC1155(_tokenContract);
        require(token.balanceOf(_seller, _tokenId) > 0, "seller must own given token");
        require(token.isApprovedForAll(_seller, address(this)), "contract must be approved for given token");

        listings[currentListingId] = Listing(
            _seller,
            _tokenContract,
            _tokenId,
            true,
            _price,
            0
        );

        currentListingId = currentListingId + 1;
    }

    function setListingRestriction(uint256 _listingId, address _tokenContract, uint256 _tokenId) public {
        require(msg.sender == listings[_listingId].seller, "must be seller");

        restrictions[_listingId] = BuyRestriction(
            _tokenContract, _tokenId
        );
    }

    function buy(uint256 _listingId, uint256 _amount) public payable {
        require(_amount > 0, "amount must be above zero");
        if(restrictions[_listingId].tokenContract != address(0)) {
            require(IERC1155(
                restrictions[_listingId].tokenContract).balanceOf(msg.sender, restrictions[_listingId].tokenId) > 0,
                "must own specifc token"
            );
        }

        require(msg.value == _amount * listings[_listingId].price, "wrong amount of ETH sent");

        IERC1155(listings[_listingId].tokenContract).safeTransferFrom(
            listings[_listingId].seller,
            msg.sender,
            listings[_listingId].tokenId,
            _amount,
            ""
        );
        listings[_listingId].balance += msg.value;
    }

    function withdrawFunds(uint256 _listingId, uint256 _amount) public {
        require(listings[_listingId].seller == msg.sender, "caller is not seller");
        listings[_listingId].seller.transfer(_amount);
        listings[_listingId].balance = listings[_listingId].balance - _amount;
    }
}
