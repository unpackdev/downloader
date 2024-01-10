// SPDX-License-Identifier: MIT

//  $$$$$$$\                             $$$$$$\   $$$$$$\        $$$$$$$\                                                             
//  $$  __$$\                           $$  __$$\ $$  __$$\       $$  __$$\                                                            
//  $$ |  $$ | $$$$$$\  $$$$$$$\        $$ /  $$ |$$ /  \__|      $$ |  $$ | $$$$$$\  $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\ 
//  $$ |  $$ |$$  __$$\ $$  __$$\       $$ |  $$ |$$$$\           $$ |  $$ |$$  __$$\ \____$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  _____|
//  $$ |  $$ |$$$$$$$$ |$$ |  $$ |      $$ |  $$ |$$  _|          $$ |  $$ |$$ |  \__|$$$$$$$ |$$ /  $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
//  $$ |  $$ |$$   ____|$$ |  $$ |      $$ |  $$ |$$ |            $$ |  $$ |$$ |     $$  __$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
//  $$$$$$$  |\$$$$$$$\ $$ |  $$ |       $$$$$$  |$$ |            $$$$$$$  |$$ |     \$$$$$$$ |\$$$$$$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
//  \_______/  \_______|\__|  \__|       \______/ \__|            \_______/ \__|      \_______| \____$$ | \______/ \__|  \__|\_______/ 
//                                                                                             $$\   $$ |                              
//                                                                                             \$$$$$$  |                              
//                                                                                              \______/                               

pragma solidity >=0.6.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721Burnable.sol";



interface oldSmartContract{
  function totalSupply() external view returns (uint256);
  function ownerOf(uint256) external view returns (address);
}


contract DenOfDragons is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  address public stakingContract;

  bytes32 public root = 0x62b7022dfe3a9014ea1aa2771a1f9dc6ee683f3a1ce497bc4b06b9d30c06c8ea;
  
  uint256 public cost = 0.07 ether;
  uint256 public maxSupply = 7777;
  uint256 public maxMintAmountPerTx = 20;

  bool public paused = false;
  bool public revealed = false;

  //mapping variables checking if already claimed
  mapping(address => bool) public whitelistClaimed ;
  //bool checking openTo  public
  bool public OpenToPublic = false; 

  uint256 public maxPresaleMintAmount = 5;
  
  address oldSmartContractA = 0x1C8CD38d3945035dd12Fe4B5EfCF17c0bc638CED;

  constructor() ERC721("DenOfDragons", "DOD") {
    setHiddenMetadataUri("ipfs://QmcTLLrdfagp4aLBmRu7Y3Ydkbcw4hino1SPKh5ZD7MZzp/1.json");
    
    uint256 oldSupply = getSupplyOfOldContract();
    for (uint256 i = 1; i <= oldSupply; i++) {
      supply.increment();
      address oldOwner = getOwnerOfOldContract(i);
      _safeMint(oldOwner, supply.current());

   } 
  }   

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }


  function getSupplyOfOldContract() internal view returns (uint256) {
    return oldSmartContract(oldSmartContractA).totalSupply();
  }

  function getOwnerOfOldContract(uint256 _tokenId) internal view returns (address) {
    return oldSmartContract(oldSmartContractA).ownerOf(_tokenId);
  }


  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

 function changeMerkleROOT(bytes32 _merkleRoot) public onlyOwner {
     root = _merkleRoot;
 }

 /*if OpenToPublic = true, merkleproof=[] and amount = _mintAmount
 *else merkleproof= proof sent to client
 *client can claim one time
 */
  function mint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

     //Don't allow minting if presale is set and buyer is not in whitelisted map
    if (OpenToPublic) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _mintLoop(msg.sender, _mintAmount);
    }else{ 
        require(_mintAmount <= maxPresaleMintAmount, "Amount exceeded");
        whitelistMint(_merkleProof,msg.sender);
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _mintLoop(msg.sender, _mintAmount);
    }
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
      _mintLoop(_receiver, _mintAmount);
  }


  function setStakingAddress (address _contractAddress) public onlyOwner {
      stakingContract = _contractAddress;  //STAKING CONTRACT MUST BE SET IN ORDER FOR STAKING TO WORK
      setApprovalForAll(_contractAddress, true);
  }

  function approve1TokenForStaking (uint256 _tokenId) public {
      _approve(stakingContract, _tokenId); 
  }

  function approveAllTokensForStaking() public {
      uint256 ownedNfts = balanceOf(msg.sender);
      uint256 idCounter = 1;
      uint256 ownedNftsCounter = 0;
      while (ownedNftsCounter < ownedNfts && idCounter <= maxSupply) {
        address nftOwner = ownerOf(idCounter);

        if (nftOwner == msg.sender) {
            _approve(stakingContract, idCounter);
            ownedNftsCounter++;
        }
        idCounter++;
    }
  }

  function isApprovedForAll (address _address) public returns (bool) {
      return(isApprovedForAll(_address));
  }


  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
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
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

    function setOpenToPublic(bool _open) public onlyOwner {
      OpenToPublic = _open;
  }

  function setMaxPresaleMintAmount(uint256 _max) public onlyOwner {
      maxPresaleMintAmount = _max;
  }


    function whitelistMint(bytes32[] calldata _merkleProof, address _from) internal   {

    require(!whitelistClaimed[_from], "address has already claimed");
    //check if account is in whitelist
    bytes32 leaf=  keccak256(abi.encodePacked(_from));
    require(MerkleProof.verify(_merkleProof ,root ,leaf ),"Now Whitelisted");
    //mark address as having claimed their token 
        whitelistClaimed[_from]= true ;    
    }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
      _approve(stakingContract, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}