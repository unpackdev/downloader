// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract PlanetMintPass is
  ERC721Enumerable,
  PaymentSplitter,
  Ownable,
  ReentrancyGuard
{
  uint256 currentId;
  string BASE_URI;
  uint256 MAX_SUPPLY = 10000;
  uint256 PRICE = 0.069 ether;

  mapping(address => bool) public admin;

  constructor(
    string memory baseUri,
    address[] memory payees,
    uint256[] memory shares
  ) ERC721("Planet Mint Pass", "") PaymentSplitter(payees, shares) {
    BASE_URI = baseUri;
    for (uint256 i; i < payees.length; i++) {
      admin[payees[i]] = true;
    }
  }

  event AdminUpdated(address adminAddress, bool value);

  function updateAdmin(address adminAddress, bool value) public onlyOwner {
    admin[adminAddress] = value;
    emit AdminUpdated(adminAddress, value);
  }

  modifier onlyAdmin() {
    require(admin[msg.sender] == true, "Not admin");
    _;
  }

  function release(address payable account) public override onlyAdmin {
    super.release(payable(account));
  }

  function withdraw() public onlyAdmin {
    for (uint256 i = 0; i < numberOfPayees(); i++) {
      release(payable(payee(i)));
    }
  }

  function mint(uint256 amount) public payable nonReentrant {
    require(amount > 0 && amount <= 10, "Max 10 per transaction");
    require(amount * PRICE == msg.value, "Incorrect value");
    require(currentId < MAX_SUPPLY, "All minted");
    require(
      currentId + amount <= MAX_SUPPLY,
      "Amount to mint greater than supply"
    );
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = ++currentId;
      _safeMint(msg.sender, tokenId);
    }
  }

  function setBaseUri(string memory baseUri) public onlyOwner {
    BASE_URI = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }
}
