// SPDX-License-Identifier: MIT

/*

            /$$$$$$                             
           /$$__  $$                            
  /$$$$$$ | $$  \__//$$$$$$   /$$$$$$   /$$$$$$$
 /$$__  $$| $$$$   /$$__  $$ /$$__  $$ /$$_____/
| $$  \ $$| $$_/  | $$$$$$$$| $$  \__/|  $$$$$$ 
| $$  | $$| $$    | $$_____/| $$       \____  $$
| $$$$$$$/| $$    |  $$$$$$$| $$       /$$$$$$$/
| $$____/ |__/     \_______/|__/      |_______/ 
| $$                                            
| $$                                            
|__/                                            
                                                                                                                         
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";
import "./ERC721A.sol";

contract Pfers is Ownable, ERC721A, IERC2981, ReentrancyGuard {

  struct RoyaltyInfo {
    address recipient;
    uint24 basisPoints;
  }

  uint256 public immutable collectionSize; // = 10021;
  uint256 public immutable maxPerTxDuringMint; // = 10;
  uint256 public immutable amountForDevs; // = 21;
  uint256 public immutable publicPrice; // = 0.03 ether;
  uint256 public amountForFree; // = 1000;
  bool public isActive;
  bool public isRevealed;
  string public notRevealedURI;
  string private _baseTokenURI;
  string private _contractURI;
  address UKRAINE = 0x165CD37b4C644C2921454429E7F9358d18A45e14; // Ukraine Crypto Donation Address

  RoyaltyInfo private _royalties;

  constructor(
    uint256 _collectionSize,
    uint256 _maxPerTxDuringMint,
    uint256 _amountForDevs,
    uint256 _publicPrice,
    uint256 _amountForFree,
    string memory _initNotRevealedURI
  ) ERC721A("pfers", "PFERS") 
  {
    collectionSize = _collectionSize;
    maxPerTxDuringMint = _maxPerTxDuringMint;
    amountForDevs = _amountForDevs;
    publicPrice = _publicPrice;
    amountForFree = _amountForFree;
    setNotRevealedURI(_initNotRevealedURI);
    _royalties.recipient = msg.sender;
    _royalties.basisPoints = 500;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function freeMint()
    external
    callerIsUser
    nonReentrant
  {
    require(isActive,"free mint has not begun yet");
    require(amountForFree >= 1, "purchase would exceed free mint supply");
    require(totalSupply() + 1 <= collectionSize, "purchase would exceed max supply");

    amountForFree--;
    _safeMint(msg.sender, 1);
  }

  function publicSaleMint(uint256 quantity)
    public
    payable
    callerIsUser
    nonReentrant
  {
    require(isActive,"public sale has not begun yet");
    require(totalSupply() + quantity <= collectionSize, "purchase would exceed max supply");
    require(quantity <= maxPerTxDuringMint,"can not mint this many");
    require(publicPrice * quantity <= msg.value, "ETH amount is not sufficient");

    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }


  /* PUBLIC / EXTERNAL VIEW FUNCTIONS */

  function contractURI() 
    public 
    view 
    returns (string memory) 
  {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (isRevealed == false) {
        return notRevealedURI;
    }

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : '';
  }

  function numberMinted(address owner) 
    public 
    view 
    returns (uint256) 
  {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    override(ERC721A, IERC165) 
    returns (bool) 
  {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
      RoyaltyInfo memory royalties = _royalties;
      receiver = royalties.recipient;
      royaltyAmount = (_salePrice * royalties.basisPoints) / 10000;
  }


  /* PRIVATE / INTERNAL FUNCTIONS */
  function refundIfOver(uint256 price) 
    private 
  {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function _baseURI() 
    internal 
    view 
    virtual 
    override 
    returns (string memory) 
  {
    return _baseTokenURI;
  }


  /* ONLY OWNER FUNCTIONS */
  function setContractURI(string calldata URI) 
    external 
    onlyOwner 
  {
    _contractURI = URI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) 
    public 
    onlyOwner 
  {
    notRevealedURI = _notRevealedURI;
  }
  function setBaseURI(string calldata baseURI) 
    external 
    onlyOwner 
  {
    _baseTokenURI = baseURI;
  }

  function devMint() 
    external
    onlyOwner 
  {
    require(totalSupply() + amountForDevs <= collectionSize,"too many already minted before dev mint");
    require(numberMinted(msg.sender) < amountForDevs, "dev already minted");
    _safeMint(msg.sender, amountForDevs);
  }

  function setIsActive() 
    external 
    onlyOwner 
  {
    isActive = !isActive;
  }

  function setIsRevealed() 
    external 
    onlyOwner 
  {
    isRevealed = true;
  }

  function setRoyaltiesPercentage(uint24 _basisPoints) 
    external 
    onlyOwner 
  {
      require(_basisPoints <= 10000, 'Basis points too high');
      _royalties.basisPoints = _basisPoints;
  }

  function setRoyaltiesAddress(address _addr) 
    external 
    onlyOwner 
  {
      _royalties.recipient = _addr;
  }

  function withdrawMoney() 
    external 
    onlyOwner 
  {
    // 90% of mint goes directly to Ukraine 
    payable(UKRAINE).transfer(address(this).balance * 90 / 100);
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}