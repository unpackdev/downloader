// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BlurApeYachtClub is ERC721A, Ownable {
    uint256 public MaxPerTxn = 15;
    bool public mintEnabled = false;
    uint256 public maxSupply = 5555;
    uint256 public price = 0.003 ether;
    string public baseURI = "ipfs://QmP8FqaoNRLRNbAzHsTEFNFidaZcNTef8fLzNNoqjXgb92/";
    mapping(address => bool) public wlAddress;
    mapping(address => bool) public blacklistedMarketplaces;

    constructor(address[] memory _address) ERC721A("BlurApeYachtClub", "BAYC") {
        for (uint256 i = 0; i < _address.length; i++) {
            wlAddress[_address[i]] = true;
        }

        blacklistedMarketplaces[
            0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e
        ] = true;
        blacklistedMarketplaces[
            0xF849de01B080aDC3A814FaBE1E2087475cF2E354
        ] = true;
        blacklistedMarketplaces[
            0x1E0049783F008A0085193E00003D00cd54003c71
        ] = true;
        blacklistedMarketplaces[
            0xb16c1342E617A5B6E4b631EB114483FDB289c0A4
        ] = true;
    }

    function devMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "sold out");
        _safeMint(msg.sender, quantity);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function toggleMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function mint(uint256 quantity) external payable {
        require(mintEnabled, "wait until sale start");
        require(totalSupply() + quantity <= maxSupply, "max supply reached");
        require(quantity <= MaxPerTxn, "max out");
        require(tx.origin == msg.sender, "The caller is another contract");

        uint256 count = quantity;
        if (wlAddress[msg.sender]) count = 0;

        require(msg.value >= count * price, "Please send the exact amount.");

        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function changePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function approve(address to, uint256 id) public payable virtual override {
        require(!blacklistedMarketplaces[to], "Use Blur.io");
        super.approve(to, id);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(!blacklistedMarketplaces[operator], "Use Blur.io");
        super.setApprovalForAll(operator, approved);
    }
}
