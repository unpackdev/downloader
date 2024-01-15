// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract AIdickbutts is ERC721A, Ownable {
  using Strings for uint256;

  string private baseUri = "ipfs://QmdxwfzjDLUyakm4DQ1B93z18n5gvvVx5fssxXxtUNVRPn/";
  string public hiddenMetadataUri;
  
  uint256 public price = 0.0269 ether; 
  uint256 public maxSupply = 690; 
  uint256 public maxMintAmountPerTx = 50; 
  uint256 public nftPerAddressLimit = 100; 
  
  bool public paused = false;
  bool public revealed = true;
  bool public onlyWhitelisted = false;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;


  constructor() ERC721A("AIdickutts", "AIDB") {
    setHiddenMetadataUri("");
  }

   function mint(uint256 _mintAmount) public payable {
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(!paused, "The contract is paused! don't confirm the transaction!");
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded! don't confirm the transaction!");
    if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "address is not Whitelisted! don't confirm the transaction!");
        }
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
    
    addressMintedBalance[msg.sender]+=_mintAmount;
    
    _safeMint(msg.sender, _mintAmount);
  }
  
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;

  }
 
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setnftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setbaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      _safeMint(_receiver, _mintAmount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
    
  }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
    
  }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
   
  }

  function addWhitelistUsers(address[] calldata _users) public onlyOwner { //ARRAY users
    whitelistedAddresses = _users;
  }

    function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  // withdraw address
  address dep1 = 0x0814f174b179886d92c9136Bebb639124156E702; // Deployer address


     /// @notice Withdraw contract balance to deployer address
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(dep1).transfer((balance * 100)/100);
    }
    
}