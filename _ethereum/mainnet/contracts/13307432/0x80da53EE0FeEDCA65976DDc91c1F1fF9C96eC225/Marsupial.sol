// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract Marsupial is Ownable, ERC721URIStorage, ERC721Enumerable {
  using Counters for Counters.Counter;

  modifier tokensLeft(uint number) {
    require(
      _totalSupply() < MAX_TICKETS - OWNER_ALLOCATION,
      "No more tickets left"
    );
    require(
      _totalSupply() + number <= MAX_TICKETS - OWNER_ALLOCATION,
      "Sale would exceed max supply"
    );
    _;
  }

  modifier ownerTokensLeft(uint number) {
    require(
      redeemedByOwner < OWNER_ALLOCATION,
      "Owner limit reached"
    );
    require(
      redeemedByOwner + number <= OWNER_ALLOCATION,
      "Sale would exceed owner limit"
    );
    _;
  }

  modifier saleIsActive {
    require(saleActive, "Sale not active");
    _;
  }

  Counters.Counter private _tokenIds;
  string private _baseURIextended;

  uint public MAX_TICKETS;
  uint public OWNER_ALLOCATION;
  uint public TICKET_PRICE = 0.06 ether;
  uint public mintedTokens;
  uint public redeemedByOwner = 0;
  bool public saleActive = false;

  event TicketMinted(address payer, address recipient);

  constructor(uint maxTickets, uint ownerAllocation) ERC721("Marsupial Madness", "MSPL") {
    _baseURIextended = "https://ipfs.io/ipfs/QmZ2n4FdBKuxiHAs1eAUcbSQGaDbMeStpfvZJmsw5xJKWp/";
    MAX_TICKETS = maxTickets;
    OWNER_ALLOCATION = ownerAllocation;
  }

  function updateBaseUri(string memory baseURIExtended) external onlyOwner {
    _baseURIextended = baseURIExtended;
  }

  function toggleSaleState() external onlyOwner {
    saleActive = !saleActive;
  }

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _totalSupply() public view returns (uint) {
    return _tokenIds.current();
  }

  function mint(address recipient, uint number) private tokensLeft(number) {
    require(number >= 1, "Invalid mint amount");
    for (uint i = 0; i < number; i++) {
      uint id = _totalSupply() + 1;
      _safeMint(recipient, id);
      _tokenIds.increment();
      mintedTokens = _totalSupply();
      emit TicketMinted(msg.sender, recipient);
    }
  }

  function buyFor(address recipient, uint number) public payable saleIsActive {
    require(msg.value == number * TICKET_PRICE, "Invalid mint price");
    mint(recipient, number);
  }

  function buy(uint number) external payable saleIsActive {
    buyFor(msg.sender, number);
  }

  function ownerBuy(address recipient, uint number) external onlyOwner ownerTokensLeft(number)  {
    redeemedByOwner += number;
    mint(recipient, number);
  }

  function tokensOfOwner(address owner)
    public
    view
    returns (uint[] memory)
  {
    uint tokenCount = balanceOf(owner);
    uint[] memory tokenIds = new uint[](tokenCount);
    for (uint i = 0; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }

  // OVERRIDES

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint tokenId)
    internal
    override(ERC721, ERC721URIStorage)
  {
    super._burn(tokenId);
  }

  function tokenURI(uint tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}