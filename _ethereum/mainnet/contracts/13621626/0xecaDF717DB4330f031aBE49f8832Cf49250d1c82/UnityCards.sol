// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

import "./ReentrancyGuard.sol";


import "./IUnityCards.sol";
import "./IUnityCardsMetadata.sol";

contract UnityCards is ERC721Enumerable, Ownable, IUnityCards, IUnityCardsMetadata, ReentrancyGuard {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 7_777;
  uint256 public PURCHASE_LIMIT = 2;


  bool public isActive = true;
  bool public isAllowListActive = true;
  bytes32 public merkleroot;

  /// @dev We will use these to be able to calculate remaining correctly.
  uint256 public totalPublicSupply;

  mapping(address => uint256) private _allowListClaimed;
  mapping(address => bool) private _batchAllowed;


  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  constructor(string memory name, string memory symbol, bytes32 root) ERC721(name, symbol) {
    merkleroot = root;
  }


  /**
  * @dev We want to be able to distinguish tokens bought during isAllowListActive
  * and tokens bought outside of isAllowListActive
  */
  function allowListClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');

    return _allowListClaimed[owner];
  }

  function purchase(uint256 numberOfTokens) 
    external 
    override  
  nonReentrant() {

    require(isActive, 'Contract is not active');
    require(!isAllowListActive, 'Only allowing from Allow List');
    require(totalSupply() < MAX_SUPPLY, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
    require(totalPublicSupply < MAX_SUPPLY, 'Purchase would exceed MAX_SUPPLY');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      /**
      * @dev Since they can get here while exceeding the MAX_SUPPLY,
      * we have to make sure to not mint any additional tokens.
      */
      if (totalPublicSupply < MAX_SUPPLY) {
        /**
        * @dev Public token numbering starts at 1.
        * so next token id is equal to actualSupply + 1.
        */
        uint256 tokenId = totalPublicSupply + 1;

        totalPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }


  function freeClaimAllowList(uint256 index, uint256 numberOfTokens, bytes32[] calldata proof) 
    external 
    override 
  nonReentrant() {
    
    require(isActive, 'Contract is not active'); //
    require(isAllowListActive, 'Allow List is not active'); //
    require(totalSupply() < MAX_SUPPLY, 'All tokens have been minted'); //
    require(totalPublicSupply + numberOfTokens <= MAX_SUPPLY, 'claim would exceed MAX_SUPPLY'); //
    // Verify the merkle proof: we store the the Allow List in a Merkle Tree to reduce gas costs to claim
    require(_verify(_leaf(index, msg.sender, numberOfTokens), proof), "Invalid merkle proof");
    require(_allowListClaimed[msg.sender] + numberOfTokens <= numberOfTokens, 'Already Claimed');


    for (uint256 i = 0; i < numberOfTokens; i++) {

      totalPublicSupply += 1;
      _safeMint(msg.sender, totalPublicSupply);
    }

    _allowListClaimed[msg.sender] += numberOfTokens;   

  }

  function freeClaimAllowListBatch(uint256 index, uint256 numberOfTokens, uint256 numberOfTokensClaimed, bytes32[] calldata proof) 
    external 
    override
  nonReentrant() {
    require(_batchAllowed[msg.sender], 'Batch Claiming is not allowed');
    require(isActive, 'Contract is not active'); //
    require(isAllowListActive, 'Allow List is not active'); //
    require(totalSupply() < MAX_SUPPLY, 'All tokens have been minted'); //
    require(totalPublicSupply + numberOfTokensClaimed <= MAX_SUPPLY, 'claim would exceed MAX_SUPPLY'); //
    // Verify the merkle proof: we store the the Allow List in a Merkle Tree to reduce gas costs to claim
    require(_verify(_leaf(index, msg.sender, numberOfTokens), proof), "Invalid merkle proof");
    require(_allowListClaimed[msg.sender] + numberOfTokensClaimed <= numberOfTokens, 'Already Claimed');


    for (uint256 i = 0; i < numberOfTokensClaimed; i++) {

      totalPublicSupply += 1;
      _safeMint(msg.sender, totalPublicSupply);
    }

    _allowListClaimed[msg.sender] += numberOfTokensClaimed;   

  }

  function _leaf(uint256 index, address account, uint256 amount) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(index, account, amount));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
    return MerkleProof.verify(proof, merkleroot, leaf);
  }

  function setBatchClaimState(address account, bool state) external override onlyOwner {
    _batchAllowed[account] = state;
  }

  function setIsActive(bool _isActive) external override onlyOwner {
    isActive = _isActive;
  }

  function setIsAllowListActive(bool _isAllowListActive) external override onlyOwner {
    isAllowListActive = _isAllowListActive;
  }

  function setMerkleRoot(bytes32 root) external override onlyOwner {
    merkleroot = root;
  }

  function setPurchaseLimit(uint256 limit) external override onlyOwner {
    PURCHASE_LIMIT = limit;
  }

  function withdraw() external override onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    /// @dev Convert string to bytes so we can check if it's empty or not.
    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}