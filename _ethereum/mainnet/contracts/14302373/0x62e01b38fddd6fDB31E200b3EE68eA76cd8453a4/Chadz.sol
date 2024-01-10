//
//     _,.----.  ,--.-,,-,--,   ,---.
//   .' .' -   \/==/  /|=|  | .--.'  \      _,..---._   ,--,----.
//  /==/  ,  ,-'|==|_ ||=|, | \==\-/\ \   /==/,   -  \ /==/` - ./
//  |==|-   |  .|==| ,|/=| _| /==/-|_\ |  |==|   _   _\`--`=/. /
//  |==|_   `-' \==|- `-' _ | \==\,   - \ |==|  .=.   | /==/- /
//  |==|   _  , |==|  _     | /==/ -   ,| |==|,|   | -|/==/- /-.
//  \==\.       /==|   .-. ,\/==/-  /\ - \|==|  '='   /==/, `--`\
//   `-.`.___.-'/==/, //=/  |\==\ _.\=\.-'|==|-,   _`/\==\-  -, |
//              `--`-' `-`--` `--`        `-.`.____.'  `--`.-.--`
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";

contract Chadz is ERC721, Ownable {
  uint256 public totalSupply;
  uint16 immutable public maxSupply = 4200;

  string public baseURI;
  string public baseURI_EXT;
  bool public releaseChadz  = false;
  // Constants
  uint256 public constant cost = 0.042 ether;
  uint256 public constant maxMintAmount = 10;
  address constant chad1 = 0xae1911A64ec808B1A45723Dcc820D22fc1b4DFfd;
  address constant chad2 = 0x6e1DAfA38a882c38012b41e38D79E9CA89787C5C;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {}

  // Events
  event Mint(address to_, uint256 tokenId_);

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  function __getTokenId() internal view returns (uint256) {
      return totalSupply + 1;
  }

  function mintChad(uint256 _mintAmount) public payable {
    require(releaseChadz, "Chadz are still at the gym");
    require(_mintAmount > 0, "Quantity cannot be zero");
    require(_mintAmount <= maxMintAmount, "Exceeds the max quantity per mint");
    require(totalSupply + _mintAmount <= maxSupply, "Not enough Chadz left");
    require(msg.value >= cost * _mintAmount, "Ether value sent is below the price");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _mint(msg.sender, __getTokenId());
      emit Mint(msg.sender, __getTokenId());
      totalSupply++;
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseURI_EXT))
        : "";
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseURI_EXT = _newBaseExtension;
  }

  function enableMint(bool _state) public onlyOwner {
    releaseChadz = _state;
  }

  function withdraw() public payable onlyOwner {
    // Chad1 50%
    (bool sm, ) = payable(chad1).call{value: address(this).balance * 500 / 1000}("");
    require(sm);

    // Chad2 50%
    (bool os, ) = payable(chad2).call{value: address(this).balance}("");
    require(os);
  }
}
