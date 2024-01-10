// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721ABurnable.sol";
import "./Base64.sol";
import "./IMaterialContract.sol";

contract BuildoorsHomes is Ownable, ERC721A, ERC721ABurnable {

    using Strings for uint256;

    uint256 newestHome;
    string private imageTokenURI;
    bool private unique;
    bool public saleIsActive;
    address materialsContract;

    // Mapping for type of home
    mapping(uint256 => string) private styleByHomeId;

    constructor() ERC721A("Buildoors Homes", "HOME") {}

    //
    // FUNCTIONS FOR VALIDATING
    //

    // Dirt has token IDs 666-998
    function dirtValidated(uint256 dirtId) internal view returns (bool) {
        IMaterialContract iMaterial = IMaterialContract(materialsContract);
        return((iMaterial.ownerOf(dirtId) == _msgSender()) && (dirtId > 665) && (dirtId < 999));
    }

    // Glue has token IDs 332-664
    function glueValidated(uint256 glueId) internal view returns (bool) {
        IMaterialContract iMaterial = IMaterialContract(materialsContract);
        return((iMaterial.ownerOf(glueId) == _msgSender()) && (glueId > 331) && (glueId < 665));
    }

    // Style materials have token IDs 1-331, or 665, or 999
    function styleValidated(uint256 styleId) internal view returns (bool) {
        IMaterialContract iMaterial = IMaterialContract(materialsContract);
        return((iMaterial.ownerOf(styleId) == _msgSender()) && ((styleId < 332) || (styleId == 665) || (styleId == 999)));
    }

    //
    // FUNCTIONS FOR GETTING METADATA
    //

    function getStyleOfHomeId(uint256 homeId) public view returns (string memory) {
        return styleByHomeId[homeId];
    }

    function getImageOfHomeId(uint256 homeId) public view returns (string memory) {
        if(unique){
            return string(abi.encodePacked(imageTokenURI, Strings.toString(homeId), ".png"));
        } else {
            return string(abi.encodePacked(imageTokenURI, styleByHomeId[homeId], ".png"));
        }
    }

    function getYieldOfHomeId(uint256 homeId) public view returns (string memory) {
        if(keccak256(bytes(styleByHomeId[homeId])) == keccak256(bytes("Straw"))){
            return "Low";
        } else if(keccak256(bytes(styleByHomeId[homeId])) == keccak256(bytes("Wood"))){
            return "Medium";
        } else if(keccak256(bytes(styleByHomeId[homeId])) == keccak256(bytes("Brick"))){
            return "High";
        } else {
            return "Extreme";
        }
    }

    function getStartTimestamp(uint256 homeId) public view returns (uint64) {
        return _ownerships[homeId].startTimestamp;
    }

    //
    // FUNCTION FOR MINTING
    //

    function mint(uint256 dirtId, uint256 glueId, uint256 styleId) external {
        require(
            saleIsActive,
            "Building is not active"
        );
        require(
            tx.origin == _msgSender(),
            "Not allowing contracts"
        );
        require(
            dirtValidated(dirtId),
            "You do not have dirt"
        );
        require(
            glueValidated(glueId),
            "You do not have glue"
        );
        require(
            styleValidated(styleId),
            "You do not have gold, bricks, sticks, or straw"
        );

        IMaterialContract iMaterial = IMaterialContract(materialsContract);
        iMaterial.burn(dirtId);
        iMaterial.burn(glueId);
        iMaterial.burn(styleId);

        if(styleId > 5 && styleId < 189) {
            // Straw has token IDs 6-188
            _safeMint(_msgSender(), 1);
            newestHome++;
            styleByHomeId[newestHome] = "Straw";
        } else if(styleId > 240 && styleId < 331) {
            // Sticks has token IDs 241-330
            _safeMint(_msgSender(), 1);
            newestHome++;
            styleByHomeId[newestHome] = "Wood";
        } else if(styleId > 189 && styleId < 240) {
            // Bricks has token IDs 190-239
            _safeMint(_msgSender(), 1);
            newestHome++;
            styleByHomeId[newestHome] = "Brick";
        } else {
            // Gold has other token IDs
            _safeMint(_msgSender(), 1);
            newestHome++;
            styleByHomeId[newestHome] = "Gold";
        }
    }

    //
    // FUNCTIONS FOR OVERRIDING
    //

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Home #',
            Strings.toString(tokenId),
            '", "description": "A beautiful home created by a Buildoor.", "external_url": "https://www.buildoors.org", "image": "',
            getImageOfHomeId(tokenId),
            '", "attributes":[{"trait_type": "Style", "value": "',
            getStyleOfHomeId(tokenId),
            '"}, {"trait_type": "Yield", "value": "',
            getYieldOfHomeId(tokenId),
            '"}]}'
        ))));

        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    //
    // FUNCTIONS FOR OWNER
    //

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipUniqueState() external onlyOwner {
        unique = !unique;
    }

    function setImageURI(string calldata imageURI) external onlyOwner {
        imageTokenURI = imageURI;
    }

    function setMaterialsAddress(address contractAddress) external onlyOwner {
        materialsContract = contractAddress;
    }
}
