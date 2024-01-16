// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract CosmicMushrooms is ERC721A, Ownable {
  using Strings for uint256;
  
  string public baseURI;
  string public baseExtension = ".json";
  bytes32 public whitelistMerkleRoot = "";
  uint256 public maxMintPerWhitelistTx = 50;
  uint256 public cost = 0.05 ether;
  uint256 public constant MAX_SUPPLY = 1111;

  bool public paused = true;
  bool public isWhitelistSaleActive = false;
  bool public hasTeamReserved = false;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  modifier pausedCompliance() {
    require(!paused, "Minting is currently paused");
    _;
  }

  modifier amountCompliance(uint256 _value, uint256 _amount) {
    require(_value >= _amount * cost, "Insufficient funds sent");
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata _merkleProof, bytes32 _root) {
    require(
      MerkleProof.verify(
        _merkleProof,
        _root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Whitelist merkle proof is invalid"
    );
    _;
  }

  function reserve(uint256 _amount, address _recipient) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _amount <= MAX_SUPPLY, "Insufficient supply remaining");
    _safeMint(_recipient, _amount);
  }

  function whitelistMint(
    uint256 _amount,
    bytes32[] calldata _merkleProof
  )
    public
    payable
    pausedCompliance
    amountCompliance(msg.value, _amount)
    isValidMerkleProof(_merkleProof, whitelistMerkleRoot)
  {
    uint256 supply = totalSupply();
    require(isWhitelistSaleActive, "Whitelist sale is not active");
    require(supply + _amount <= MAX_SUPPLY, "Insufficient whitelist supply remaining");
    _safeMint(msg.sender, _amount);
  }

  function mint(uint256 _amount) public payable pausedCompliance amountCompliance(msg.value, _amount) {
    uint256 supply = totalSupply();
    require(supply + _amount <= MAX_SUPPLY, "Insufficient supply remaining");
    _safeMint(msg.sender, _amount);
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

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension)
        )
        : "";
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintPerWhitelistTx(uint256 _maxMintPerWhitelistTx) public onlyOwner {
    maxMintPerWhitelistTx = _maxMintPerWhitelistTx;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _baseExtension) public onlyOwner {
    baseExtension = _baseExtension;
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
    whitelistMerkleRoot = _whitelistMerkleRoot;
  }

  function setIsWhitelistSaleActive(bool _isWhitelistSaleActive) public onlyOwner {
    isWhitelistSaleActive = _isWhitelistSaleActive;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }
}