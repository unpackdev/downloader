// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*
  ___    ___    ___  _____ 
 / _ \  / _ \  / _ \|  __ \
/ /_\ \/ /_\ \/ /_\ \ |  \/
|  _  ||  _  ||  _  | | __ 
| | | || | | || | | | |_\ \
\_| |_/\_| |_/\_| |_/\____/

*/
import "./Ownable.sol";
import "./ERC721A.sol";

contract AAAG is ERC721A, Ownable {
  enum Status {
    Pending,
    PublicSale,
    Finished
  }

  Status public status;
  string public baseURI;
  uint256 public constant MAX_MINT_PER_ADDR = 10;
  uint256 public constant MAX_SUPPLY = 2022;
  uint256 public aaagPrice = 0.01 * 10**18; // 0.01 ETH

  event Minted(address minter, uint256 amount);
  event StatusChanged(Status status);
  event BaseURIChanged(string newBaseURI);

  constructor(string memory initBaseURI) ERC721A("Animation Animation Actress Girl", "AAAG") {
    baseURI = initBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 quantity) external payable {
    require(status == Status.PublicSale, "sale has not started yet");
    require(tx.origin == msg.sender, "EOA only");
    require(
      numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
      "can not mint this many"
    );
    require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");

    _safeMint(msg.sender, quantity);
    refundIfOver(aaagPrice * quantity);

    emit Minted(msg.sender, quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function setStatus(Status _status) external onlyOwner {
    status = _status;
    emit StatusChanged(status);
  }

  function setPrice(uint256 newPrice)public onlyOwner{
    aaagPrice = newPrice;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
    emit BaseURIChanged(newBaseURI);
  }

  function withdraw(address payable recipient) external onlyOwner {
    uint256 balance = address(this).balance;
    (bool success, ) = recipient.call{value: balance}("");
    require(success, "Transfer failed.");
  }
}