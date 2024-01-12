//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./MerkleProof.sol";

contract ToonSocietyMain is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;

    //metadata info
    string public baseURI;
    string public baseExtension = ".json";
    //string public notRevealedURI; 

    string public mycontractURI; //Collection Description
    uint256 public whitelistCost = 0.06 ether;
    uint256 public publicSaleCost = 0.09 ether;
    uint256 public maxSupply = 4444; //Number of NFTs in collection
    uint256 public maxMintAmount = 9; //Maximum number of nfts that can be minted per transaction
    uint256 public nftPerAddressLimit = 9; //Maxmimum number of nfts per Wallet

    uint96 royaltyBasis;
    bool public paused = false;
    bool public revealed = false;
    bool public onlyWhitelisted = true;
    address royaltyAddress;

    bytes32 public whitelistRoot; //merkle tree root for whitelist verification
    mapping(address => uint256) public freeMintAddresses;
    mapping(address => uint256) public addressMintedBalance;

    constructor(string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    //string memory _initNotRevealedUri,
    uint96 _royaltyBasis, 
    string memory _contractURI,
    bytes32 _whitelistRoot) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        //setNotRevealedURI(_initNotRevealedUri);
        royaltyAddress = owner();
        royaltyBasis = _royaltyBasis;
        mycontractURI = _contractURI;
        whitelistRoot = _whitelistRoot;
    }

    // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // function _notRevealedURI() internal view virtual returns (string memory) {
  //   return notRevealedURI;
  // }

  function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
      require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
      require(addressMintedBalance[msg.sender] + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        if(onlyWhitelisted) { //whitelist Sale
            require(MerkleProof.verify(_merkleProof, whitelistRoot, keccak256(abi.encodePacked(msg.sender))), "Wallet is not whitelisted");
            require(msg.value >= whitelistCost * _mintAmount, "insufficient funds");
        }
        else{ //public Sale
          require(msg.value >= publicSaleCost * _mintAmount, "insufficient funds");
        }
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function freeMint(uint256 _mintAmount) public {
    require(!paused, "the contract is paused");
    require(!onlyWhitelisted, "Presale only");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    require(_mintAmount <= freeMintAddresses[msg.sender], "Unsufficient free mints available");

    
    for (uint256 i = 1; i <= _mintAmount; i++) {
      freeMintAddresses[msg.sender]--;
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    // if(!revealed) {
    //     string memory currentNotRevealedURI = _notRevealedURI();
    //     return bytes(currentNotRevealedURI).length > 0
    //     ? string(abi.encodePacked(currentNotRevealedURI, Strings.toString(tokenId), baseExtension))
    //     : "";
    // }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }

  function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(mycontractURI));
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view 
  returns (address receiver, uint256 royaltyAmount){
    return (royaltyAddress, _salePrice.mul(royaltyBasis).div(10000));
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
      return interfaceId == type(IERC721Enumerable).interfaceId || 
      interfaceId == 0xe8a3d485 /* contractURI() */ ||
      interfaceId == 0x2a55205a /* ERC-2981 royaltyInfo() */ ||
      super.supportsInterface(interfaceId);
  }

  //only owner
  // function reveal() public onlyOwner {
  //     revealed = true;
  // }
  
  function setRoyaltyInfo(address _receiver, uint96 _royaltyBasis) public onlyOwner {
      royaltyAddress = _receiver;
      royaltyBasis = _royaltyBasis;
  }

  function setContractURI(string calldata _contractURI) public onlyOwner {
      mycontractURI = _contractURI;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setWhitelistCost(uint256 _whitelistCost) public onlyOwner {
    whitelistCost = _whitelistCost;
  }

  function setPublicCost(uint256 _publicCost) public onlyOwner {
    publicSaleCost = _publicCost;
  }

  function setmaxMintAmount(uint8 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  // function setNotRevealedURI(string memory _notRevealedUri) public onlyOwner {
  //   notRevealedURI = _notRevealedUri;
  // }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _onlyWhitelist) public onlyOwner {
      onlyWhitelisted = _onlyWhitelist;
  }

  function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner{
    whitelistRoot = _whitelistRoot;
  }

   function addUsersToFreeMint(address[] memory _users, uint256[] memory _mintAmt) public onlyOwner {
    for(uint256 i=0;i<_users.length;i++)
      freeMintAddresses[_users[i]] = _mintAmt[i];
  }

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}
