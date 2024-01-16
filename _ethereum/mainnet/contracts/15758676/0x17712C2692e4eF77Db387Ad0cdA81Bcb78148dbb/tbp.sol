//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TheBillionPage is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public paused = false;

    string public baseURI;

    uint256 public origPrice = 0.39 ether;

    uint256 public maxSupply = 12321;
    uint256 public preSaleInnovators = 249;
    uint256 public preSale1 = 1476;
    uint256 public preSale2 = 4026;
    uint256 public origSale = 5256;

    mapping(address => uint256) public addressMintedBalance;
    uint256 public perAddressLimit = 6;

    mapping(uint256 => bool) public existingIDs;

    address payable public commissionRecipient;

    event CoordinatesTaken(
        uint256 indexed tokenId,
        address owner,
        uint256 price
    );

    constructor() ERC721("The Billion Page", "TBP") {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _metadataID)
        public
        payable
        returns (uint256)
    {
        require(!paused, "Currently it is not active");
        require(
            _metadataID >= 1 && _metadataID <= maxSupply,
            "Not valid number #!"
        );
        require(existingIDs[_metadataID] != true, "It is already taken!");

        uint256 currentPrice = getCurrentPrice();

        if (msg.sender != owner()) {
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(
                ownerMintedCount + 1 <= perAddressLimit,
                "The maximum per address reached"
            );

            require(
                msg.value >= currentPrice,
                "The amount sent must be equal to price"
            );

            addressMintedBalance[msg.sender] =
                addressMintedBalance[msg.sender] +
                1;
        }

        existingIDs[_metadataID] = true;
        _safeMint(_to, _metadataID);

        emit CoordinatesTaken(_metadataID, _to, currentPrice);

        return _metadataID;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Return current price with respect to pre-sale special offers
    function getCurrentPrice() public view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 price;

        if (supply < preSaleInnovators) {
            price = 0.0156 ether;
        } else if (supply < preSaleInnovators + preSale1) {
            price = 0.0312 ether;
        } else if (supply < preSaleInnovators + preSale1 + preSale2) {
            price = 0.195 ether;
        } else if (
            supply < preSaleInnovators + preSale1 + preSale2 + origSale
        ) {
            price = origPrice;
        } else {
            price = 1.287 ether;
        }
        return price;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return super.tokenURI(tokenId);
    }

    function detectCoordsTaken(uint256 metadataID) public view returns (bool) {
        return existingIDs[metadataID] == true;
    }

    //!  ONLY OWNER
    // Price change functions is used in case ETH price goes crazy
    function setOrigPrice(uint256 _newOrigPrice) public onlyOwner {
        origPrice = _newOrigPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCommissionRecipient(address payable _user) public onlyOwner {
        commissionRecipient = _user;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawToCommissionRecipient() public payable onlyOwner {
        require(
            commissionRecipient != address(0),
            "No commission recipient is set!"
        );
        uint256 balanceIs = address(this).balance;
        require(payable(commissionRecipient).send(balanceIs));
    }
}
