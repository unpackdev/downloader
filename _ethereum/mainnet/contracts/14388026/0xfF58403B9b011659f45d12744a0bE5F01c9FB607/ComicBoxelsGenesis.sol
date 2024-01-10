//SPDX-License-Identifier: MIT
/*
 ██████  ██████  ███    ███ ██  ██████ ██████   ██████  ██   ██ ███████ ██      ███████ 
██      ██    ██ ████  ████ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██      ██      
██      ██    ██ ██ ████ ██ ██ ██      ██████  ██    ██   ███   █████   ██      ███████ 
██      ██    ██ ██  ██  ██ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██           ██ 
 ██████  ██████  ██      ██ ██  ██████ ██████   ██████  ██   ██ ███████ ███████ ███████ 
*/                                                                           
pragma solidity ^0.8.11;           
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ComicBoxelsGenesis is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  enum PERIOD {
    PRE_LAUNCH,
    PRE_SALE,
    OPEN_SALE
  }

  //uris
  string private __baseURI = "";
  string private _contractURI = "";
  string private _placeholderURI = "";
  //token properties
  uint256 public immutable price;
  bool public revealed = false;
  PERIOD public mintPeriod;
  //limits
  uint16 public boxelsLeft;
  uint8 public maxBatchSize;
  uint8 public maxPerUser;
  uint16 public immutable reserveAmount;

  error MintBeforeLaunch();
  error MintMoreThanMaxSupply(uint16 left);
  error MintMoreThanMaxPerUser(uint16 limit, uint16 owned, uint16 triedToMint);
  error MintMoreThanBatchSize(uint16 limit);
  error InsufficientPayment(uint256 sent, uint256 expected);
  error WrongPeriod();

  event TokenRevealed();
  event PeriodChanged(PERIOD period);
  
  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    string memory contractURI_,
    string memory placeholderURI_,
    uint256 price_,
    uint16 maxSupply_
  ) ERC721A(name_, symbol_) {
    __baseURI = baseURI_;
    _contractURI = contractURI_;
    _placeholderURI = placeholderURI_;
    price = price_;
    setMintPeriod(PERIOD.PRE_LAUNCH);
    reserveAmount = preAllocate();
    boxelsLeft = maxSupply_ - reserveAmount;
  }

  /// @dev first token index starts at 1
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
    * @dev mint quantity tokens
    * _safeMint's second argument now takes in a quantity, not a tokenId
    * Prevents minting if:
    * 1. trying to mint pre launch
    * 2. trying to mint more than max batch size tokens at a time
    * 3. Trying to mint more than the max allowed per user
    * 4. going over the max supply
    * 5. not sending enough ETH
    */
  function mint(uint16 quantity) external payable {
    if(mintPeriod == PERIOD.PRE_LAUNCH) revert MintBeforeLaunch();
    if(quantity > maxBatchSize && msg.sender != owner()) revert MintMoreThanBatchSize({limit: maxBatchSize});
    if(boxelsLeft == 0 || (boxelsLeft > 0 && boxelsLeft < quantity)) revert MintMoreThanMaxSupply({left: boxelsLeft});
    uint8 tokensOwned = uint8(_numberMinted(msg.sender));
    if(tokensOwned + quantity > maxPerUser && msg.sender != owner()) revert MintMoreThanMaxPerUser({limit: maxPerUser, owned: tokensOwned, triedToMint: quantity});
    uint256 totalPrice = msg.sender != owner() ? quantity * price : 0.0;
    if(msg.value < totalPrice) revert InsufficientPayment({sent: msg.value, expected: totalPrice});

    _safeMint(msg.sender, quantity);
    unchecked {
      if(boxelsLeft - quantity >= 0) {
        boxelsLeft -= quantity;
      }
      else {
        boxelsLeft = 0;
      }
    }
    //emits a Transfer event for every token minted
  }

  /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
  /// @dev avoid implementing if totalSupply >= 10,000
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
      uint256[] memory a = new uint256[](balanceOf(owner)); 
      uint256 end = _currentIndex;
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      for (uint256 i; i < end; i++) {
        TokenOwnership memory ownership = _ownerships[i];
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          a[tokenIdsIdx++] = i;
        }
      }
      return a;    
    }
  }

  /// @dev burn a token
  function burn(uint256 tokenId) override public {
    ERC721ABurnable.burn(tokenId);
    //emits Transfer to 0x0
  }

  /***    URI functions  ***/
  function baseURI() public view returns (string memory) {
    return __baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function placeholderURI() public view returns (string memory) {
    return _placeholderURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    if(revealed) {
      return bytes(__baseURI).length != 0 ? string(abi.encodePacked(__baseURI, tokenId.toString(), '.json')) : '';
    }
    else {
      return bytes(_placeholderURI).length != 0 ? _placeholderURI : '';
    }
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    __baseURI = baseURI_;
  }

  function setContractURI(string memory contractURI_) public onlyOwner {
    _contractURI = contractURI_;
  }

  function setPlaceholderURI(string memory placeholderURI_) public onlyOwner {
    _placeholderURI = placeholderURI_;
  }

  /***  Owner only functions ***/
  function withdraw() external nonReentrant onlyOwner {
    uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
  }

  /// @dev set mint period and token mint limits
  function setMintPeriod(PERIOD period_) public onlyOwner {
    if(period_ == PERIOD.PRE_LAUNCH) {
      maxBatchSize = 0;
      maxPerUser = 0;
    }
    else if(period_ == PERIOD.PRE_SALE) {
      maxBatchSize = 3;
      maxPerUser = 3;
    }
    else if(period_ == PERIOD.OPEN_SALE) {
      maxBatchSize = 10;
      maxPerUser = 30;
    }
    mintPeriod = period_;
    emit PeriodChanged(period_);
  }

  /// @dev reveal signals the contract to return token JSON, instead of placeholder JSON
  function reveal() external onlyOwner {
    revealed = true;
    emit TokenRevealed();
  }

  /// @dev pre-allocate tokens to creators
  /// @return number of tokens pre-allocated 
  function preAllocate() internal onlyOwner returns(uint16) {
    //pre randomization allocation
    _safeMint(address(0xf33A496671C71dF3e304E2dc7854DCb0FACBCBCB), 64);
    _safeMint(address(0xe8B16D34f816348C08DE076e08E6DF05493AA70A), 14);
    _safeMint(address(0x2038C4988e0F7Bc1E2Bc7D15eEd49c83494b70a3), 13);
    _safeMint(address(0xb6A90c897F0C0Ca7ddE519bAf707CbB52FB254A2), 40);
    _safeMint(address(0xA9f99787f8dF47bD9369c82079Fc1bb1871D5A65), 40);
    _safeMint(address(0x909A30F58D9E7abfD4F8cF8430e2c2F97783E769), 5);
    _safeMint(address(0x5A667f33a24Bdcb0DEe1BACf61d828cdC51e496e), 5); 
    //post randomization allocation
    _safeMint(address(0xf33A496671C71dF3e304E2dc7854DCb0FACBCBCB), 223);
    _safeMint(address(0xe8B16D34f816348C08DE076e08E6DF05493AA70A), 6);
    _safeMint(address(0x2038C4988e0F7Bc1E2Bc7D15eEd49c83494b70a3), 7);
    _safeMint(address(0xb6A90c897F0C0Ca7ddE519bAf707CbB52FB254A2), 10);
    _safeMint(address(0xA9f99787f8dF47bD9369c82079Fc1bb1871D5A65), 10);
    _safeMint(address(0x909A30F58D9E7abfD4F8cF8430e2c2F97783E769), 5);
    _safeMint(address(0x5A667f33a24Bdcb0DEe1BACf61d828cdC51e496e), 5);
    return uint16(_currentIndex - 1);
  }
}
