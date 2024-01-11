// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";

contract AdmitTwo is ERC721A, Ownable {
    using Strings for uint256;

    enum Status {
        Paused,
        PublicSale,
        Finished
    }

    Status public status;
    string baseURI;
    string public baseExtension = ".json";
    uint256 public maxPerTx = 5;
    uint256 public maxPerWallet = 10;
    uint256 public maxSupply = 2000;
    uint256 public price = 0.003 ether;
    uint256 public totalFree = 500;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory _initBaseURI) ERC721A("Admit Two", "ADMIT") {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        uint256 cost = price;
        if (totalSupply() + quantity < totalFree + 1) {
            cost = 0;
        }
        require(msg.value >= quantity * cost, "Not enough ETH.");
        require(status == Status.PublicSale, "sale has not started yet");
        require(tx.origin == msg.sender, "EOA only");
        require(quantity < maxPerTx + 1, "too many per tx.");
        require(
            numberMinted(msg.sender) + quantity <= maxPerWallet,
            "can not mint this many"
        );
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }
}
