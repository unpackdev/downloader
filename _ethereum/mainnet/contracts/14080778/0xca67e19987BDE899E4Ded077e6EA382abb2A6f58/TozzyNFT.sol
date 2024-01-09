// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ERC721.sol";

contract TozzyNFT is ERC721("Tozzy NFT", "TFT") {

  // Using SafeMath for random index
  using SafeMath for uint256;

  // Base URL to external websites know what is token's metadata
  string public baseURI;

  // Booleans
  bool public isSaleActive;
  bool public isPreSaleActive;
  bool public isRevealed;

  // Base variables
  uint256 public circulatingSupply;
  address public owner = msg.sender;
  uint256 public itemPrice = 0.3 ether;
  uint256 public preSalePrice = 0.3 ether;
  uint256 public constant totalSupply = 10_000;
  uint256 public totalPreSaleReserved = 5_555;

  // Limits
  uint256 internal walletLimit = 3;

  mapping(address => bool) preSaleList;

  // Variables for random indexed tokens
  uint[totalSupply] internal indices;
  uint internal nonce = 0;
  
  //Minting and Pre-Minting tokens
  function mintTokens(uint256 _amount)
    external
    payable
    tokensAvailable(_amount)
  {
    require(
        isSaleActive,
        "Sale not started"
    );
    require(balanceOf(msg.sender) <= walletLimit);
    require(_amount > 0 && _amount <= walletLimit, "Mint min 1, max 3");
    require(msg.value >= _amount * itemPrice, "Try to send more ETH");

    for (uint256 i = 0; i < _amount; i++) {
      ++circulatingSupply;
      _safeMint(msg.sender, randomIndex());
    }
  }
  function preSaleMint(uint256 _amount) external payable
    tokensAvailable(_amount)
    preSaleStarted()
  {
    address minter = msg.sender;
    require(preSaleList[minter] == true, "Not allowed to pre mint");
    require(balanceOf(minter) <= walletLimit, "Mint min 1, max 3");
    require(totalPreSaleReserved - _amount > 0, "Pre sale sold out");
    require(msg.value >= _amount * preSalePrice, "Try to send more ETH");
    
    if(balanceOf(minter) + _amount == walletLimit) {
      preSaleList[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++circulatingSupply;
      --totalPreSaleReserved;
      _safeMint(minter, randomIndex());
    }
  }

  //QUERIES
  function _baseURI() internal view override returns (string memory) {
    return isRevealed ? baseURI : "";
  }
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), ".json"));
  }
  function tokensRemaining() public view returns (uint256) {
    return totalSupply - circulatingSupply;
  }
  //OWNER ONLY
  function addToPreSaleList(address[] calldata _preSaleMinters) external onlyOwner {
    for(uint256 i = 0; i < _preSaleMinters.length; i++)
      preSaleList[_preSaleMinters[i]] = true;
  }
  function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }
  
  function toggleSale() external onlyOwner {
    isSaleActive = !isSaleActive;
  }
  function togglePreSale() external onlyOwner {
    isPreSaleActive = !isPreSaleActive;
  }
  function toggleReveal() external onlyOwner {
    isRevealed = !isRevealed;
  }
  function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is a private function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function burn(
    uint256 _tokenId
  )
    external onlyOwner validNFToken(_tokenId)
  {
    _burn(_tokenId);
  }

  function randomIndex() internal returns (uint256) {
      uint256 totalSize = totalSupply - circulatingSupply;
      uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
      uint256 value = 0;

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

          return value.add(1);
  }

  //MODIFIERS
  modifier tokensAvailable(uint256 _amount) {
      require(_amount <= tokensRemaining(), "Try minting less tokens");
      _;
  }
  modifier preSaleStarted() {
    require(isPreSaleActive == true, "Pre-Minting is not started");
    _;
  }
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: Caller is not the owner");
    _;
  }
    /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(ownerOf(_tokenId) != address(0));
    _;
  }
}
