// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Cybots is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public maxPerTx = 5;
    uint256 public maxSupply = 5000;
    uint256 public maxPerWallet = 5;
    bool public isMintEnabled;
    string internal baseTokenUri;
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor() ERC721A("Cybots", "CB") {}

    function setIsMintEnabled(bool _isMintEnabled) external onlyOwner {
        isMintEnabled = _isMintEnabled;
    }

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function mint(uint256 _quantity) public payable {
        require(isMintEnabled, "minting not enabled");
        uint256 totalMinted = totalSupply();
        require(totalMinted + _quantity <= maxSupply, "sold out");
        require(_quantity < maxPerTx + 1, "Max per TX reached.");
        require(
            walletMints[msg.sender] + _quantity <= maxPerWallet,
            "exceed max wallet"
        );

        _safeMint(msg.sender, _quantity);
    }

    function ownerBatchMint(uint256 _quantity) public onlyOwner nonReentrant {
        uint256 totalMinted = totalSupply();
        require(totalMinted + _quantity <= maxSupply, "sold out");

        _safeMint(msg.sender, _quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}
