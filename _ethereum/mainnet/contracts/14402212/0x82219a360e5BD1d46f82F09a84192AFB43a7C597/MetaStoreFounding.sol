// SPDX-License-Identifier: MIT AND GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

interface IStateTunnel {
    function sendTransferMessage(bytes calldata _data) external;
}

contract MetaStoreLandmark is ERC721A, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public publicSalePrice = 0.188 ether;
  uint256 public publicSaleTime;
  uint256 public preSalePrice = 0.168 ether;
  uint256 public preSaleTime;
  uint256 public teamReverseMinted = 0;
  uint256 public maxTeamReverseNum = 100;
  uint256 public maxTotalSupply = 100;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 1;

  bool public paused = false;
  bool public isPreSaleActive = false;
  bool public isPublicSaleActive = false;

  bool private isStateTunnelEnabled = false;
  IStateTunnel private stateTunnel;

  constructor(
    string memory _initBaseURI
  ) ERC721A("MetaStore Founding", "MSF") {
    setBaseURI(_initBaseURI);
    _safeMint(owner(), 1);
    _burn(0);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 0;
  }

  function currentIndex() public view returns (uint256) {
    return _currentIndex;
  }

  modifier mintValidate(uint256 _mintAmount) {
    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(tx.origin == msg.sender, "contracts not allowed");
    require(totalSupply() + _mintAmount <= maxTotalSupply, "exceeds max supply");
    _;
  }

  function teamReserveMint(uint256 _mintAmount) public mintValidate(_mintAmount) onlyOwner {
    require(
      teamReverseMinted + _mintAmount <= maxTeamReverseNum,
      'exceeds max team reversed NFTs'
    );
    _safeMint(owner(), _mintAmount);
    teamReverseMinted += _mintAmount;
  }

  function preSaleMint(uint256 _mintAmount, bytes32[] calldata proof_) public mintValidate(_mintAmount) payable {
    require(isPreSaleActive, "minting not enabled");
    require(checkAllowlist(proof_), 'address is not on the whitelist');
    require(
      _numberMinted(msg.sender) + _mintAmount <= nftPerAddressLimit,
      'exceeds max available NFTs per address'
    );
    require(block.timestamp >= preSaleTime, 'It is not pre-sale time');

    require(msg.value == preSalePrice * _mintAmount, "wrong payment amount");
    _safeMint(msg.sender, _mintAmount);
  }

  function publicMint(uint256 _mintAmount) public mintValidate(_mintAmount) payable {
    require(isPublicSaleActive, "minting not enabled");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(block.timestamp >= publicSaleTime, 'It is not public sale time');

    require(msg.value == publicSalePrice * _mintAmount, "wrong payment amount");
    _safeMint(msg.sender, _mintAmount);

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

    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    if(isStateTunnelEnabled) {
      bytes memory parameter = abi.encode(from, to, startTokenId, quantity, address(this));
      stateTunnel.sendTransferMessage(parameter);
    }
  }

  //only owner
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setPreSalePrice(uint256 _newPreSalePrice) public onlyOwner {
    preSalePrice = _newPreSalePrice;
  }

  function setPublicSalePrice(uint256 _newPublicSalePrice) public onlyOwner {
    publicSalePrice = _newPublicSalePrice;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setPause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setIsPreSaleActive(bool _state) public onlyOwner {
    isPreSaleActive = _state;
  }

  function setIsPublicSaleActive(bool _state) public onlyOwner {
    isPublicSaleActive = _state;
  }
  
  function setPublicSaleTime(uint256 _publicSaleTime) external onlyOwner {
    publicSaleTime = _publicSaleTime;
  }

  function setPreSaleTime(uint256 _preSaleTime) external onlyOwner {
    preSaleTime = _preSaleTime;
  }
 
  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{ value: address(this).balance }('');
    require(success, 'failed to withdraw money');
  }

  function setStateTunnel(address _stateTunnel) public onlyOwner {
    stateTunnel = IStateTunnel(_stateTunnel);
  }

  function setStateTunnelEnabled(bool _enabled) public onlyOwner {
    isStateTunnelEnabled = _enabled;
  }

  //
  bytes32 private merkleRoot;
  function checkAllowlist(bytes32[] calldata proof)
    public
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}
