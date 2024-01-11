//SPDX-License-Identifier: MIT
/*
 ██████  ██████  ███    ███ ██  ██████ ██████   ██████  ██   ██ ███████ ██      ███████ 
██      ██    ██ ████  ████ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██      ██      
██      ██    ██ ██ ████ ██ ██ ██      ██████  ██    ██   ███   █████   ██      ███████ 
██      ██    ██ ██  ██  ██ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██           ██ 
 ██████  ██████  ██      ██ ██  ██████ ██████   ██████  ██   ██ ███████ ███████ ███████ 
*/                                                                           
pragma solidity ^0.8.13; 
import "./ERC721A.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract DigiDorablesC1 is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  enum PERIOD {
    PRE_LAUNCH,
    PRE_SALE,
    OPEN_SALE
  }

  //URIs
  string public baseURI = "";
  string public contractURI = "";
  string public placeholderURI = "";
  
  //token limits
  uint256 public immutable price;
  uint16 public immutable maxSupply;
  uint8 public maxBatchSize;
  uint8 public maxPerUser;
  
  //Merkle roots
  bytes32 public rootAllowList;
  bytes32 public rootRedeemableTokens;

  //token state
  bool public revealed;
  PERIOD public mintPeriod;

  IERC721 private immutable boxelContract;

  mapping(uint256 => bool) private redeemedBoxels;

  error MintMoreThanMaxSupply();
  error MintMoreThanMaxPerUser();
  error MintMoreThanBatchSize();
  error InsufficientPayment(uint256 expected);
  error NotOnAllowList();
  error NonRedeemableToken();
  error NotOwnerOfToken();
  error TokenHasBeenRedeemed();
  error WrongPeriod();

  event TokenRevealed();
  event PeriodChanged(PERIOD period);
  event BoxelRedeemed(uint256 tokenId);

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    string memory contractURI_,
    string memory placeholderURI_,
    uint256 price_,
    uint16 maxSupply_,
    address boxelContract_,
    bytes32 rootAllowList_,
    bytes32 rootRedeemableTokens_
  ) ERC721A(name_, symbol_) {
    baseURI = baseURI_;
    contractURI = contractURI_;
    placeholderURI = placeholderURI_;
    price = price_;  //pass price in ETH
    maxSupply = maxSupply_;
    //ComicBoxels Genesis is at 0xfF58403B9b011659f45d12744a0bE5F01c9FB607
    boxelContract = IERC721(boxelContract_);
    rootAllowList = rootAllowList_;
    rootRedeemableTokens = rootRedeemableTokens_;
    setMintPeriod(PERIOD.PRE_LAUNCH);
    preAllocate();
  }

  modifier onlyUser() {
    require(tx.origin == msg.sender, "Only a wallet address can mint");
    _;
  }

  // @dev first token index starts at 1
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /** Mint functions */

  function mint(uint16 quantity) external payable onlyUser {
    if(mintPeriod != PERIOD.OPEN_SALE) revert WrongPeriod();
    if(quantity > maxBatchSize && msg.sender != owner()) revert MintMoreThanBatchSize();
    if(totalSupply() + uint256(quantity) > maxSupply) revert MintMoreThanMaxSupply();
    if(_numberMinted(msg.sender) + quantity > maxPerUser && msg.sender != owner()) revert MintMoreThanMaxPerUser();
    uint256 totalPrice = calculatePrice(quantity);
    if(msg.value < totalPrice) revert InsufficientPayment({expected: totalPrice});

    _safeMint(msg.sender, quantity);
    //emits a Transfer event for every token minted
  }

  //mint for an address on the allow list
  function allowListMint(uint16 quantity, bytes32[] memory proof) external payable onlyUser {
    if(mintPeriod != PERIOD.PRE_SALE) revert WrongPeriod();
    if(!MerkleProof.verify(proof, rootAllowList, keccak256(abi.encodePacked(msg.sender)))) revert NotOnAllowList();
    if(quantity > maxBatchSize && msg.sender != owner()) revert MintMoreThanBatchSize();
    if(totalSupply() + uint256(quantity) > maxSupply) revert MintMoreThanMaxSupply();
    if(_numberMinted(msg.sender) + quantity > maxPerUser && msg.sender != owner()) revert MintMoreThanMaxPerUser();
    uint256 totalPrice = calculatePrice(quantity);
    if(msg.value < totalPrice) revert InsufficientPayment({expected: totalPrice});
    
    _safeMint(msg.sender, quantity);
    //emits a Transfer event for every token minted
  }

  //redeem a DigiDorables token, providing Merkle Proof to the token number
  function redeem(uint256 tokenId, bytes32[] memory proof) external onlyUser {
    if(mintPeriod == PERIOD.PRE_LAUNCH) revert WrongPeriod();
    if(totalSupply() + 1 > maxSupply) revert MintMoreThanMaxSupply();
    if(boxelContract.ownerOf(tokenId) != msg.sender) revert NotOwnerOfToken();
    if(redeemedBoxels[tokenId]) revert TokenHasBeenRedeemed();
    bytes32 token = keccak256(abi.encodePacked(tokenId.toString()));
    if(!MerkleProof.verify(proof, rootRedeemableTokens, token)) revert NonRedeemableToken();
    //you get 2 DigiDorables for a redeemed Boxel! Yay!
    _safeMint(msg.sender, 2);
    redeemedBoxels[tokenId] = true;
    emit BoxelRedeemed(tokenId);
    //emits a Transfer event for every token minted
  }

  function tokensLeft() public view returns(uint16) {
    return maxSupply - uint16(totalSupply());
  }

  function isBoxelRedeemed(uint256 tokenId) public view returns(bool) {
    return (redeemedBoxels[tokenId] == true);
  }

  function calculatePrice(uint16 quantity) public view returns (uint256) {
    if(msg.sender != address(0)) {
      if(msg.sender == owner()) {
        return 0 ether;
      }
      else if(boxelContract.balanceOf(msg.sender) > 0) {
        return ((price - 0.01 ether) * quantity);
      }
    }
    return price * quantity;
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

  /** URI functions */

  // @dev if token is revealed, use baseURI + tokenID, otherwise, serve placeholder URI
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    if(revealed) {
      return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }
    else {
      return bytes(placeholderURI).length != 0 ? placeholderURI : '';
    }
  }

  /** Owner only functions */

  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function setContractURI(string memory contractURI_) public onlyOwner {
    contractURI = contractURI_;
  }

  function setPlaceholderURI(string memory placeholderURI_) public onlyOwner {
    placeholderURI = placeholderURI_;
  }

  /// @dev reveal signals the contract to return token JSON, instead of placeholder JSON
  function reveal() external onlyOwner {
    revealed = true;
    emit TokenRevealed();
  }

  function withdraw() external nonReentrant onlyOwner {
    uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
  }

  function setMerkleRoots(bytes32 rootAllowList_, bytes32 rootRedeemableTokens_) external onlyOwner {
    rootAllowList = rootAllowList_;
    rootRedeemableTokens = rootRedeemableTokens_;
  }

  /// @dev set mint period and token mint limits
  function setMintPeriod(PERIOD period_) public onlyOwner {
    if(period_ == PERIOD.PRE_LAUNCH) {
      maxBatchSize = 0;
      maxPerUser = 0;
    }
    else if(period_ == PERIOD.PRE_SALE) {
      maxBatchSize = 10;
      maxPerUser = 10;
    }
    else if(period_ == PERIOD.OPEN_SALE) {
      maxBatchSize = 10;
      maxPerUser = 30;
    }
    mintPeriod = period_;
    emit PeriodChanged(period_);
  }

  function preAllocate() internal onlyOwner {
    _safeMint(address(0xf33A496671C71dF3e304E2dc7854DCb0FACBCBCB), 200);
    _safeMint(address(0xe8B16D34f816348C08DE076e08E6DF05493AA70A), 100);
  }
}
