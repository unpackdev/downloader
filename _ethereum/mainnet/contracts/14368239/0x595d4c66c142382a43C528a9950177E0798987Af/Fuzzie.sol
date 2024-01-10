// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Counters.sol";
import "./AccessControl.sol";

/**
 * @title Fuzzie
 * Fuzzie - a contract for my non-fungible creatures.
 */
contract Fuzzie is ERC721Tradable {
  using Counters for Counters.Counter;

  bool _revealed = false;
  bool _paused = true;
  bool _locked = false; // When all phases are complete we lock the contract.

  // An address we own, can be changed.
  address _airdropMintAddress = 0x56f4DC083Ab7455793A1c5FfaB3957279E1003df;

  string baseURI;
  string baseExtension = '.json';
  string unreleasedPhaseUri = 'ipfs://QmXbAUKGfLitQwAi56gkkSH9oaGD7gAfwbBbD67xuj5MWT';
  string contractUri = 'ipfs://QmRKKXwqFmTjtyK8bNq7skeXrqczZpEuKdZgHdynxgnAYo';

  uint256 _maxPhase = 7; // The number of completion
  uint256 _maxSupply = 0;
  uint256 _mintPhase = 0;
  uint256 _mintFundTrxAmount = 0.022 ether;
  uint256 _cost = 0.05 ether;
  uint256 nftPerAddressLimit = 300;
  uint256 _createTokenModulus = 20;
  uint256 _lastFreeTokenId = 0;

  Counters.Counter private _projectPhase;

  mapping(address => uint256) private addressMintedBalance;
  mapping(uint256 => string) private phaseUri;
  mapping(uint256 => uint256) private maxTokenToPhase;

  event CreateFreeToken(uint256 indexed _tokenId);

  bytes32 public constant SERVICE_ROLE = keccak256('SERVICE_ROLE');
  bytes32 public constant OPENSEA_FACTORY_ROLE = keccak256('OPENSEA_FACTORY_ROLE');

  constructor(address _proxyRegistryAddress, address _adminRoleAddress) ERC721Tradable('MetaFuzzies', 'MFUZZ', _proxyRegistryAddress) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    if (msg.sender != _adminRoleAddress) {
      _grantRole(DEFAULT_ADMIN_ROLE, _adminRoleAddress);
    }
    _grantRole(DEFAULT_ADMIN_ROLE, address(this));

    // Starting at phase 1 since it sound better for humans
    maxTokenToPhase[_projectPhase.current()] = 0;
    _projectPhase.increment();
    _mintPhase = 1;

    // Configure initial phase here. Number of Fuzzies and baseURI
    // First phase is hard coded
    maxTokenToPhase[_projectPhase.current()] = 20;
    _maxSupply = 20;

    // Give founders some Fuzzies
    for (uint256 i = 1; i <= 10; i++) {
      _mintTo(_adminRoleAddress);
    }
  }

  // **********************
  // Minting functions
  // **********************
  function directMint(uint256 _mintAmount) public payable {
    // Check that the sender can mint
    if (msg.sender != owner()) {
      require(_maxSupply >= totalSupply() + _mintAmount, string(abi.encodePacked('Minting would exceed total supply!')));
      require(_projectPhase.current() == _mintPhase, string(abi.encodePacked('Minting is disabled for this phase, ', Strings.toString(_mintPhase))));
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, 'Max NFT per address exceeded');
      require(msg.value >= _cost * _mintAmount, string(abi.encodePacked('This mint costs ', Strings.toString(_cost / 1e18), ' ether per token.')));
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      mintTo(msg.sender);
    }
  }

  function randomMint() public payable {
    // Check that the sender can mint
    if (msg.sender != owner()) {
      require(_maxSupply > totalSupply(), string(abi.encodePacked('Minting would exceed total supply!')));
      require(_projectPhase.current() == _mintPhase, string(abi.encodePacked('Minting is disabled for this phase, ', Strings.toString(_mintPhase))));
      // Allow random mints to exceed limit on address
      require(msg.value >= (_cost * 1) / 2, string(abi.encodePacked('This mint costs ', Strings.toString((_cost * 1) / 2e18), ' ether per token.')));
    }
    uint256 winningTokenId = random(totalSupply());
    address addressToMintTo = ownerOf(winningTokenId);
    mintTo(addressToMintTo);
    addressMintedBalance[addressToMintTo]++;
  }

  function airdropMint() public payable onlyRole(SERVICE_ROLE) {
    uint256 winningTokenId = random(totalSupply());
    address addressToMintTo = ownerOf(winningTokenId);
    _lastFreeTokenId = _nextTokenId.current();
    // Ensure the airdrop wallet always has funds to mint.
    (bool os, ) = payable(_airdropMintAddress).call{value: _mintFundTrxAmount}('');
    require(os);

    mintTo(addressToMintTo);
    addressMintedBalance[addressToMintTo]++;
  }

  function factoryMint(address _to) public onlyRole(OPENSEA_FACTORY_ROLE) {
    mintTo(_to);
  }

  function mintTo(address _to) internal {
    require(!_paused, 'Minting is paused!');
    _mintTo(_to);
    if (shouldCreateFreeToken(totalSupply())) {
      emit CreateFreeToken(_lastFreeTokenId);
    }
  }

  // **********************
  // URI functions
  // **********************
  function contractURI() public view returns (string memory) {
    return contractUri;
  }

  // The Factory contract uses this
  function baseTokenURI() public view virtual override returns (string memory) {
    return phaseUri[_projectPhase.current()];
  }

  // All base URI calls should use this function
  function getBaseURIForPhase(uint256 phaseId) public view returns (string memory) {
    return phaseUri[phaseId];
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (_revealed == false) {
      return unreleasedPhaseUri;
    }

    uint256 tokenPhase = getPhaseForTokenId(tokenId);

    string memory phaseBaseURI = getBaseURIForPhase(tokenPhase);

    return bytes(phaseBaseURI).length > 0 ? string(abi.encodePacked(phaseBaseURI, Strings.toString(tokenId), baseExtension)) : unreleasedPhaseUri;
  }

  // **********************
  // General information functions
  // **********************
  function getPhaseForTokenId(uint256 tokenId) public view returns (uint256) {
    uint256 counter = 0;
    while (tokenId > maxTokenToPhase[counter]) {
      counter += 1;
    }
    return counter;
  }

  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  function projectPhase() public view returns (uint256) {
    return _projectPhase.current();
  }

  function paused() public view returns (bool) {
    return _paused;
  }

  function revealed() public view returns (bool) {
    return _revealed;
  }

  function locked() public view returns (bool) {
    return _locked;
  }

  function price() public view returns (uint256) {
    return _cost;
  }

  function lastFreeTokenId() public view returns (uint256) {
    return _lastFreeTokenId;
  }

  // **********************
  // Configuration functions
  // **********************
  function setCost(uint256 _newCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    _cost = _newCost;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    nftPerAddressLimit = _limit;
  }

  // We can only modify the current phase, all previous phases are set
  function setBaseURIForPhase(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    phaseUri[_projectPhase.current()] = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    baseExtension = _newBaseExtension;
  }

  function setUnreleasedPhaseUri(string memory _unreleasedPhaseUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    unreleasedPhaseUri = _unreleasedPhaseUri;
  }

  function setRevealed(bool _newRevealed) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    _revealed = _newRevealed;
  }

  function setPaused(bool _newPaused) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    _paused = _newPaused;
  }

  function setContractUri(string memory _contractUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    contractUri = _contractUri;
  }

  function setMintPhaseRestriction(uint256 phase) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!_locked, 'Contract is locked and can no longer be changed');
    _mintPhase = phase;
  }

  function setAirdropAddress(address newAddress, uint256 gasPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _airdropMintAddress = newAddress;
    _mintFundTrxAmount = gasPrice;
  }

  function progressPhase(uint256 numberOfTokens) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_projectPhase.current() < _maxPhase, 'No more phases to step to');

    string memory phaseBaseURI = getBaseURIForPhase(_projectPhase.current());
    require(bytes(phaseBaseURI).length > 0, 'Cannot progress a phase without a baseURI set for current phase.');

    // Get the token id for the last token in this phase
    // Update the mapping of tokens to phases and then store the max supply in a local variable for easy access
    uint256 currentMaxToken = maxTokenToPhase[_projectPhase.current()];
    _projectPhase.increment();
    _maxSupply = currentMaxToken + numberOfTokens;
    maxTokenToPhase[_projectPhase.current()] = _maxSupply;
  }

  function lockFinalPhase() public onlyRole(DEFAULT_ADMIN_ROLE) {
    string memory phaseBaseURI = getBaseURIForPhase(_projectPhase.current());
    require(bytes(phaseBaseURI).length > 0, 'Cannot lock without baseURI set for current phase.');
    _locked = true;
  }

  // **********************
  // Utility functions
  // **********************

  // This is a pseudo random number
  function random(uint256 max) internal view returns (uint256) {
    uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, max - 1)));
    return (randomHash % max) + 1;
  }

  function shouldCreateFreeToken(uint256 tokenId) public view returns (bool) {
    return tokenId % _createTokenModulus == 0 && _lastFreeTokenId < tokenId && tokenId < _maxSupply; // No airdrop if it is the last token in supply
  }

  function withdraw(address add1, address add2) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
    require(add1 == address(add1),"Invalid address 1");
    require(add2 == address(add2),"Invalid address 2");

    (bool os1, ) = payable(add1).call{value: address(this).balance / 2}('');
    require(os1);
    (bool os2, ) = payable(add2).call{value: address(this).balance}('');
    require(os2);
  }
}
