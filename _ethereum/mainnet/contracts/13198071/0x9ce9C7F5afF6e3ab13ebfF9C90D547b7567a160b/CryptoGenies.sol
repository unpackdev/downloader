// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title Crypto Genies contract
 */
contract CryptoGenies is ERC721Enumerable, Ownable {
    string public PROVENANCE_HASH = "";
    uint256 public MAX_ITEMS;
    uint256 public MAX_PRESALE_ITEMS;
    uint256 public PUBLIC_ITEMS;
    uint256 public COMMUNITY_ITEMS;

    string public baseUri;
    bool public isSaleActive;
    bool public isPresaleActive;
    uint256 public saleStartBlock;
    uint256 public presaleStartBlock;
    uint256 public mintPrice;
    uint256 public maxPerMint;
    uint256 public maxPerPresaleMint;
    uint256 public communityMinted;
    uint256 public presaleMinted;

    mapping(address => bool) public presaleWhitelist;
    mapping(address => uint) public presaleClaimed;

    event SetBaseUri(string indexed baseUri);

    modifier whenSaleActive {
        require(isSaleActive || block.number >= saleStartBlock, "Crypto Genies: Sale is not active");
        _;
    }

    modifier whenPresaleActive {
        require(isPresaleActive || block.number >= presaleStartBlock, "Crypto Genies: Presale is not active");
        require(presaleMinted < MAX_PRESALE_ITEMS, "Crypto Genies: Presale sold out");
        _;
    }

    constructor() ERC721("Crypto Genies", "GENIE") {
        presaleStartBlock = 13199200;
        saleStartBlock = 13210900;

        MAX_ITEMS = 10000;
        MAX_PRESALE_ITEMS = 2000;
        COMMUNITY_ITEMS = 50;
        PUBLIC_ITEMS = MAX_ITEMS - COMMUNITY_ITEMS;

        mintPrice = 0.005 ether;
        maxPerMint = 20;
        maxPerPresaleMint = 3;
        baseUri = "ipfs://QmYR4iYpRZEhpShoU5UiNqXjZYvMpwQGSvazPKufSn3YXp/";
    }

    // ------------------
    // Utility view functions
    // ------------------

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function mint(uint256 amount) external payable whenSaleActive {
        uint256 publicMinted = totalSupply() - communityMinted;

        require(amount <= maxPerMint, "Crypto Genies: Amount exceeds max per mint");
        require(publicMinted + amount <= PUBLIC_ITEMS, "Crypto Genies: Purchase would exceed cap");
        require(mintPrice * amount <= msg.value, "Crypto Genies: Ether value sent is not correct");

        for(uint256 i = 0; i < amount; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (publicMinted< PUBLIC_ITEMS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function presaleMint(uint256 amount) external payable whenPresaleActive {
        require(amount <= maxPerPresaleMint, "Crypto Genies: Amount exceeds max per presale mint");
        require(presaleMinted + amount <= MAX_PRESALE_ITEMS, "Crypto Genies: Purchase would exceed presale supply cap");
        require(presaleClaimed[msg.sender] + amount <= maxPerPresaleMint, 'Purchase exceeds max allowed presale address cap');
        require(mintPrice * amount <= msg.value, "Crypto Genies: Ether value sent is not correct");

        for(uint256 i = 0; i < amount; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (presaleMinted < MAX_PRESALE_ITEMS) {
                presaleClaimed[msg.sender] += 1;
                presaleMinted += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // ------------------
    // Functions for the owner
    // ------------------

    function updateWhitelist(address[] memory addresses, bool remove) external onlyOwner {
      for (uint i=0; i < addresses.length; i++) {
        require(addresses[i] != address(0), "Can't add the null address");

        presaleWhitelist[addresses[i]] = remove ? false : true;
        presaleClaimed[addresses[i]] > 0 ? presaleClaimed[addresses[i]] : 0;
      }
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setMaxPerPresaleMint(uint256 _maxPerPresaleMint) external onlyOwner {
        maxPerPresaleMint = _maxPerPresaleMint;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
        emit SetBaseUri(baseUri);
    }

    function setPresaleStartBlock(uint256 blockNumber) external onlyOwner {
        presaleStartBlock = blockNumber;
    }

    function setSaleStartBlock(uint256 blockNumber) external onlyOwner {
        saleStartBlock = blockNumber;
    }

    function mintForCommunity(address _to, uint256 _numberOfTokens) external onlyOwner {
        require(_to != address(0), "Crypto Genies: Cannot mint to zero address.");
        require(totalSupply() + _numberOfTokens <= MAX_ITEMS, "Crypto Genies: Minting would exceed cap");
        require(communityMinted + _numberOfTokens <= COMMUNITY_ITEMS, "Crypto Genies: Minting would exceed community cap");

        for(uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < MAX_ITEMS && communityMinted < COMMUNITY_ITEMS) {
                _safeMint(_to, mintIndex);
                communityMinted = communityMinted + 1;
            }
        }
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }

    function toggleSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function togglePresaleState() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}