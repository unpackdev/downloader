// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./OperatorFilterer.sol";

//               ..   ..                                    
//             .111   111.                                   
//            .1111   1111.                                  
//           .11111   11111.                                
//          .111111   111111.                               
//         .111111.   .111111.                              
//        .1111111     1111111.                             
//       .1111111.     .1111111.                            
//      .11111111       11111111.                           
//     .11111111.       .11111111.                          
//    .111111111         111111111.                         
//   .11111111111111111111111111111.                        
//  .1111111111111111111111111111111.    

//Errors

//Mint
error MaxQuantityAllowedExceeded();
error MaxEntitlementsExceeded();
error MaxSupplyExceeded();
error ContractIsPaused();
error PriceIncorrect();
error ContractsNotAllowed();
error NonceConsumed();
error HashMismatched();
error MerkleProofInvalid();
error SignedHashMismatched();
error MintIsNotOpen();

//Post-Mint
error DNASequenceHaveBeenInitialised();
error DNASequenceNotSubmitted();
error NotReadyForTranfusion();
error TransfusionSequenceCompleted();

/// @title Arcana Contract
/// @author @whyS0curious
/// @notice Beware! Arcana is only for the dauntless ones. 
/// @dev Based off ERC-721A for gas optimised batch mints

contract ArcanaPrime is ERC721A, Ownable, OperatorFilterer {
  using Strings for uint256;
  using ECDSA for bytes32;
  enum Phases{ CLOSED, ARCANA, ASPIRANT, ALLIANCE, PUBLIC }
  uint public currentPhase;

  bool public operatorFilteringEnabled;

  uint256 public constant WAR_CHEST_SUPPLY = 512;
  uint256 public constant MAX_ENTITLEMENTS_ALLOWED = 2;
  uint256 public constant MAX_QUANTITY_ALLOWED = 3;
  uint256 public constant MAX_SUPPLY = 10_000;
  uint256 public constant MINT_PRICE = 0.08 ether;

  
  string public notRevealedUri;
  string public baseTokenURI;
  uint256 public nextStartTime;
  bool public paused = true;

  bytes32 public arcanaListMerkleRoot;
  bytes32 public aspirantListMerkleRoot;
  bytes32 public allianceListMerkleRoot;

  bool public isTransfused = false;
  uint256 public scheduledTransfusionTime;
  uint256 public sequenceOffset;
  string public dna;

  mapping(bytes32 => bool) public nonceRegistry;

  constructor(
    string memory _baseURI
  ) ERC721A("TEST", "TITS") {
     _registerForOperatorFiltering();
    notRevealedUri = _baseURI;
    operatorFilteringEnabled = true;
  }

  /*Royalty Enforcement*/

  function registerCustomBlacklist(address subscriptionOrRegistrantToCopy, bool subscribe) public onlyOwner {
    _registerForOperatorFiltering(subscriptionOrRegistrantToCopy, subscribe);
  }

  function repeatRegistration() public {
    _registerForOperatorFiltering();
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function _operatorFilteringEnabled() internal view virtual override returns (bool) {
    return operatorFilteringEnabled;
  }

  /*Pre-mint Configurations*/
  function setArcanaListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner
  {
    arcanaListMerkleRoot = _merkleRootHash;
  }

  function setAspirantListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner
  {
    aspirantListMerkleRoot = _merkleRootHash;
  }

  function setAllianceListMerkleRoot(bytes32 _merkleRootHash) external onlyOwner
  {
    allianceListMerkleRoot = _merkleRootHash;
  }

  function setNotRevealedBaseURI(string memory _baseURI) external onlyOwner {
    notRevealedUri = _baseURI;
  }

  function togglePause(bool _state) external payable onlyOwner {
    paused = _state;
  }

  function setNextStartTime(uint256 _timestamp) external payable onlyOwner {
    nextStartTime = _timestamp;
  }

  function setCurrentPhase(uint index) external payable onlyOwner {
    if(index == 0) {
      currentPhase = uint(Phases.CLOSED);
    }
    if(index == 1) {
      currentPhase = uint(Phases.ARCANA);
    }
    if(index == 2) {
      currentPhase = uint(Phases.ASPIRANT);
    }
    if(index == 3) {
      currentPhase = uint(Phases.ALLIANCE);
    }
    if(index == 4) {
      currentPhase = uint(Phases.PUBLIC);
    }
  }

   /*Pre-reveal Configurations*/
  function setBaseTokenURI(string memory _baseURI) external onlyOwner {
    baseTokenURI = _baseURI;
  }

  function commitDNASequence(string calldata _dna) external payable onlyOwner {
    if (scheduledTransfusionTime != 0) revert DNASequenceHaveBeenInitialised();

    dna =_dna;
    scheduledTransfusionTime = block.number + 5;
  }

  function transfuse() external payable onlyOwner {
    if (scheduledTransfusionTime == 0) revert DNASequenceNotSubmitted();

    if (block.number < scheduledTransfusionTime) revert NotReadyForTranfusion();

    if (isTransfused) revert TransfusionSequenceCompleted();

    sequenceOffset = (uint256(blockhash(scheduledTransfusionTime)) % MAX_SUPPLY) + 1;

    isTransfused = true;
  }

  /*Mint*/

  // Community War Chest
  /// @notice Mints part of the supply in the community wallet that Arcana owns. Note: Likely hidden from OpenSea due to Aux.
  /// @dev Only the Owner of the smart contract can call this function
  /// @param _communityWalletPublicKey The address of the community wallet
  function mintWarChestReserve(address _communityWalletPublicKey) external payable isBelowMaxSupply(WAR_CHEST_SUPPLY) onlyOwner {
    _mint(_communityWalletPublicKey, WAR_CHEST_SUPPLY);
  }

  // Arcana List Mint
  /// @notice Mint function to invoke for ARCANA LIST PHASE addresses
  /// @dev Checks that enough ETH is paid, quantity to mint results in below max supply, is whitelisted, is not paused and below max quantity allowed per wallet address
  function mintArcanaList(bytes32[] calldata _merkleProof, uint256 _quantity) external payable isBelowMaxSupply(_quantity) isWhitelisted(_merkleProof, arcanaListMerkleRoot) isNotPaused isMintOpen(Phases.ARCANA) {
    uint256 totalPrice = MINT_PRICE * _quantity;
    if (msg.value != totalPrice) revert PriceIncorrect();

    uint256 entitlements = getTotalEntitlements(msg.sender);
    if (entitlements + _quantity > MAX_ENTITLEMENTS_ALLOWED) revert MaxEntitlementsExceeded();

    _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity));

    _mint(msg.sender, _quantity);
  }

  // Aspirant List Mint
  /// @notice Mint function to invoke for ASPIRANT LIST PHASE addresses
  /// @dev Checks that enough ETH is paid, quantity to mint results in below max supply, is whitelisted, is not paused and below max quantity allowed per wallet address
  function mintAspirantList(bytes32[] calldata _merkleProof, uint256 _quantity) external payable isBelowMaxSupply(_quantity) isWhitelisted(_merkleProof, aspirantListMerkleRoot) isNotPaused isMintOpen(Phases.ASPIRANT){
    uint256 totalPrice = MINT_PRICE * _quantity;
    if (msg.value != totalPrice) revert PriceIncorrect();

    uint256 entitlements = getTotalEntitlements(msg.sender);
    if (entitlements + _quantity > MAX_ENTITLEMENTS_ALLOWED) revert MaxEntitlementsExceeded();

    _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity));

    _mint(msg.sender, _quantity);
  }

  // Alliance List Mint
  /// @notice Mint function to invoke for ALLIANCE LIST PHASE addresses
  /// @dev Checks that enough ETH is paid, quantity to mint results in below max supply, is whitelisted, is not paused and below max quantity allowed per wallet address

  function mintAllianceList(bytes32[] calldata _merkleProof, uint256 _quantity) external payable isBelowMaxSupply(_quantity) isWhitelisted(_merkleProof, allianceListMerkleRoot) isNotPaused isMintOpen(Phases.ALLIANCE){
    uint256 totalPrice = MINT_PRICE * _quantity;
    if (msg.value != totalPrice) revert PriceIncorrect();

    uint256 entitlements = getTotalEntitlements(msg.sender);
    if (entitlements + _quantity > MAX_ENTITLEMENTS_ALLOWED) revert MaxEntitlementsExceeded();

    _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity));

    _mint(msg.sender, _quantity);
  }

  // Public Mint
  /// @notice Mint function to invoke during public phase
  /// @dev Same conditions as whitelist and raffle mints, max 3 per wallet instead of 2, replay attack is mitigated by checking whether contract is minting and using signed unique nonce generated in the client.
  function mintPublic(uint256 _quantity, bytes32 _nonce, bytes32 _hash, uint8 v, bytes32 r, bytes32 s) external payable isBelowMaxSupply(_quantity) isNotPaused isMintOpen(Phases.PUBLIC) {
    if (tx.origin != msg.sender) revert ContractsNotAllowed();
    
    if (nonceRegistry[_nonce]) revert NonceConsumed();

    if (_hash != keccak256(
        abi.encodePacked(msg.sender, _quantity, _nonce)
    )) revert HashMismatched();

    bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));

    if (msg.sender != ecrecover(message, v, r, s)) revert SignedHashMismatched();

    nonceRegistry[_nonce] = true;

    uint256 totalPrice = MINT_PRICE * _quantity;
    if (msg.value != totalPrice) revert PriceIncorrect();


    uint256 totalMinted = getPublicListMints(msg.sender);
    if (totalMinted + _quantity > MAX_QUANTITY_ALLOWED) revert MaxQuantityAllowedExceeded();

    _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity << 2));

    _mint(msg.sender, _quantity);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    if (isTransfused) {
      uint256 assignedPFPId = (_tokenId + sequenceOffset) % MAX_SUPPLY;

      return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, assignedPFPId.toString(), ".json")) : "";
    }
    else {
      return notRevealedUri;
    }
  }

  /*Utility Methods*/

  function getBits(uint256 _input, uint256 _startBit, uint256 _length) private pure returns (uint256) {
    uint256 bitMask = ((1 << _length) - 1) << _startBit;

    uint256 outBits = _input & bitMask;

    return outBits >> _startBit;
  }

  function getTotalEntitlements(address _minter) public view returns (uint256) {
    return getBits(_getAux(_minter), 0, 2);
  }

  function getPublicListMints(address _minter) public view returns (uint256) {
    return getBits(_getAux(_minter), 2, 3);
  }

  /*Modifiers*/

  modifier isMintOpen(Phases phase) {
    if (uint(phase) != currentPhase) revert MintIsNotOpen();
    _;
  }

  modifier isNotPaused() {
    if (paused) revert ContractIsPaused();
    _;
  }

  modifier isBelowMaxSupply(uint256 _amount) {
    if ((totalSupply() + _amount) > MAX_SUPPLY) revert MaxSupplyExceeded();
    _;
  }

  /// @notice Verifies whitelist or raffle list
  /// @dev generate proof offchain and invoke mint function with proof as parameter
  modifier isWhitelisted(bytes32[] calldata _merkleProof, bytes32 _merkleRoot) {
    bytes32 node = keccak256(abi.encodePacked(msg.sender));
    if (!MerkleProof.verify(_merkleProof, _merkleRoot, node))
      revert MerkleProofInvalid();
    _;
  }

}