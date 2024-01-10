// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Xplorers is ERC721A("Xplorers", "XPLORERS"), Ownable {
    uint256 public currCap = 1500;
    uint256 public price = 50000000000000000;
    uint256 public maxPurchase = 10;
    mapping(address => uint256) public reservations;
    address private rl = 0xa343F89E7A90Ce6eB8888A4247820697DBE05623;
    uint256 public totalReserved = 0;
    uint256 public totalReservationsMinted = 0;
    uint256 public totalPublicMinted = 0;
    string public baseURL;
    bool public isPublicMintActive = false;
    bool public isReservationMintActive = false;
    string public provenanceHash;

    function getReservation(address addr) public view returns (uint256) {
        return reservations[addr];
    }

    function reserve(address[] memory ads, uint256[] memory howmany)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ads.length; i++) {
            reservations[ads[i]] = howmany[i];
            totalReserved = totalReserved + howmany[i] - reservations[ads[i]];
        }
    }

    function mintReserved(uint256 qty) external payable {
        require(isReservationMintActive, "Reservation sale must be active!");
        require(qty + totalSupply() <= currCap, "Exceeding supply cap!");
        uint256 res = reservations[msg.sender];
        require(res > 0, "0 Reserved for you!");
        require(qty <= res, "Cannot mint more than reserved!");
        require(price * qty <= msg.value, "Ether sent is not correct");
        _safeMint(msg.sender, qty);
        reservations[msg.sender] = (res - qty);
    }

    function publicMint(uint256 qty) external payable {
        require(isPublicMintActive, "Public mint not active!");
        require(qty + totalSupply() <= currCap, "Exceeding supply cap!");
        require(qty * price <= msg.value, "Eth value sent is not correct!");
        require(qty <= maxPurchase, "Max purchase exceeded!");
        totalPublicMinted = totalPublicMinted + qty;
        _safeMint(msg.sender, qty);
    }

    function devmint(uint256 quantity) external onlyOwner {
        _safeMint(owner(), quantity);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURL = uri;
    }

    function setPrice(uint256 newprice) public onlyOwner {
        price = newprice;
    }

    function setMaxPurchase(uint256 newMaxPurchase) public onlyOwner {
        maxPurchase = newMaxPurchase;
    }

    function setcurrCap(uint256 newcurrCap) public onlyOwner {
        currCap = newcurrCap;
    }

    function flipPublicMint() public onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function flipReservationMint() public onlyOwner {
        isReservationMintActive = !isReservationMintActive;
    }

    function setProvenanceHash(string memory phash) public onlyOwner {
        provenanceHash = phash;
    }

    function withdraw() public onlyOwner {
        uint256 b = address(this).balance;
        payable(rl).transfer((b * 15) / 100);
        payable(msg.sender).transfer((b * 85) / 100);
    }
}
