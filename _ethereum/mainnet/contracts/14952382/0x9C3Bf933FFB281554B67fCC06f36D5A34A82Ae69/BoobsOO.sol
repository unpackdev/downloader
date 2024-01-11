// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract BoobsOO is ERC721A, Ownable {
    using Strings for uint256;

    //
    string public baseURI;
    uint256 public constant maxSupply = 6009; 
    uint256 public freeSupply = 1111;
    uint256 public price = 0.003 ether;
    uint256 public maxFreePerWallet = 1;
    uint256 public maxPerTx = 10;
    bool public mintEnabled = true;

    mapping(address => uint256) private _walletFreeMints;

    constructor() ERC721A("BoobsOO", "BoobsOO") {
        baseURI = "ipfs://QmdXGs4NRgeSGhNETBinVqPiVUXvLbSPH8GBtF9E5EHEPt/";
        _safeMint(msg.sender, 20);
    }

    function mintBoobs(uint256 amt) external payable {
        require(mintEnabled, "Minting is not live yet.");
        require(msg.sender == tx.origin, "No bots, only true BoobsOO!");
        require(
            totalSupply() + amt < maxSupply + 1,
            "Not enough BoobsOO left."
        );
        require(amt < maxPerTx + 1, "Not enough BoobsOO per tx left.");
        require(msg.value >= amt * price, "Please send the exact amount.");

        _safeMint(msg.sender, amt);
    }

    function freeBoobs(uint256 amt) external {
        require(mintEnabled, "Minting is not live yet.");
        require(msg.sender == tx.origin, "No bots, only true BoobsOO!");
        require(
            totalSupply() + amt < freeSupply + 1,
            "Not enough Free BoobsOO left."
        );
        require(
            _walletFreeMints[_msgSender()] + amt < maxFreePerWallet + 1,
            "That's enough Free BoobsOO for you!"
        );

        _walletFreeMints[_msgSender()] += amt;
        _safeMint(msg.sender, amt);
    }

    function devBoobs(uint256 amt) external onlyOwner {
        require(mintEnabled, "Minting is not live yet.");
        require(
            totalSupply() + amt < maxSupply + 1,
            "Not enough BoobsOO left."
        );

        _safeMint(msg.sender, amt);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : ".json";
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMaxFreePerWallet(uint256 maxFreePerWallet_) external onlyOwner {
        maxFreePerWallet = maxFreePerWallet_;
    }

    function setMaxPerWallet(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setFreeSupply(uint256 freeSupply_) external onlyOwner {
        freeSupply = freeSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
