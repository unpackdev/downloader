// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFT is ERC721URIStorage, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  uint256 public constant MAX_NFT_SUPPLY = 10000;
  uint256 public constant NUM_RESERVED = 250;
  uint256 public constant MAX_NUM_MINT = 25;
  uint public MINT_PRICE = 60000000000000000 wei; // 0.06 ETH
  bool public SALE_IS_ACTIVE = false;
  uint public COUNT_RESERVED;
  string public baseUri = "ipfs://QmdPUgps7gRUArw8GVc1Tjk4hpXiTXocKgQuo1NktMYyUi/";
  address public PSA = 0xA90CbD83FFacde7Fe03839371d55b4A4450C1B55;
  
  constructor() ERC721("FinalTestNFT", "FTNFT") {
  }
  
  function changePSA(address newPSA) external onlyOwner {
    PSA = newPSA;
  }

  function flipSaleState() external onlyOwner {
    SALE_IS_ACTIVE = !SALE_IS_ACTIVE;
  }

  function mintVariableAmountOfTokens(address to, uint amount) external payable {
    require(SALE_IS_ACTIVE, "Tokensale is not active right now.");
    require(amount <= MAX_NUM_MINT, "Maximum number of mints per function call exceeded.");
    require(msg.value >= MINT_PRICE * amount, "Price was not paid in full.");
    require(_tokenIds.current() + amount <= MAX_NFT_SUPPLY - (NUM_RESERVED - COUNT_RESERVED), "Desired amount of Tokens exceeds the publicly available number of tokens.");
    for(uint i = 0; i < amount; i++){
      uint256 id = _tokenIds.current();
      _tokenIds.increment();
      string memory tokenURIcombined = string(abi.encodePacked(baseUri, UintToString(id),  ".json"));
      _safeMint(to, id);
      _setTokenURI(id, tokenURIcombined);
    }
  }

  function mintReservedByOwner(address to, uint amount) external onlyOwner {
    // mints the limited amount of Reserved Tokens by Team
    require(COUNT_RESERVED + amount <= NUM_RESERVED, "Not enough reserved tokens left for the provided input amount to be minted.");
    require(amount <= MAX_NUM_MINT, "Maximum number of mints per function call exceeded.");
    require(_tokenIds.current() + amount <= MAX_NFT_SUPPLY, "Your desired amount of Tokens exceeds the Maximum token supply.");
    for(uint i = 0; i < amount; i++){
      COUNT_RESERVED = COUNT_RESERVED + 1;
      uint256 id = _tokenIds.current();
      _tokenIds.increment();
      string memory tokenURIcombined = string(abi.encodePacked(baseUri, UintToString(id),  ".json"));
      _safeMint(to, id);
      _setTokenURI(id, tokenURIcombined);
    }
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
    _setTokenURI(tokenId, _tokenURI);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function tokensIndicesOfOwner(address _owner) external view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } 
    else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 indexCounter = 0;
      for (uint256 i = 0; i <= totalSupply() - 1; i++) {
        if (ownerOf(i) == _owner){
          result[indexCounter] = i;
          indexCounter += 1;
        }
      }
      return result;
    }
  }
  
  function totalSupply() public view returns(uint){
    return _tokenIds.current();
  }

  function UintToString(uint256 value) internal pure returns (string memory) {
    // utility function for the right tokenURI generation
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

  function withdrawFunds() public {
    payable(PSA).transfer(address(this).balance);
  }

}
