// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/* 
 * ////////////////////////////////////////////////////////00/////////////////////
 * /////////////////////////////////////////////////////0###0/////////////////////
 * //////////////////////////////////////////////00//0#####0//////////////////////
 * /////////////////////////////////////////////000#######0///////////////////////
 * ////////////////////////////////////////////0#########0////////////////////////
 * ///////////////////////////////////////////0#########0/////////////////////////
 * ////////////////////////0000000000000000000###########0000/////////////////////
 * //////////////////////0####################################0///////////////////
 * ////////////////////0#######################################0//////////////////
 * ///////////////////0#########################################0/////////////////
 * //////////////////0###########################################0////////////////
 * /////////////////0#####################--------------------####0///////////////
 * /////////////////0#####################----    ----    ----####0///////////////
 * /////////////////0#####################----    ----    ----####0///////////////
 * /////////////////0#####################----    ----    ----####0///////////////
 * /////////////////0#####################--------------------####0///////////////
 * //////////////////00#########################################00////////////////
 * ///////////////////00#######################################00/////////////////
 * ////////////////////00####   ##############################00//////////////////
 * /////////////////////00###   #############################00///////////////////
 * //////////////////////00###    ##########################00////////////////////
 * ////////////////////////00###   ########################00/////////////////////
 * //////////////////////////00%%%%   ###################00///////////////////////
 * //////////////////////////////00###################00//////////////////////////
 * //////////////////////////////////000000000000000//////////////////////////////
 * ///////////////////////////////////////////////////////////////////////////////
 * ///////////////////////////////////////////////////////////////////////////////
 * 
 * 
 * Dem Apples Fam!
 *
 * First, we want to give a huge shoutout to @nftchance, @masonnft, 
 * @squeebo_nft, and the entire Nuclear Nerds team. 
 *
 * A week ago, after the Nuclear Nerds launch with insanely low gas fees, we decided to re-think
 * and optimize our standard Smart Contract and committed to building something better for our community.
 * 
 * Without their attention to detail and openness about how they re-wrote the playbook
 * for NFT smart contracts - none of the optimizations in this Smart Contract would exist 
 * - so a huge thank you to all of them!
 *
 * We're so excited to share Dem Apples with you all. 
 *
 * We are a community for everyone, we are a place for creatives and collectors to come together,
 * to foster ideas, projects, and relationships. We are creating something truly special, 
 * and we can't wait for you to be apart of it.
 */

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract DemApples is ERC721Enumerable, Ownable {
  string public baseURI;

  address public theTeam;
  address public proxyRegistryAddress;

  bool public saleIsActive = false;  

  uint256 public constant PRICE_PER_TOKEN = 0.05 ether;
  uint256 public constant MAX_SUPPLY = 5500;
  uint256 public constant MAX_MINT_AMOUNT = 21;

  mapping(address => uint8) private _allowList;
  mapping(address => bool) public projectProxy;

  constructor(
    string memory _baseURI,
    address _proxyRegistryAddress,
    address _theTeam
  ) 
    ERC721("Dem Apples", "NOM") 
  {
    baseURI = _baseURI;
    proxyRegistryAddress = _proxyRegistryAddress;
    theTeam = _theTeam;
  }

  // Set base URI
  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  // Set proxy registry address of opensea
  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  } 

  // Set the teams address
  function setTheTeam(address _theTeam) external onlyOwner {
    theTeam = _theTeam;
  }    

  // Retrieve tokenURI for a specific tokenID
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist.");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  // Number of tokens available to mint for address on whitelist
  function numAvailableToMint(address addr) external view returns (uint8) {
    return _allowList[addr];
  }    

  // Whitelist minting function
  function mintPrivateSale(uint256 numberOfTokens) external payable {
    uint256 ts = totalSupply();

    require(numberOfTokens < _allowList[msg.sender], "You are not on the whitelist");
    require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed maximum supply");   
    require(PRICE_PER_TOKEN * numberOfTokens == msg.value, "Ether value sent is not correct");     
         
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, ts + i);
    }
  }

  // Allow anyone in public to mint
  function mintPublicSale(uint256 numberOfTokens) external payable {
    uint256 ts = totalSupply();

    require(saleIsActive, "Public sale is not yet active");
    require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed maximum supply");
    require(numberOfTokens < MAX_MINT_AMOUNT, "Can't purchase that many tokens");
    require(PRICE_PER_TOKEN * numberOfTokens == msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, ts + i);
    }
  }

  // Set the status of the public sale
  function setSaleIsActive(bool _newState) public onlyOwner {
    saleIsActive = _newState;
  }    
 
  // Set the allow list for whitelisted users
  function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      _allowList[addresses[i]] = numAllowedToMint;
    }
  }

  // Run airdrop to giveaway winners
  function runAirdrops(address[] calldata addresses) external onlyOwner {
    uint256 ts = totalSupply();
    for (uint256 i = 0; i < addresses.length; i++) {
      _safeMint(addresses[i], ts + i);
    }
  }

  // Reserve
  function reserve(uint256 n) public onlyOwner {
    uint256 ts = totalSupply();
    for (uint256 i = 0; i < n; i++) {
      _safeMint(msg.sender, ts + i);
    }    
  }

  // Withdraw
  function withdraw() public onlyOwner  {
    (bool success, ) = theTeam.call{value: address(this).balance}("");
    require(success, "Failed to send to the Team.");
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) return new uint256[](0);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      transferFrom(_from, _to, _tokenIds[i]);
    }
  }

  function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      safeTransferFrom(_from, _to, _tokenIds[i], data_);
    }
  }

  function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
    for(uint256 i; i < _tokenIds.length; ++i ){
      if(_owners[_tokenIds[i]] != account)
          return false;
    }

    return true;
  }  

  // IsApprovedForAll function with opensea proxy registry pre-approved
  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
    return super.isApprovedForAll(_owner, operator);
  }

  function flipProxyState(address proxyAddress) public onlyOwner {
      projectProxy[proxyAddress] = !projectProxy[proxyAddress];
  }    
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}