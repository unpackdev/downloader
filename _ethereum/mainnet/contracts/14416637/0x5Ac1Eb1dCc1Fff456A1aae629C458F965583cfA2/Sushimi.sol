// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ISushimiToken.sol";

contract Sushimi is ERC721Enumerable, Ownable {
  uint16 private remainingIDsLength = 10000;
  uint16[10000] private remainingIDs;

  string public baseURI;
  address public sushimiToken;

  constructor(string memory _baseURI, address _sushimiToken) ERC721("Sushimi", "SUSH") {
    baseURI = _baseURI;
    sushimiToken = _sushimiToken;
  }

  // Set base URI, ownership will be renounced after IPFS migration
  function setBaseURI(string calldata _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  // Returns the token's tokenURI
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    if(!_exists(_tokenId)) return "";
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
  }

  // Generates a random index from the remaining pool
  function _getRandomID() private returns (uint16 number) {
    uint16 _remainingIDsLength = remainingIDsLength;
    uint16 index = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number-1), block.timestamp))) % _remainingIDsLength);

    number = remainingIDs[index];
    if(number == 0) {
        number = index;
    }
    uint16 lastNumber = remainingIDs[_remainingIDsLength-1];
    if(lastNumber == 0) {
        lastNumber = _remainingIDsLength-1;
    }
    remainingIDs[index] = lastNumber;
    remainingIDsLength = _remainingIDsLength - 1;
  }

  // Mint Sushimis
  function mint(uint _amount) external {
    require(tx.origin == msg.sender, "Only EOAs.");

    ISushimiToken(sushimiToken).burnFrom(msg.sender, _amount * 1e18);
    
    for(uint i = 0; i < _amount; i++) {
      uint mintIndex = _getRandomID();
      _safeMint(msg.sender, mintIndex);
    }
  }
}