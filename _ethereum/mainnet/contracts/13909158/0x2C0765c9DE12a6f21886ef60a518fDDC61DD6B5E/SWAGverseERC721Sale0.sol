// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SWAGverseERC721.sol";

contract SWAGverseERC721Sale0 is Ownable {
    event Sold(address indexed to, uint256 indexed tokenId, address indexed paymentTokenAddress, uint256 price);

    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public nftAddress;
    address public paymentTokenAddress;
    uint256 public price;
    uint256 public supply;
    address public paymentRecipient;

    constructor(address _nftAddress, address _paymentTokenAddress, uint256 _price, uint256 _supply, address _paymentRecipient) {
        nftAddress = _nftAddress;
        paymentTokenAddress = _paymentTokenAddress;
        price = _price;
        supply = _supply;
        paymentRecipient = _paymentRecipient;

        emit Transfer(address(0), owner(), 0);
    }

    function buy() public payable {
        require(canBuy());

        SWAGverseERC721 nftContract = SWAGverseERC721(nftAddress);
        nftContract.mintTo(_msgSender());

        uint256 tokenId = nftContract.totalSupply();

        emit Sold(_msgSender(), tokenId, paymentTokenAddress, price);

        address recipient = paymentRecipient == address(0) ? owner() : paymentRecipient;

        if (paymentTokenAddress == address(0)) {
            require(msg.value == price);
            (bool success, ) = recipient.call{value: price}("");
            require(success, "Transfer failed.");
        } else {
            require(msg.value == 0);
            ERC20 tokenContract = ERC20(paymentTokenAddress);
            tokenContract.transferFrom(_msgSender(), recipient, price);
        }
    }

    function canBuy() public view returns (bool) {
        SWAGverseERC721 nftContract = SWAGverseERC721(nftAddress);
        uint256 minted = nftContract.totalSupply();
        return minted < supply;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        emit Transfer(_prevOwner, newOwner, 0);
    }

    function returnOwnership() public onlyOwner {
        SWAGverseERC721 nftContract = SWAGverseERC721(nftAddress);
        nftContract.transferOwnership(owner());
    }

    function setPaymentTokenAddress(address _paymentTokenAddress) public onlyOwner {
        paymentTokenAddress = _paymentTokenAddress;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }

    function setPaymentRecipient(address _paymentRecipient) public onlyOwner {
        paymentRecipient = _paymentRecipient;
    }
}
