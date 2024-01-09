pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

contract AzukiMfers is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  uint256 public constant teamReserveAmount  = 0;
  uint256 public constant totalAvailable   = 5000;
  
  uint256 public          maxPerTx        = 20;
  uint256 public          cost            = 0.009 ether;
  uint256 public          nextOwnerToExplicitlySet;
  string public           baseURI;

  bool public             isMintActive;

  constructor(
    address[] memory payees_,
    uint256[] memory shares_
  )
    ERC721A("Azuki mfers", "AZMF") 
    PaymentSplitter(payees_, shares_)
  {}

  function setCost(uint256 _newCost) external onlyOwner {
      cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
      maxPerTx = _newMaxMintAmount;
  }

  function flipMintState() external onlyOwner {
      isMintActive = !isMintActive;
  }

  function mint(uint256 quantity)
    external
    payable
  {
    require(isMintActive, "Mint is not active");
    require(
      msg.sender == tx.origin, 
      "Only sender can execute this transaction!"
    );
    
    require(
      quantity < maxPerTx + 1, 
      "Minted amount exceeds mint limit!"
    );

    require(
      totalSupply() + quantity < totalAvailable - teamReserveAmount + 1, 
      "SOLD OUT!"
    );


    require(
      msg.value == quantity * cost,
      "Need to send the exact amount!"
    );

    _safeMint(msg.sender, quantity);
  }

  function reserve(uint256 quantity) 
    external 
    onlyOwner    
  {
    require(
      totalSupply() + quantity < totalAvailable + 1, 
      "Not Enough supply to reserve"
    );
  
    _safeMint(msg.sender, quantity);
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
  

  /**
    * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
    */
  function _setOwnersExplicit(uint256 quantity) internal {
      require(quantity != 0, "quantity must be nonzero");
      require(currentIndex != 0, "no tokens minted yet");
      uint256 _nextOwnerToExplicitlySet = nextOwnerToExplicitlySet;
      require(_nextOwnerToExplicitlySet < currentIndex, "all ownerships have been set");

      // Index underflow is impossible.
      // Counter or index overflow is incredibly unrealistic.
      unchecked {
          uint256 endIndex = _nextOwnerToExplicitlySet + quantity - 1;

          // Set the end index to be the last token index
          if (endIndex + 1 > currentIndex) {
              endIndex = currentIndex - 1;
          }

          for (uint256 i = _nextOwnerToExplicitlySet; i <= endIndex; i++) {
              if (_ownerships[i].addr == address(0)) {
                  TokenOwnership memory ownership = ownershipOf(i);
                  _ownerships[i].addr = ownership.addr;
                  _ownerships[i].startTimestamp = ownership.startTimestamp;
              }
          }

          nextOwnerToExplicitlySet = endIndex + 1;
      }
  }
}