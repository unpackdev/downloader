// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract JiraBear is ERC721A, Ownable {
    uint256 public maxSupply = 4500;
    uint256 public freeSupply = 2500;
    uint256 private constant maxPerAddress = 20;
    uint256 private constant maxFreePerAddress = 1;
    uint256 public constant publicMintPrice = 0.0066 ether;
    uint256 public saleStartDate = 1654963200;
    uint256 public freeMintCounter;
    string private baseUri =
        "https://gateway.pinata.cloud/ipfs/QmXX1bsnEqaxcaVwx51b4RYbtuc1PJbxdELnCTzMCNpeQw/";
    string private baseExtension = ".json";

    constructor() ERC721A("JIRA VS BEAR", "JVSB") {}

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseUri).length != 0
                ? string(
                    abi.encodePacked(
                        baseUri,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= saleStartDate;
    }

    function setSaleStartDate(uint256 date) external onlyOwner {
        saleStartDate = date;
    }

    function numberminted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function freeMint(uint256 amount) external onlyEOA {
        require(isSaleOpen(), "Sale not open");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            (amount > 0) && (amount <= maxFreePerAddress),
            "Incorrect amount"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxFreePerAddress,
            "Max per address"
        );
        require(freeMintCounter + amount <= freeSupply, "Max Supply Reached");
        freeMintCounter += amount;
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable onlyEOA {
        require(isSaleOpen(), "Sale not open");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require((amount > 0) && (amount <= maxPerAddress), "Incorrect amount");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(msg.value >= publicMintPrice * amount, "Incorrect Price sent");
        _safeMint(msg.sender, amount);
    }

    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "Zero Balance");
        payable(msg.sender).transfer(address(this).balance);
    }
}
