//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";

interface Minter {
    function purchase(
        address buyer,
        uint256 tokenId,
        string memory metaUri
    ) external returns (uint256);
}

/// @custom:security-contact contact@boogie-woogie.io
contract BoogieWoogieRunOneAuction is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _printsSold;

    uint256 private _currentPrice;

    uint256 public constant MAX_ELEMENTS = 125;
    address public tokenContract;

    // Retain purchased Boogie-Woogies for lookup
    mapping(uint256 => bool) public purchased;

    event ReceivedPurchaseRequest(uint256 boogieWoogieId);
    event BoogieWoogiePurchased(address buyer, uint256 boogieWoogieId);

    constructor(address token) {
        // 1 ETH
        _currentPrice = 1 * 10**18;
        // 0.01
        // _currentPrice = 1 * 10**16;

        tokenContract = token;
    }

    function currentPrice() public view returns (uint256) {
        return _currentPrice;
    }

    function hasBeenPurchased(uint256 tokenId) public view returns (bool) {
        return purchased[tokenId];
    }

    function setCurrentPrice(uint256 price) public onlyOwner {
        _currentPrice = price;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() public onlyOwner {
        address payable to = payable(owner());

        to.transfer(getBalance());
    }

    error AlreadyPurchased();
    error OutOfBoogieWoogies();

    function purchaseBoogieWoogie(
        address buyer,
        uint256 boogieWoogieId,
        string memory metaUri
    ) external payable {
        require(msg.value >= _currentPrice, "Value is less than cost");

        require(_printsSold.current() <= MAX_ELEMENTS, "Sold Out");

        if (purchased[boogieWoogieId]) revert AlreadyPurchased();

        emit ReceivedPurchaseRequest(boogieWoogieId);

        purchased[boogieWoogieId] = true;
        _printsSold.increment();

        Minter(tokenContract).purchase(buyer, boogieWoogieId, metaUri);

        emit BoogieWoogiePurchased(buyer, boogieWoogieId);
    }
}
