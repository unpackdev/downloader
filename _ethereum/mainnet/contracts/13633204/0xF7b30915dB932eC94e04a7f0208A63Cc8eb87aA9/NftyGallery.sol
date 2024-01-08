//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./IGallery.sol";
import "./GalleryAuction.sol";

contract NftyGallery is ERC721, IGallery {
    uint256 currentTokenId;
    string metadatabaseURI;

    address private _owner;
    uint256 private amountGifted;
    uint256 constant OWNER_ENTITLEMENT = 150;

    struct FrameContents {
        address _contract_address;
        uint256 token_id;
    }

    bool metadataFrozen;
    mapping(uint256 => mapping(uint256 => FrameContents))  private _galleryContents;

    address auctionHouseAddress;

    constructor() ERC721("NftyGalleries", "NFTYGALLERY") {
        _owner = _msgSender();
        GalleryAuction c = new GalleryAuction(address(this), _owner);
        auctionHouseAddress = address(c);
        metadataFrozen = false;
    }


    //OWNERSHIP UTILS

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    function mintNFT(address recipient)
    public override
    returns (uint256)
    {
        require(currentTokenId < 10000);
        require(_msgSender() == auctionHouseAddress || _msgSender() == owner());
        currentTokenId++;


        if (metadataFrozen) {
            emit PermanentURI(tokenURI(currentTokenId), currentTokenId);
        }
        _mint(recipient, currentTokenId);

        return currentTokenId;
    }

    event PermanentURI(string _value, uint256 indexed _id);

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        string memory tokenIdString = Strings.toString(tokenId);

        return string(abi.encodePacked(metadatabaseURI, '/', tokenIdString, '.json'));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(metadatabaseURI, '/contract.json'));
    }

    function setGalleryFrames(uint256 tokenID, uint256[] calldata frameIndex, address[] calldata displayeeContractAddress, uint256[] calldata displayeeTokenID)
    external
    {
        require(_exists(tokenID) && ERC721.ownerOf(tokenID) == _msgSender() && frameIndex.length == displayeeTokenID.length && frameIndex.length == displayeeContractAddress.length);

        for (uint256 i = 0; i < frameIndex.length; i++) {
            require(frameIndex[i] < 60);

            if (displayeeContractAddress[i] != address(0)) {
                IERC721 other = IERC721(displayeeContractAddress[i]);
                require(other.supportsInterface(type(IERC721Metadata).interfaceId));


                require(other.ownerOf(displayeeTokenID[i]) == _msgSender());
                _galleryContents[tokenID][frameIndex[i]] = FrameContents({_contract_address : displayeeContractAddress[i], token_id : displayeeTokenID[i]});
            }
            else {
                delete _galleryContents[tokenID][frameIndex[i]];
            }
        }
    }

    function removeAllFrames(uint256 tokenID) external {
        require(_exists(tokenID));
        require(ERC721.ownerOf(tokenID) == _msgSender());

        for (uint256 i = 0; i < 60; i++) {
            delete _galleryContents[tokenID][i];
        }
    }

    function setMetadataURI(string calldata newURI) external onlyOwner {
        require(!metadataFrozen);
        metadatabaseURI = newURI;
    }

    function freezeMetadata() external onlyOwner {
        metadataFrozen = true;
        for (uint256 i = 1; i <= currentTokenId; i++)
        {
            emit PermanentURI(tokenURI(currentTokenId), currentTokenId);
        }
    }

    function ownerGift(address[] calldata giftees)
    external onlyOwner {
        require(giftees.length <= OWNER_ENTITLEMENT - amountGifted);

        //Due to the above require, no overflows can occur here
        amountGifted += giftees.length;

        for (uint256 i = 0; i < giftees.length; i++) {
            mintNFT(giftees[i]);
        }
    }

    function ownerGiftSelf(uint amount)
    external onlyOwner {
        require(amount <= OWNER_ENTITLEMENT - amountGifted);

        //Due to the above require, no overflows can occur here
        amountGifted += amount;
        for (uint256 i = 0; i < amount; i++) {
            mintNFT(_msgSender());
        }


    }

    function getFrameContentsInfo(uint256 tokenID, uint256 frameIndex)
    external view
    returns (address displayeeContractAddress, uint256 displayeeTokenID)
    {
        require(_galleryContents[tokenID][frameIndex]._contract_address != address(0));

        FrameContents memory contents = _galleryContents[tokenID][frameIndex];
        IERC721 other = IERC721(contents._contract_address);
        require(other.ownerOf(contents.token_id) == ERC721.ownerOf(tokenID));

        return (contents._contract_address, contents.token_id);
    }

    function getFrameContentsURI(uint256 tokenID, uint256 frameIndex)
    external view
    returns (string memory contentURI)
    {
        if (_galleryContents[tokenID][frameIndex]._contract_address == address(0)) {
            return "";
        }
        FrameContents memory contents = _galleryContents[tokenID][frameIndex];
        IERC721 other = IERC721(contents._contract_address);
        if (other.ownerOf(contents.token_id) != ERC721.ownerOf(tokenID)) {
            return "";
        }

        IERC721Metadata metadata = IERC721Metadata(contents._contract_address);
        return metadata.tokenURI(contents.token_id);
    }


    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function totalSupply()
    external override view returns (uint256){
        return currentTokenId;
    }

    function getGalleriesOwnedBy(address potentialOwner) external view returns (uint256[] memory) {
        uint256[] memory ownedGalleries = new uint256[](balanceOf(potentialOwner));
        uint currentIndex = 0;
        for (uint256 i = 1; i <= currentTokenId; i++)
        {
            if (ownerOf(i) == potentialOwner) {
                ownedGalleries[currentIndex] = i;
                currentIndex += 1;
            }
        }
        return ownedGalleries;
    }

    function getAuctionAddress() external view virtual returns (address) {
        return auctionHouseAddress;
    }
}
