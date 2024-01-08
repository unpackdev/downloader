// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 *__/\\\\\\\\\\\\\_________/\\\\\_______/\\\\\\\\\\\\\\\_
 *_\/\\\/////////\\\_____/\\\///\\\____\///////\\\/////__
 *__\/\\\_______\/\\\___/\\\/__\///\\\________\/\\\______
 *___\/\\\\\\\\\\\\\\___/\\\______\//\\\_______\/\\\_____
 *____\/\\\/////////\\\_\/\\\_______\/\\\_______\/\\\____
 *_____\/\\\_______\/\\\_\//\\\______/\\\________\/\\\___
 *______\/\\\_______\/\\\__\///\\\__/\\\__________\/\\\__
 *_______\/\\\\\\\\\\\\\/_____\///\\\\\/___________\/\\\_
 *________\/////////////_________\/////_____________\///_
 */
contract BionicOutlierTribe is ERC721, Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  /**
   * @dev Constants
   */

  uint public constant TOKEN_LIMIT = 10000;
  uint private constant GIVEAWAY_LIMIT = 50;
  uint256 public constant MINT_PRICE = 100000000000000000; // 0.1 ETH
  uint public constant MAX_MINT_QUANTITY = 20;

  /**
   * @dev Addresses
   */

  address payable constant public devWallet = payable(0x296dd01060847FdaEbecB142a0f36aa86f874484);
  address payable constant public creatorWallet = payable(0xf331AFba4179FBfEA8464f69e69ea7Fa4cF37474);
  address payable constant public creativeWallet = payable(0x8f035fd5fa1fdc6639f7cD5301c7AdAA0c24DbC6);

  /**
   * @dev Variables
   */

  bool public isSaleActive = false;
  bool public hasPresaleStarted = false;
  bool private URISet = false;
  uint private nonce = 0;
  uint[TOKEN_LIMIT] private indices;
  mapping(address => uint) private presaleAllowance;

  constructor() ERC721("BionicOutlierTribe", "BOT") {}

  /**
   * General usage
   */

  function randomIndex() private returns (uint) {
      uint totalSize = TOKEN_LIMIT - totalSupply();
      uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
      uint value = 0;
      if (indices[index] != 0) {
          value = indices[index];
      } else {
          value = index;
      }

      if (indices[totalSize - 1] == 0) {
          indices[index] = totalSize - 1;
      } else {
          indices[index] = indices[totalSize - 1];
      }

      nonce++;
      return value;
  }

  function listTokensForOwner(address _owner) external view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index;
        for (index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }
  }

  function mintTokens(uint256 _numTokens) external payable nonReentrant {
    require(isSaleActive, "Sale is not active");
    require(_numTokens > 0 && _numTokens <= MAX_MINT_QUANTITY, "You can only mint 1 to 20 tokens at a time");
    require(totalSupply().add(_numTokens) <= TOKEN_LIMIT, "BOT has sold out");
    uint256 totalPrice = MINT_PRICE.mul(_numTokens);
    require(msg.value >= totalPrice, "Ether value sent is below the price");

    uint id;
    for (uint i = 0; i < _numTokens; i++) {
        id = randomIndex();
        _safeMint(msg.sender, id);
    }
  }

  function hasPresaleAllowance(address _minter) external view returns(bool) {
    return presaleAllowance[_minter] > 0;
  }

  function presaleAllowanceForAddress(address _minter) external view returns(uint) {
    return presaleAllowance[_minter];
  }

  function mintPresaleTokens(uint256 _numTokens) external payable nonReentrant {
    require(hasPresaleStarted, "Presale hasn't started");
    require(!isSaleActive, "Sale is active");
    require(_numTokens > 0 && _numTokens <= presaleAllowance[msg.sender], "You are not eligible to early mint that many tokens");
    require(totalSupply().add(_numTokens) <= TOKEN_LIMIT, "BOT has sold out");
    uint256 totalPrice = MINT_PRICE.mul(_numTokens);
    require(msg.value >= totalPrice, "Ether value sent is below the price");

    uint id;
    for (uint i = 0; i < _numTokens; i++) {
        id = randomIndex();
        presaleAllowance[msg.sender]--;
        _safeMint(msg.sender, id);
    }
  }

  /**
   * Owner only
   */

   function editPresaleAllowance(address[] memory _addresses, uint256 _amount) public onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
            presaleAllowance[_addresses[i]] = _amount;
        }
    }

  function setBaseURI(string memory _baseURI) external onlyOwner {
      _setBaseURI(_baseURI);
      URISet = true;
  }

  function reserveTokens(uint256 _numTokens) external onlyOwner {
    require(!isSaleActive, "Sale is active");
    require(!hasPresaleStarted, "Presale has already started");
    require(URISet, "URI not set");
    require(totalSupply().add(_numTokens) <= GIVEAWAY_LIMIT, "Exceeded giveaway supply");
    uint id;
    uint i;
    for (i = 0; i < _numTokens; i++) {
        id = randomIndex();
        _safeMint(creatorWallet, id);
    }
  }

  function startPresale() external onlyOwner {
    require(URISet, "URI not set");
    hasPresaleStarted = true;
  }

  function startSale() external onlyOwner {
    require(hasPresaleStarted, "Presale hasn't started");
    isSaleActive = true;
  }

  function pauseSale() external onlyOwner {
    isSaleActive = false;
  }

  function withdraw() external onlyOwner {
    uint256 creativeAmount = address(this).balance.mul(500).div(1000); // 50.0%
    uint256 creatorAmount = address(this).balance.mul(425).div(1000); // 42.5%
    uint256 devAmount = address(this).balance.mul(75).div(1000); // 7.5%
    creativeWallet.transfer(creativeAmount);
    creatorWallet.transfer(creatorAmount);
    devWallet.transfer(devAmount);
  }
}
