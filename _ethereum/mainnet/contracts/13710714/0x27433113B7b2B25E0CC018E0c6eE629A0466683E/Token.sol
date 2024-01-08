//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 10010;

    // Public sale
    uint256 public constant PRICE = 0.08 ether;

    // Pre-sale
    bool public presale = true;
    uint256 public constant PRE_PRICE = 0.07 ether;
    mapping (address => uint256) public preMinted;
    uint256 public preNFTsMinted;
    mapping (address => bool) public isWhitelisted;
    mapping (address => uint256) public VIPAmounts;

    bool public hidden = false;
    uint256 public revealDate = 1638334800;

    string public baseTokenURI;

    uint256[10] public giveawayNFTs = [10001, 10002, 10003, 10004, 10005, 10006, 10007, 10008, 10009, 10010];

    constructor(string memory baseURI) ERC721("Picky Parrots", "PPT") {
        setBaseURI(baseURI);

        // Mint the special giveaway NFTs
        for (uint256 i = 0;i < giveawayNFTs.length;i++) {
            _safeMint(msg.sender, giveawayNFTs[i]);
        }
        
        // Mint the normal giveaway NFTs
        for (uint256 i = 0; i < 10; i++) {
            preNFTsMinted += 1;
            _mintSingleNFT();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (block.timestamp < revealDate && hidden) {
            return "";
        }
        
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mintNFTs(uint256 _count) public payable {
        uint256 totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count > 0, "Cannot mint 0 NFTs.");
        require(msg.value >= calculatePrice(_count),"Not enough ether to purchase NFTs.");
        
        if (presale) {
            require(isWhitelisted[msg.sender], "Address is not whitelisted!");
            preNFTsMinted += _count;
            require(preNFTsMinted <= 1500, "Pre-sale is over.");
            bool freeNft;
            if (preMinted[msg.sender] == 0) {
                freeNft = true;
            }
            preMinted[msg.sender] += _count;
            require(preMinted[msg.sender] <= 3, "Address can't mint more NFTs in pre-sale.");

            if (freeNft) _count += 1;
        }

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function claimFreeNFTsVIP() public {
        require(VIPAmounts[msg.sender] > 0, "No free NFTs left!");

        uint256 _count = VIPAmounts[msg.sender];
        VIPAmounts[msg.sender] = 0;
        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function calculatePrice(uint256 _count) public view returns(uint256) {
        if (presale) {
            return _count * PRE_PRICE;
        }
        
        return _count * PRICE;
    }

    function _mintSingleNFT() private {
        uint256 newTokenID = _tokenIds.current();
        if (newTokenID == 0) {
            _tokenIds.increment();
            newTokenID = _tokenIds.current();
        }
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function startPublicSale() external onlyOwner {
        presale = false;
    }

    function revealNFTs() external onlyOwner {
        hidden = false;
    }

    function addToVIPlist (address[] memory _addresses, uint256[] memory _amounts) external onlyOwner {
        for (uint256 i = 0;i < _addresses.length;i++) {
            VIPAmounts[_addresses[i]] = _amounts[i];
        }
    }

    function removeFromVIPlist (address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0;i < _addresses.length;i++) {
            VIPAmounts[_addresses[i]] = 0;
        }
    }

    function addToWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0;i < _addresses.length;i++) {
            isWhitelisted[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist (address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0;i < _addresses.length;i++) {
            isWhitelisted[_addresses[i]] = false;
        }
    }
}