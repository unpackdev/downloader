// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract TheDubaiProjectCarCollectible is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    struct CardType {
        uint256 id;
        bytes32 name;
        uint256 maxToken;
        uint256 sold;
        uint256 offset;
        uint256 priceWei;
    }
    CardType[] public cardTypes;

    bool private SALE_STARTED = false;
    string public BASE_URI = "https://meta.thedubaiproject.com/json/";

    event SaleStateChanged(bool isStarted);
    event BaseURIChanged(string newBaseURI);

    constructor() ERC721("The Dubai Project Collection", "CAR") {
        CardType memory black = CardType({
            id: 1,
            name: "Black",
            maxToken: 500,
            sold: 0,
            offset: 0,
            priceWei: 7 * 10**18 // 7 ETH
        });
        cardTypes.push(black);

        CardType memory platinum = CardType({
            id: 2,
            name: "Platinum",
            maxToken: 1500,
            sold: 0,
            offset: 500,
            priceWei: 1.5 * 10**18 // 1.5 ETH
        });
        cardTypes.push(platinum);

        CardType memory gold = CardType({
            id: 3,
            name: "Gold",
            maxToken: 5500,
            sold: 0,
            offset: 2000,
            priceWei: 0.55 * 10**18 // 0.55 ETH
        });
        cardTypes.push(gold);
    }

    function mint(uint256 _cTypeId) external payable {
        uint256 maxToken = cardTypes[_cTypeId - 1].maxToken;
        uint256 sold = cardTypes[_cTypeId - 1].sold;
        uint256 price = cardTypes[_cTypeId - 1].priceWei;

        require(SALE_STARTED, "Sale not started yet");
        require(price == msg.value, "Ether value sent is not correct");
        require(sold < maxToken, "No more token available");

        uint256 mintIndex = cardTypes[_cTypeId - 1].offset + sold;
        _safeMint(msg.sender, mintIndex);
        cardTypes[_cTypeId - 1].sold += 1;
    }

    function giveAway(address _receiver, uint256 _cTypeId) external onlyOwner {
        uint256 maxToken = cardTypes[_cTypeId - 1].maxToken;
        uint256 sold = cardTypes[_cTypeId - 1].sold;

        require(sold < maxToken, "No more token available");

        uint256 mintIndex = cardTypes[_cTypeId - 1].offset + sold;
        _safeMint(_receiver, mintIndex);
        cardTypes[_cTypeId - 1].sold += 1;
    }

    function kill(address payable to) public onlyOwner {
        selfdestruct(to);
    }

    function flipSaleStarted() external onlyOwner {
        SALE_STARTED = !SALE_STARTED;
        emit SaleStateChanged(SALE_STARTED);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw(address to, uint256 percent) public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 split = (balance * (percent)) / 100;

        (bool success, ) = to.call{value: split}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        BASE_URI = _URI;
        emit BaseURIChanged(BASE_URI);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return BASE_URI;
    }
}
