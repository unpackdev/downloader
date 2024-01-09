// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Strings.sol";

contract JPEGSeasonFive is ERC1155, Ownable {

  using Strings for uint256;

  string private baseURI;
  string private baseExtension = ".json";
  string private notRevealedUri;
  uint256 public cost = 0.08 ether;
  uint256 public costOG = 0.04 ether;
  uint256 public maxSupply = 150;
  uint256 public maxRegularSupply = 135;
  uint256 public maxOGSupply = 15;
  uint256 public currentRegularSupply = 0;
  uint256 public currentOGSupply = 0;
  uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 1;
  bool public paused = true;
  bool public revealed = false;
  bool public whitelistedMintSale = true;
  address[] public whitelistedAddresses;
  address[] public whitelistedAddressesOG;

  uint256 public totalSupply;
  mapping(address => uint8) private howManyMinted;

  mapping (uint256 => bool) public tokenExists;

  string public _name;
  string public _symbol;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC1155(""){
    _name = name_;
    _symbol = symbol_;

    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function _baseURI() internal view returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
      return "ipfs://QmVKrcGrvY49FmWJ8tdgKWjXeBvkcagpftDad285PCU1dR";
  }

  function mint(uint256 _mintAmount) public payable {
    //uint256 supply = totalSupply();
    uint256 regularSupply = currentRegularSupply;
    uint256 totalMinted = howManyMinted[msg.sender];
    require(regularSupply + _mintAmount <= maxRegularSupply);

    if (msg.sender != owner()) {
        require(!paused);
        require(whitelistedMintSale);
        require(_mintAmount <= maxMintAmount);
        require(totalMinted <= maxMintAmount);
        require(isWhitelisted(msg.sender), "user is not whitelisted");

        uint256 ownerTokenCount = balanceOf(msg.sender, 0);
        require(ownerTokenCount < nftPerAddressLimit);
        require(msg.value >= cost * _mintAmount);
    }


    for (uint256 i = 0; i < _mintAmount; i++) {
      uint256 tokenCount = totalSupply + 1;
      _mint(msg.sender, tokenCount, 1, "");
      tokenExists[tokenCount] = true;
      totalSupply += 1;
      howManyMinted[msg.sender] += 1;
    }

    increaseRegularSupply(_mintAmount);
    
  }

  function mintOG(uint256 _mintAmount) public payable {
    //uint256 supply = totalSupply();
    uint256 OGSupply = currentOGSupply;
    uint256 totalMinted = howManyMinted[msg.sender];

    require(_mintAmount > 0);
    require(OGSupply + _mintAmount <= maxOGSupply);

    if (msg.sender != owner()) {
        require(!paused);
        require(whitelistedMintSale);
        require(_mintAmount <= maxMintAmount);
        require(totalMinted <= maxMintAmount);
        require(isOG(msg.sender), "user is not OG");

        uint256 ownerTokenCount = balanceOf(msg.sender, 0);
        require(ownerTokenCount < nftPerAddressLimit);
        require(msg.value >= costOG * _mintAmount);
    }


    for (uint256 i = 0; i < _mintAmount; i++) {
      uint256 tokenCount = totalSupply + 1;
      _mint(msg.sender, tokenCount, 1, "");
      tokenExists[tokenCount] = true;
      totalSupply += 1;
      howManyMinted[msg.sender] += 1;
    }
    increaseOGSupply(_mintAmount);
  }
  
  function increaseOGSupply(uint256 amount) internal {
    currentOGSupply = currentOGSupply + amount;
  }
  
  function increaseRegularSupply(uint256 amount) internal {
    currentRegularSupply = currentRegularSupply + amount;
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
      for(uint256 i =0; i < whitelistedAddresses.length; i++) {
          if(whitelistedAddresses[i] == _user) {
              return true;
          }
      }
      return false;
  }
  
   function isOG(address _user) public view returns (bool) {
      for(uint256 i =0; i < whitelistedAddressesOG.length; i++) {
          if(whitelistedAddressesOG[i] == _user) {
              return true;
          }
      }
      return false;
  }
  
  function alreadyMinted(address _user) public view returns (bool) {
    uint256 totalMinted = howManyMinted[_user];
        if(totalMinted >= 1) {
              return true;
        }
    return false;
  }


  /**
    * @dev Returns whether `tokenId` exists.
    *
    * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
    *
    * Tokens start existing when they are minted (`_mint`),
    * and stop existing when they are burned (`_burn`).
    */
  function _exists(uint256 tokenId) internal view returns (bool) {
      return tokenExists[tokenId];
  }
  function uri(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return bytes(notRevealedUri).length > 0
        ? string(abi.encodePacked(notRevealedUri, tokenId.toString(), baseExtension))
        : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  
  function setCostOG(uint256 _newCostOG) public onlyOwner {
    costOG = _newCostOG;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function StartWhitelistSale(bool _state) public onlyOwner {
    whitelistedMintSale = _state;
  }
 
 function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
  
 function whitelistOGUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddressesOG;
    whitelistedAddressesOG = _users;
  }

  function withdraw() public payable onlyOwner {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}