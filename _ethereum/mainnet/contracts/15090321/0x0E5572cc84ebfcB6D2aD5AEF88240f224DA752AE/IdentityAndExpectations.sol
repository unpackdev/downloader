// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ERC2981.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./LibRoyaltiesV2.sol";
import "./ERC721.sol";
import "./RaribleRoyaltyV2.sol";

contract IdentityAndExpectations is ERC721, Pausable, RaribleRoyaltyV2, Ownable {
  using Strings for uint256;

  event Sale(uint256 indexed tokenId, address indexed to, uint256 indexed price, uint256 timestamp);
  event Withdrawal(address indexed to, uint256 indexed amount, uint256 indexed timestamp);

  uint256 private constant PRINT_SUPPLY = 20;
  uint256 private constant ORIGINALS_COUNT = 5;
  uint256 private constant MAX_SUPPLY = 105;

  uint256 public oneOfOnePrice = 1.85 ether;
  uint256 public oneOfTwentyPrice = 0.185 ether;

  address public withdrawWallet = 0x46AdB53F4DAc76422c618304Eb39E7b5f2d26bae;
  address public royaltyReceiver = 0x65Ce391F03833434B1D50A2E9bD5401790e66e8D;

  //  Tangled = 0;
  //  Brave = 1;
  //  Clockwork = 2;
  //  Poetry in Motion 2 = 3;
  //  Dinner is Served = 4;
  mapping(uint256 => uint256) private printSupply;

  uint256 private _totalSupply;

  constructor() ERC721("IdentityAndExpectations", "RSIE") {
    _setDefaultRoyalty(royaltyReceiver, 800);
    _setBaseURI("https://ipfs.idea.tf/ipfs/QmY5FuYbFLEHMXQ6qbXp69CwWwwYxPURUjbo1ED9F7iAzU/");

    _pause();
  }

  function _getNextId(uint256 editionId) internal view returns(uint256) {
    return ORIGINALS_COUNT + editionId * 20 + printSupply[editionId] + 1;
  }

   function rareFreeMint(uint256 tokenId, address winner) public onlyOwner whenNotPaused {
    require(tokenId <= ORIGINALS_COUNT && tokenId > 0, "tokenId must be between 1 and 5");
    require(_owners[tokenId] == address(0), "That token was already minted");
    _totalSupply++;
    _safeMint(winner, tokenId);
  }

  function freeMint(uint256 editionId, address winner) public onlyOwner whenNotPaused {
    require(editionId < ORIGINALS_COUNT, "That edition doesn't exist");
    require(printSupply[editionId] <= PRINT_SUPPLY, "That edition was minted out");

    uint256 tokenId = _getNextId(editionId);
    printSupply[editionId]++;

    _totalSupply++;
    _safeMint(winner, tokenId);
  }

  function rareMint(uint256 tokenId) public payable whenNotPaused {
    require(tokenId <= ORIGINALS_COUNT && tokenId > 0, "tokenId must be between 1 and 5");
    require(_owners[tokenId] == address(0), "That token was already minted");
    require(msg.value == oneOfOnePrice, "You must send the right amount");

    _totalSupply++;
    _safeMint(msg.sender, tokenId);
    emit Sale(tokenId, msg.sender, msg.value, block.timestamp);
  }

  function mint(uint256 editionId) public payable whenNotPaused {
    require(editionId < ORIGINALS_COUNT, "That edition doesn't exist");
    require(printSupply[editionId] < PRINT_SUPPLY, "That edition was minted out");
    require(msg.value == oneOfTwentyPrice, "You must send the right amount");
    uint256 tokenId = _getNextId(editionId);
    printSupply[editionId]++;

    _totalSupply++;
    _safeMint(msg.sender, tokenId);
    emit Sale(tokenId, msg.sender, msg.value, block.timestamp);
  }

  function setRoyalties(address receiver, uint96 part) public onlyOwner {
    _setDefaultRoyalty(receiver, part);
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  internal
  override(ERC721)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function isAvailable(uint256 tokenId) public view returns (bool) {
    require(tokenId > 0 && tokenId < MAX_SUPPLY, "That token doesn't exist");
    return (_owners[tokenId] == address(0));
  }

  function remainingSupply(uint256 editionId) public view returns (uint256) {
    require(editionId < 5, "That edition doesn't exist");
    return PRINT_SUPPLY - printSupply[editionId];
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
  }

  function setWithdrawWallet(address _wallet) public onlyOwner {
    withdrawWallet = _wallet;
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC721, RaribleRoyaltyV2)
  returns (bool)
  {
    if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setBaseURI(string memory _uri) public onlyOwner {
    _setBaseURI(_uri);
  }

  function setMintingPrices(uint256 _oneOfOne, uint256 _oneOfTwenty) public onlyOwner {
    oneOfOnePrice = _oneOfOne;
    oneOfTwentyPrice = _oneOfTwenty;
  }

  function withdraw() public {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to withdraw");
    (bool success, ) = withdrawWallet.call{value: balance}("");
    require(success, "Could not process payment");
    emit Withdrawal(withdrawWallet, balance, block.timestamp);
  }
}
