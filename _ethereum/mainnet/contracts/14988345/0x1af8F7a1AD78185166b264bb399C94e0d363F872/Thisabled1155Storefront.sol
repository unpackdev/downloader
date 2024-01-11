// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./IThisabled1155.sol";

contract Thisabled1155Storefront is IThisabled1155, AccessControl {
    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    address public nftContractAddress;
    IThisabled1155 private thisabled1155Contract;

    uint256[] private forSaleList;
    mapping(uint256 => Artwork) private idToArtwork;

    struct Artwork {
        bool valid;
        bool paused;
        uint256 price;
    }

    struct ArtworkForSale {
        uint256 tokenId;
        string uri;
        uint256 availablePrints;
        uint256 maxPrints;
        uint256 price;
        bool paused;
    }

    event ArtworkAddedToStorefront(
        uint256 indexed tokenId,
        uint256 prints,
        uint256 price
    );

    event ArtworkRemovedFromStorefront(uint256 indexed tokenId);

    event ArtworkSalePaused(uint256 indexed tokenId);

    event ArtworkSaleUnpaused(uint256 indexed tokenId);

    event PrintSold(uint256 indexed tokenId, uint256 price, address buyer);

    constructor(address _nftContractAddress) {
        nftContractAddress = _nftContractAddress;
        thisabled1155Contract = IThisabled1155(_nftContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier validArtworkId(uint256 tokenId) {
        require(idToArtwork[tokenId].valid, "Invalid Token ID");
        _;
    }

    function checkSalePaused(uint256 tokenId)
        public
        view
        validArtworkId(tokenId)
        returns (bool)
    {
        return idToArtwork[tokenId].paused;
    }

    function pauseSale(uint256 tokenId)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        require(!idToArtwork[tokenId].paused, "Artwork sale already paused");
        idToArtwork[tokenId].paused = true;
        emit ArtworkSalePaused(tokenId);
    }

    function unpauseSale(uint256 tokenId)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        require(idToArtwork[tokenId].paused, "Artwork sale not paused");
        idToArtwork[tokenId].paused = false;
        emit ArtworkSaleUnpaused(tokenId);
    }

    function getPrice(uint256 tokenId)
        public
        view
        validArtworkId(tokenId)
        returns (uint256)
    {
        return idToArtwork[tokenId].price;
    }

    function updatePrice(uint256 tokenId, uint256 newPrice)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        idToArtwork[tokenId].price = newPrice;
    }

    function getBalance()
        public
        view
        onlyRole(ACCOUNTANT_ROLE)
        returns (uint256)
    {
        return address(this).balance;
    }

    function withdrawETH(uint256 amount)
        public
        onlyRole(ACCOUNTANT_ROLE)
    {
        address payable to = payable(msg.sender);
        withdrawETHTo(to, amount);
    }

    function withdrawETHTo(address payable to, uint256 amount)
        public
        onlyRole(ACCOUNTANT_ROLE)
    {
        require(amount <= getBalance(), "Insufficent funds");
        to.transfer(amount);
    }

    function addArtworkToStorefront(string memory uri, uint256 prints, uint256 price, bool salePaused)
        public
        onlyRole(CURATOR_ROLE)
        returns (uint256)
    {
        require(prints > 0, "Print count must be non-zero");
        uint256 tokenId = thisabled1155Contract.addArtwork(uri, prints);
        idToArtwork[tokenId] = Artwork(true, salePaused, price);
        forSaleList.push(tokenId);
        emit ArtworkAddedToStorefront(tokenId, prints, price);
        if(salePaused){
            emit ArtworkSalePaused(tokenId);
        }
        return tokenId;
    }

    function batchAddArtworkToStorefront(string[] memory uris, uint256[] memory printCounts, uint256[] memory prices, bool[] memory salePausedList)
        public
        onlyRole(CURATOR_ROLE)
        returns (uint256[] memory)
    {
        require(uris.length == printCounts.length, "Every artwork must have a print count");
        require(uris.length == prices.length, "Every artwork must have a price");
        require(uris.length == salePausedList.length, "Every artwork must have a paused status");
        uint256 index;
        for(index = 0; index < uris.length; index++){
            require(printCounts[index] > 0, "Print count must be non-zero");
        }
        uint256[] memory tokenIds = thisabled1155Contract.batchAddArtwork(uris, printCounts);
        for(index = 0; index < tokenIds.length; index++){
            idToArtwork[tokenIds[index]] = Artwork(true, salePausedList[index], prices[index]);
            forSaleList.push(tokenIds[index]);
            emit ArtworkAddedToStorefront(
                tokenIds[index],
                printCounts[index],
                prices[index]
            );
            if(salePausedList[index]){
              emit ArtworkSalePaused(tokenIds[index]);
            }
        }
        return tokenIds;
    }

    function removeArtworkFromStorefront(uint256 tokenId)
        public
        onlyRole(CURATOR_ROLE)
        validArtworkId(tokenId)
    {
        delete idToArtwork[tokenId];
        //Remove token ID from artwork for sale listing
        for(uint256 i = 0; i < forSaleList.length; i++){
            if(forSaleList[i] == tokenId){
                forSaleList[i] = forSaleList[forSaleList.length - 1];
                forSaleList.pop();
                break;
            }
        }
        emit ArtworkRemovedFromStorefront(tokenId);
    }

    function getArtwork(uint256 tokenId)
        public
        view
        validArtworkId(tokenId)
        returns (ArtworkForSale memory)
    {
        string memory uri = thisabled1155Contract.tokenURI(tokenId);
        uint256 availablePrints = thisabled1155Contract.getAvailablePrints(tokenId);
        uint256 maxPrints = thisabled1155Contract.getMaxPrints(tokenId);
        ArtworkForSale memory artworkForSale = ArtworkForSale(
            tokenId,
            uri,
            availablePrints,
            maxPrints,
            idToArtwork[tokenId].price,
            idToArtwork[tokenId].paused
        );
        return artworkForSale;
    }

    function getAllArtwork()
        public
        view
        returns (ArtworkForSale[] memory)
    {
        ArtworkForSale[] memory artworkForSale = new ArtworkForSale[](forSaleList.length);
        uint256 tokenId;
        string memory uri;
        uint256 availablePrints;
        uint256 maxPrints;
        for(uint256 i = 0; i < forSaleList.length; i++){
            tokenId = forSaleList[i];
            uri = thisabled1155Contract.tokenURI(tokenId);
            availablePrints = thisabled1155Contract.getAvailablePrints(tokenId);
            maxPrints = thisabled1155Contract.getMaxPrints(tokenId);
            artworkForSale[i] = ArtworkForSale(
                tokenId,
                uri,
                availablePrints,
                maxPrints,
                idToArtwork[tokenId].price,
                idToArtwork[tokenId].paused
            );
        }
        return artworkForSale;
    }

    function mintArtwork(uint256 tokenId)
        public
        payable
        validArtworkId(tokenId)
    {
        require(!idToArtwork[tokenId].paused, "Artwork sale paused");
        require(msg.value == idToArtwork[tokenId].price, "Wrong price");
        require(thisabled1155Contract.getAvailablePrints(tokenId) > 0, "Artwork sold out");

        thisabled1155Contract.mint(msg.sender, tokenId, 1);
        emit PrintSold(tokenId, msg.value, msg.sender);
    }

    function batchMintArtwork(uint256[] memory tokenIds, uint256[] memory amounts)
        public
        payable
    {
        require(tokenIds.length == amounts.length, "Every token ID must have an amount");
        uint256 totalPrice;
        uint256 index;
        for(index = 0; index < tokenIds.length; index++){
          require(idToArtwork[tokenIds[index]].valid, "Invalid Token ID");
          require(!idToArtwork[tokenIds[index]].paused, "Artwork sale paused");
          require(thisabled1155Contract.getAvailablePrints(tokenIds[index]) - amounts[index] >= 0, "Amount requested exceeds available prints");
          totalPrice += idToArtwork[tokenIds[index]].price * amounts[index];
        }
        thisabled1155Contract.mintBatch(msg.sender, tokenIds, amounts);
        for(index = 0; index < tokenIds.length; index++){
          for(uint256 i = 0; i < amounts[index]; i++){
            emit PrintSold(tokenIds[index], idToArtwork[tokenIds[index]].price, msg.sender);
          }
        }
    }
}
