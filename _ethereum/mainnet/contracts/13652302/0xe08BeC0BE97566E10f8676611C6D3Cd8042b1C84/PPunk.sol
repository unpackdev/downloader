/**
 *
 * Copyright Notice: User must include the following signature.
 *
 * Smart Contract Developer: www.QambarRaza.com
 *
 * ..#######.....###....##.....##.########.....###....########.
 * .##.....##...##.##...###...###.##.....##...##.##...##.....##
 * .##.....##..##...##..####.####.##.....##..##...##..##.....##
 * .##.....##.##.....##.##.###.##.########..##.....##.########.
 * .##..##.##.#########.##.....##.##.....##.#########.##...##..
 * .##....##..##.....##.##.....##.##.....##.##.....##.##....##.
 * ..#####.##.##.....##.##.....##.########..##.....##.##.....##
 * .########.....###....########....###...
 * .##.....##...##.##........##....##.##..
 * .##.....##..##...##......##....##...##.
 * .########..##.....##....##....##.....##
 * .##...##...#########...##.....#########
 * .##....##..##.....##..##......##.....##
 * .##.....##.##.....##.########.##.....##
 */

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./CurrentHolders.sol";

contract PPunk is ERC721, ERC721Enumerable, Ownable, CurrentHolders {
    uint256 public  PP_PRICE = 40000000000000000; //0.04 ETH
    uint256 public publicMintIndex = 250;
    uint256 private SALE_LIMIT = 3333;

    uint256 private mintedTokens;

    bool public isSaleActive = false;
    bool private isPreSaleActive = false;
    bool private isWhitelistActive = false;
    string private baseURI;

    mapping(address => bool) public winnerlist; //whitelistNumber 3
    mapping(address => uint256) public winnerlistMinted;
    mapping(address => uint256) public whitelistMinted;
    
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function mintCH() public {
        require(isPreSaleActive, "PPunk: Sale is not active");

        address wallet = msg.sender;

        chtG[wallet] = cht[wallet].length;
        for (uint256 i = 0; i < cht[wallet].length; i++) {
            _safeMint(msg.sender, cht[wallet][i]);
            cht[wallet][i] = 10000;
        }
    }

    function mintCHWhiteList(uint256 numberOfTokens) public {
        address wallet = msg.sender;

        require(isPreSaleActive, "PPunk: Sale is not active");

        require(cht[wallet].length > 0, "PPunk: Not allowed.");
        
        require(numberOfTokens <= chtG[wallet], "PPunk: You cannot mint more than what you had previously.");

        require(cht[wallet][0] == 10000, "PPunk: First migrate your current tokens from landing party.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, publicMintIndex++);
            chtG[wallet]--;
        }
    }

    function mintWhiteList(uint256 numberOfTokens) external payable {
        require(isPreSaleActive, "PPunk: Sale is not active");

        require(numberOfTokens <= 4, "PPunk: Can only mint 4 tokens at a time");
        require(whitelistMinted[msg.sender] < 4, "PPunk: You can only mint 4 tokens from the whitelist");

        require(
            msg.value >= (numberOfTokens * PP_PRICE),
            "PPunk: Insufficient funds"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, publicMintIndex++);
            whitelistMinted[msg.sender]++;
        }
    }

    function mintWinnerList() external payable {
        require(isPreSaleActive, "PPunk: Sale is not active");

        require(winnerlistMinted[msg.sender] < 1, "PPunk: You can only mint 1 tokens from the whitelist");

        require(
            msg.value >= PP_PRICE,
            "PPunk: Insufficient funds"
        );
        _safeMint(msg.sender, publicMintIndex++);
        winnerlistMinted[msg.sender]++;
    }

    function setSaleLimit(uint256 limit) public onlyOwner {
        SALE_LIMIT = limit;
    }

    function flipSaleActive() public onlyOwner {
        isSaleActive = !isSaleActive;

        if (isSaleActive) {
            isPreSaleActive = false;
        }
    }

    function flipPreSaleActive() public onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    function setPrice(uint256 price) public onlyOwner {
        PP_PRICE = price;
    }


    function mint(uint256 numberOfTokens) external payable {
        require(isSaleActive, "PPunk: Sale is not active");

        require(
           // PP_PRICE.mul(numberOfTokens) <= msg.value,
            PP_PRICE * numberOfTokens <= msg.value,
            "PPunk: Insufficient funds"
        );
        require(
            numberOfTokens <= 20,
            "PPunk: Can only mint 20 tokens at a time"
        );

        require(
            publicMintIndex + numberOfTokens <= SALE_LIMIT,
            "PPunk: More tokens requested than the sale limit"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, publicMintIndex++);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
}
