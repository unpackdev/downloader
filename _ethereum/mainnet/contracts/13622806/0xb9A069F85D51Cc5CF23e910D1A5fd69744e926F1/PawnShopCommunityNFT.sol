//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./base64.sol";

import "./ImageAndDescription.sol";

contract PawnShopCommunityNFT is ERC721Enumerable, Ownable {
    uint256 private _tokenCount;
    uint256 private _typeCount;
    mapping(uint256 => uint256) public tokenType;
    mapping(uint256 => address) public imageAndDescriptionContractForType;


    constructor(address _owner) ERC721("Pawn Shop Community NFT", "PSCNFT") {
        transferOwnership(_owner);
    }

    function mint(uint256 _tokenType, address to) public onlyOwner {
        require(_tokenType <= _typeCount, "Invalid type");

        _safeMint(to, ++_tokenCount);
        tokenType[_tokenCount] = _tokenType;
    }

    function batchMint(uint256 _tokenType, address[] calldata accounts) external {
        for (uint i; i < accounts.length; i++) {
            mint(_tokenType, accounts[i]);
        }
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        require(_exists(tokenId), "token does not exist");

        address imageAndDescriptionContract = imageAndDescriptionContractForType[
            tokenType[tokenId]
            ];
        string memory image = ImageAndDescription(imageAndDescriptionContract).image(tokenId);
        string memory description = ImageAndDescription(imageAndDescriptionContract).description(tokenId);

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"#',
                                    Strings.toString(tokenId),
                                    '", "description":"',
                                    description, 
                                    '", "image": "'
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(bytes(image)),
                                    '"}'
                                )
                            )
                        )
                    )  
                );
    }

    function addTokenType(address _imageAndDescription) external onlyOwner {
        require(_imageAndDescription != address(0), "Invalid address");

        imageAndDescriptionContractForType[++_typeCount] = _imageAndDescription;
    }
}
