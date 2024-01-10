// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "ERC721A.sol";

contract INVSBLEPUNKS is ERC721A, Ownable {
  enum Status {
    Waiting,
    Started,
    Finished
  }

  Status public status;
  string public baseURI;
  uint256 public constant MAX_MINT_PER_ADDR = 10;
  uint256 public constant MAX_SUPPLY = 5555;
  uint256 public constant PRICE = 0.005 ether;

  event Minted(address minter, uint256 amount);
  event StatusChanged(Status status);
  event BaseURIChanged(string newBaseURI);

  constructor(string memory initBaseURI) ERC721A("Invisiable Punks", "INVSBLEPUNKS") {
    baseURI = initBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 quantity) external payable {
    require(status == Status.Started, "The contract is paused!");
    require(tx.origin == msg.sender, "The contract called!");
    require(
      numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
      "Exceed Max minted"
    );
    require(totalSupply() + quantity <= MAX_SUPPLY, "Solded Out!");

    _safeMint(msg.sender, quantity);
    refundIfOver(PRICE * quantity);

    emit Minted(msg.sender, quantity);
  }

  function mintForAddress(uint256 quantity, address _receiver) external payable onlyOwner {
    require(status == Status.Started, "The contract is paused!");
    require(tx.origin == msg.sender, "The contract called!");
    require(
      numberMinted(_receiver) + quantity <= MAX_MINT_PER_ADDR,
      "Exceed Max minted"
    );
    require(totalSupply() + quantity <= MAX_SUPPLY, "Solded Out!");

    _safeMint(_receiver, quantity);
    refundIfOver(PRICE * quantity);
    emit Minted(_receiver, quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Insufficient balance!");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function setStatus(Status _status) external onlyOwner {
    status = _status;
    emit StatusChanged(status);
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
    emit BaseURIChanged(newBaseURI);
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Withdraw failed!");
  }
}