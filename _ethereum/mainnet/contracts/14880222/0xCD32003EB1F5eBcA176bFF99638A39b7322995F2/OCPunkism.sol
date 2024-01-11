// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "./Ownable.sol";
import "./Strings.sol";

import "./base64.sol";
import "./ERC721.sol";

import "./SSTORE2.sol";
import "./DynamicBuffer.sol";

import "./console.sol";

contract OCPunkism is ERC721 {
  using Strings for uint256;
  
  struct Token {
      string name;
      string externalUrl;
      address descriptionPointer;
      address imageDataPointer;
      uint64 createdAt;
  }
  
  uint256 public currentTokenId;
  uint256 public burnCounter;
    
  mapping(uint => Token) public idToToken;
  
  string public contractDescription;
  function setContractDescription(string memory _contractDescription) external onlyOwner {
      contractDescription = _contractDescription;
  }
  
  string public contractExternalURL;
  function setContractExternalURL(string memory _contractExternalURL) external onlyOwner {
      contractExternalURL = _contractExternalURL;
  }
  
  address public contractImageDataPointer;
  function setContractImageDataPointer(string memory contractImageData) external onlyOwner {
      contractImageDataPointer = SSTORE2.write(bytes(contractImageData));
  }
  
  address public immutable owner;
  
  modifier onlyOwner() {
      require(owner == msg.sender, "Caller is not the owner");
      _;
  }

  constructor(
    address _creator,
    string memory _name,
    string memory _symbol,
    string memory _contractDescription,
    string memory _contractExternalUrl,
    string memory _contractImageData
  ) ERC721(_name, _symbol) {
    owner = _creator;
    contractDescription = _contractDescription;
    contractExternalURL = _contractExternalUrl;
    contractImageDataPointer = SSTORE2.write(bytes(_contractImageData));
  }

  function mint(
    string memory name,
    string memory description,
    string memory imageData,
    string memory externalURL
  ) external onlyOwner {
    require(bytes(name).length > 0);
    require(bytes(imageData).length > 0);
    
    unchecked { ++currentTokenId; }
    _mint(msg.sender, currentTokenId);
    
    Token memory token = Token(
      name,
      externalURL,
      SSTORE2.write(bytes(description)),
      SSTORE2.write(bytes(imageData)),
      uint64(block.timestamp)
    );
    
    idToToken[currentTokenId] = token;
  }
  
  function burn(uint256 tokenId) external onlyOwner {
    require(ownerOf(tokenId) == owner, "Caller is not owner");
    
    _burn(tokenId);
    unchecked { ++burnCounter; }
    delete idToToken[tokenId];
  }

  function totalSupply() public view returns (uint) {
    unchecked {
      return currentTokenId - burnCounter;
    }
  }
  
  function contractURI() public view returns (string memory) {
    bytes memory descriptionBytes = SSTORE2.read(contractImageDataPointer);

    return
        string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"', name(), '",'
                            '"description":"', contractDescription, '",'
                            '"image":"data:image/svg+xml;base64,', Base64.encode(descriptionBytes), '",'
                            '"external_link":"', contractExternalURL, '"'
                            '}'
                        )
                    )
                )
            )
        );
  }
  
  function tokenURI(uint tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "Token does not exist");

      return constructTokenURI(tokenId);
  }
  
  function constructTokenURI(uint tokenId) private view returns (string memory) {
    Token memory token = idToToken[tokenId];
    
    bytes memory svgBytes = SSTORE2.read(token.imageDataPointer);
    bytes memory descriptionBytes = SSTORE2.read(token.descriptionPointer);
    
      return
          string(
              abi.encodePacked(
                  "data:application/json;base64,",
                  Base64.encode(
                      bytes(
                          abi.encodePacked(
                              '{',
                              '"name":', token.name, ','
                              '"description":', descriptionBytes, ','
                              '"image_data":"data:image/svg+xml;base64,', Base64.encode(svgBytes), '",'
                              '"external_url":', token.externalUrl, ','
                                  '"attributes": [',
                                      '{',
                                          '"trait_type": "Mint Time",',
                                          '"display_type": "date",',
                                          '"value": "', uint(token.createdAt).toString(), '"',
                                      '},'
                                      '{',
                                          '"trait_type": "Image Size",',
                                          '"value":', svgBytes.length.toString(),
                                      '}'
                                  ']'
                              '}'
                          )
                      )
                  )
              )
          );
  }
}
