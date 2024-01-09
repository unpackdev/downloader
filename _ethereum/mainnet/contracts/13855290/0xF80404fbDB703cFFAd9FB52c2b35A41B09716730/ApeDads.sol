// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract ApeDads is ERC721, Ownable {
    uint256 private _totalSupply;
    uint256 private _maxSupply = 4000;
    uint256 public price = 0.08 ether;

    bool public publicsaleActive = true;

    mapping(address => uint8) public publicsaleMints;
    uint256 public publicsaleMintLimit = 5;

    address private _wallet1 = 0x62139339A2a3966C9660cab942e27f22B549f306;
    address private _wallet2 = 0x4Eb19e0AE143B607Cb3C6942cA11d25c2EfEcCB0;

    string public provenanceHash;
    string public baseURI;

    constructor() ERC721("ApeDads", "APEDADS") {}

    function mintPublicsale(uint256 count) external payable {
        require(msg.sender == tx.origin, "Reverted");
        require(publicsaleActive, "Public sale is not active");
        require(_totalSupply + count <= _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= 5, "Out of per transaction mint limit");
        require(msg.value >= count * price, "Insufficient payment");
        require(publicsaleMints[msg.sender] + count <= publicsaleMintLimit, "Per wallet mint limit");

        for (uint256 i = 0; i < count; i++) {
            _totalSupply++;
            _mint(msg.sender, _totalSupply);
            publicsaleMints[msg.sender]++;
        }

        distributePayment();
    }

    function distributePayment() internal {
        bool success = false;
        (success,) = _wallet1.call{value : msg.value * 85 / 100}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : msg.value * 15 / 100}("");
        require(success2, "Failed to send2");

    }

    function togglePublicsale() external onlyOwner {
        publicsaleActive = !publicsaleActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        provenanceHash = newProvenanceHash;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    event PriceUpdated(uint256 price);
}
