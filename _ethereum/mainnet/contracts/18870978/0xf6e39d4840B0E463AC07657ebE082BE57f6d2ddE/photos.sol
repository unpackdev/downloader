// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PhotoDistrict is ERC1155, Ownable {
    struct Split {
        uint256 artistPercentage;
        uint256 photoDistrictPercentage;
        uint256 person1Percentage;
        uint256 person2Percentage;
        uint256 trunksUpPercentage;
    }

    struct Artist {
        address payable artistAddress;
        uint256 defaultPrice;
        uint256 splitType; // 1 or 2 for different split types
    }

    struct TokenInfo {
        uint256 artistId;
        uint256 remainingQuantity;
    }

    struct TokenQuantity {
        // Define the TokenQuantity struct
        uint256 tokenId;
        uint256 remainingQuantity;
    }

    mapping(uint256 => Artist) public artists;
    mapping(uint256 => TokenInfo) public tokenInfos;
    mapping(uint256 => Split) public splits;

    uint256 public nextArtistId = 1;
    uint256 public nextTokenId = 1;

    address public photoDistrictAddress = 0x1E31c297FD3d88710c35e9E1D7Eb5ce27494FC72;
    address public personOneAddress = 0x668743666ed31928fB57797631D74c8b3B1F7Ba8;
    address public personTwoAddress = 0x8Dd82df6116c9BF70b3E753E99778a85401C4682;
    address public trunksUpAddress = 0x8765613ce0abA9A077ec6579D08E1535FC010827;

    string private baseURI = "https://storage.googleapis.com/photodistric/meta/";

    constructor() ERC1155("") Ownable(msg.sender) {
        // Artist 0
        artists[0] = Artist(
            payable(address(0x3A0b104cdF14d3528Dd9410d4c95513585A08268)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(0, 0, 51, 250);

        // Artist 1
        artists[1] = Artist(
            payable(address(0x3A0b104cdF14d3528Dd9410d4c95513585A08268)),
            0.05 ether,
            2
        );
        initializeTokensForArtist(1, 52, 63, 500);

        // Artist 2
        artists[2] = Artist(
            payable(address(0x9453C41754739C01098d5604EC6891015dbd1dd3)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(2, 64, 71, 250);

        // Artist 3
        artists[3] = Artist(
            payable(address(0xf761ca7de329bBD668cF1D5A45805eEcf1365B80)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(3, 72, 99, 250);

        // Artist 4
        artists[4] = Artist(
            payable(address(0x5C783113C8074E42B0A205F374b8A2Ca2e8aF404)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(4, 100, 113, 250);

        // Artist 5
        artists[5] = Artist(
            payable(address(0x42A07B0313A2100FE9871F67d95e5B982864e408)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(5, 114, 146, 250);

        // Artist 6
        artists[6] = Artist(
            payable(address(0xa258095D0F750841191dd063d4C8fba5D4211Fe8)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(6, 147, 200, 250);

        // Artist 7
        artists[7] = Artist(
            payable(address(0x3A0b104cdF14d3528Dd9410d4c95513585A08268)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(7, 207, 207, 750);

        // Artist 8
        artists[8] = Artist(
            payable(address(0x3A0b104cdF14d3528Dd9410d4c95513585A08268)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(8, 205, 206, 500);

        // Artist 9
        artists[9] = Artist(
            payable(address(0x3A0b104cdF14d3528Dd9410d4c95513585A08268)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(9, 203, 204, 50);

        // Artist 10
        artists[10] = Artist(
            payable(address(0x3A0b104cdF14d3528Dd9410d4c95513585A08268)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(10, 201, 202, 100);

        // Artist 11
        artists[11] = Artist(
            payable(address(0x3A0b104cdF14d3528Dd9410d4c95513585A08268)),
            0.01 ether,
            1
        );
        initializeTokensForArtist(11, 208, 232, 250);

        nextArtistId = 12;
    }

    function initializeTokensForArtist(
        uint256 artistId,
        uint256 startTokenId,
        uint256 endTokenId,
        uint256 quantity
    ) internal {
        for (uint256 tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
            tokenInfos[tokenId] = TokenInfo(artistId, quantity);
            nextTokenId++;
        }
    }

    // Add a new artist
    function addArtist(
        address payable _artistAddress,
        uint256 _defaultPrice,
        uint256 _splitType
    ) public onlyOwner {
        artists[nextArtistId] = Artist(
            _artistAddress,
            _defaultPrice,
            _splitType
        );
        nextArtistId++;
    }

    // Add a new token for an artist
    function addToken(uint256 _artistId, uint256 _quantity) public onlyOwner {
        require(_artistId < nextArtistId, "Invalid artist ID");
        tokenInfos[nextTokenId] = TokenInfo(_artistId, _quantity);
        nextTokenId++;
    }

    // Function to retrieve all token IDs and their remaining quantities
    function getTokenQuantitiesByArtist(uint256 artistId)
        public
        view
        returns (TokenQuantity[] memory)
    {
        uint256 count = 0;

        // First, count how many tokens belong to the given artist
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (tokenInfos[i].artistId == artistId) {
                count++;
            }
        }

        // Create an array to store the quantities
        TokenQuantity[] memory quantities = new TokenQuantity[](count);
        uint256 index = 0;

        // Now, populate the array with the token quantities
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (tokenInfos[i].artistId == artistId) {
                quantities[index] = TokenQuantity(
                    i,
                    tokenInfos[i].remainingQuantity
                );
                index++;
            }
        }

        return quantities;
    }

    // Mint function
    function mint(uint256 tokenId, uint256 quantity) public payable {
        require(
            tokenInfos[tokenId].remainingQuantity >= quantity,
            "Not enough quantity left"
        );
        uint256 artistId = tokenInfos[tokenId].artistId;
        require(
            msg.value >= artists[artistId].defaultPrice * quantity,
            "Insufficient funds sent"
        );

        _mint(msg.sender, tokenId, quantity, "");
        tokenInfos[tokenId].remainingQuantity -= quantity;
        distributeSplits(artistId, msg.value);
    }

     function distributeSplits(uint256 _artistId, uint256 _amount) private {
        Split memory split = getSplit(artists[_artistId].splitType);
        uint256 artistShare = (_amount * split.artistPercentage) / 100;
        uint256 photoDistrictShare = (_amount * split.photoDistrictPercentage) /
            100;
        uint256 oneShare = (_amount * split.person1Percentage) / 100;
        uint256 twoShare = (_amount * split.person2Percentage) / 100;
        uint256 trunksShare = split.trunksUpPercentage > 0
            ? (_amount * split.trunksUpPercentage) / 100
            : 0;

        payable(artists[_artistId].artistAddress).transfer(artistShare);
        payable(photoDistrictAddress).transfer(photoDistrictShare);
        payable(personOneAddress).transfer(oneShare);
        payable(personTwoAddress).transfer(twoShare);

        if (split.trunksUpPercentage > 0) {
            payable(trunksUpAddress).transfer(trunksShare);
        }
    }

    function getSplit(uint256 _splitType) private pure returns (Split memory) {
        if (_splitType == 1) {
            return Split(40, 35, 15, 10, 0);
        } else if (_splitType == 2) {
            return Split(10, 10, 15, 10, 55);
        }
        return Split(40, 35, 15, 10, 0);
    }

    // Functions to update addresses with onlyOwner modifier
    function setPhotoDistrictAddress(address payable _newAddress)
        public
        onlyOwner
    {
        photoDistrictAddress = _newAddress;
    }

    function setPersonOneAddress(address payable _newAddress) public onlyOwner {
        personOneAddress = _newAddress;
    }

    function setPersonTwoAddress(address payable _newAddress) public onlyOwner {
        personTwoAddress = _newAddress;
    }

    function setTrunksUpAddress(address payable _newAddress) public onlyOwner {
        trunksUpAddress = _newAddress;
    }

    // Function to update the default price for an artist
    function updateArtistPrice(uint256 _artistId, uint256 _newPrice) public onlyOwner {
        require(_artistId < nextArtistId, "Invalid artist ID");
        artists[_artistId].defaultPrice = _newPrice;
    }

    // Function to update the address of an artist
    function updateArtistAddress(uint256 _artistId, address payable _newAddress) public onlyOwner {
        require(_artistId < nextArtistId, "Invalid artist ID");
        artists[_artistId].artistAddress = _newAddress;
    }

    function batchMint(uint256 startTokenId, uint256 quantity, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 currentTokenId = startTokenId + i;
            // Check if the token exists and has enough quantity left
            require(tokenInfos[currentTokenId].remainingQuantity >= quantity, "Not enough quantity left");
            _mint(msg.sender, currentTokenId, quantity, "");
            tokenInfos[currentTokenId].remainingQuantity -= quantity;
            // Additional logic if needed
        }
    }

    // Sets the base URI for all token types
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    
    function uri(uint256 typeId) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(typeId)))
                : baseURI;
    }
}
