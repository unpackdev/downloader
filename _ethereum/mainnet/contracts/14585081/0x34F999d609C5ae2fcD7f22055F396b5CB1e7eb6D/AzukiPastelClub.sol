// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./Address.sol";

import "./ERC721A.sol";

contract AzukiPastelClub is ERC721A, Ownable {
  using Address for address;

  Counters.Counter private _tokenIdCounter;

  string private baseURI = "ipfs://QmNmKcg2agpAnxUNDX6ziJP5qLU3Vpko6tZqNxR6atEECC";
  string private _contractURI = "ipfs://QmY3VCvLt2dhWr38wLnDg2F4ir2WMtWGXJQgS7mfrc3DxV";

  string public constant PROVANCE = "";

  bool public frozenMetadata;
  event PermanentURI(string _baseURI, string _contractURI);

  uint256 public PRICE = 0.009 ether;
  uint public constant MAXPURCHASE = 20;
  uint256 public MAXSUPPLY = 3333;

  uint256 public saleStart = 1649797200;

  bool public revealed;  

  constructor() ERC721A("AzukiPastelClub", "APC") {}

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseUri(string memory baseURI_) external onlyOwner {
    require(!frozenMetadata,"Metadata already frozen");
    baseURI = baseURI_;
  }

  function contractURI() public view returns (string memory) {        
    return _contractURI;
  }

  function setContractURI(string memory contractURI_) external onlyOwner {
    require(!frozenMetadata,"Metadata already frozen");
    _contractURI = contractURI_;
  }

  
  function setPrice(uint256 price) external onlyOwner {
    PRICE=price;
  }

  function freezeMetadata() external onlyOwner {
    frozenMetadata = true;
    emit PermanentURI(baseURI, _contractURI);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  function mint(uint numberOfTokens) public payable {
    require(block.timestamp >= saleStart, "Sale must be active to mint new NFTs");
    require(numberOfTokens <= MAXPURCHASE, "You can't mint that many at once");
    require(totalSupply() + numberOfTokens < MAXSUPPLY, "Purchase would exceed max supply");
    require(PRICE * numberOfTokens <= msg.value, "to little value has been sent");     

    _safeMint(_msgSender(), numberOfTokens);  
  }

  function singleAirdrop(address target) public onlyOwner {
    require(totalSupply() + 1 < MAXSUPPLY, "Purchase would exceed max supply");        

    _safeMint(target, 1);  
  }

  function multiAirdrop(address[] memory targets) public onlyOwner {
    require(targets.length <= MAXPURCHASE, "You can't mint that many at once");
    require(totalSupply() + targets.length < MAXSUPPLY, "Purchase would exceed max supply");   

    for (uint256 index = 0; index < targets.length; index++) {
      _safeMint(targets[index], 1);
    }      
  }

  function setSaleStart(uint256 _saleStart) public onlyOwner {
      saleStart = _saleStart;
  }

  /**
    * @dev get mint fees out of the contract and split it
    */
  function withdrawETH() external onlyOwner {
      uint256 balance = address(this).balance;        
      
      Address.sendValue(payable(0xBf6304F05eA75CB2d76B90E24a9Fb0E01832933F), balance * 15 / 100);    
      Address.sendValue(payable(0xe9A36d2d6820539ec2F3b4ddC68Fd337BF8Ce293 ), balance * 30 / 100);    
      Address.sendValue(payable(0x1b7Be63B62BA6bcD5510E541CA150A374f4A6E02 ), address(this).balance);    
  }

  /**
    * @dev Fallback to help users get their funds out, not token should ever go to this
    */
  function withdrawAnyToken(address _contract) public onlyOwner {
    IERC20(_contract).transfer(owner(), IERC20(_contract).balanceOf(address(this)));
  }    

  function reveal(string memory newBaseURI) external onlyOwner {
      revealed = true;
      baseURI = newBaseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (revealed) {
      return super.tokenURI(tokenId);
    }
    else {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return baseURI;
    }      
  }
}
