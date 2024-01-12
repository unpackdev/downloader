// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract Retrievers is ERC721Royalty, Ownable, ReentrancyGuard {
  // Smart contract status
  enum Status {
    CLOSED,
    LIST,
    PUBLIC
  }
  Status public status = Status.CLOSED;

  // Params
  string private _baseTokenURI;
  uint256 public supply = 5555;
  uint256 public price = 0.055 ether;
  uint256[2] public maxPerTxList = [3, 1];
  uint256 public maxPerTxPublic = 6;
  address public teamWalletAddress;

  // Total supply counter
  uint256 private _totalSupply = 0;

  // Mappings
  mapping(address => bool) private hasMintedList;
  mapping(address => bool) private hasMintedPublic;

  // Merkle tree
  bytes32[2] public merkleRoots;

  // Event declaration
  event ChangedStatusEvent(uint256 newStatus);
  event ChangedBaseURIEvent(string newURI);
  event ChangedMerkleRoot(uint256 list, bytes32 newMerkleRoot);
  event ChangedTeamWallet(address newAddress);

  // Modifier
  modifier checkSupply(uint256 _qty) {
    require(_totalSupply + _qty <= supply, "Quantity not available");
    _;
  }

  // Contructor
  constructor(string memory _URI) ERC721("Retrievers", "RETR") {
    setBaseURI(_URI);
  }

  // Mint
  function mint(uint256 _qty, bytes32[] calldata _proof) external payable nonReentrant checkSupply(_qty) {
    require(tx.origin == msg.sender, "Smart contract interactions disabled");
    require(status != Status.CLOSED, "Contract closed");
    require(_qty > 0, "Quantity must be greater than zero");
    require(msg.value == price * _qty, "Price not matched");

    if (status == Status.LIST) {
      uint256 _maxQuantity = getMaxQuantity(_proof);
      require(_maxQuantity > 0, "Not allowed");
      require(_qty <= _maxQuantity, "Quantity not allowed");
      require(!hasMintedList[msg.sender], "Already minted");
      hasMintedList[msg.sender] = true;
    } else {
      require(_qty <= maxPerTxPublic, "Quantity not allowed");
      require(!hasMintedPublic[msg.sender], "Already minted");
      hasMintedPublic[msg.sender] = true;
    }

    privateMint(_qty);
  }

  function teamMint(uint256 _qty) external nonReentrant checkSupply(_qty) {
    require(teamWalletAddress != address(0), "No team wallet address found");
    require(msg.sender == teamWalletAddress, "Not allowed");
    privateMint(_qty);
  }

  function privateMint(uint256 _qty) private {
    uint256 tmpIndex = _totalSupply;
    _totalSupply += _qty;
    for (uint256 i = 0; i < _qty; ++i) {
      _mint(msg.sender, tmpIndex + i);
    }
  }

  // Get maxQuantity
  function getMaxQuantity(bytes32[] calldata _proof) private view returns (uint256) {
    for (uint256 i = 0; i < merkleRoots.length; ++i) {
      if (checkProof(_proof, merkleRoots[i])) {
        return maxPerTxList[i];
      }
    }
    return 0;
  }

  // Merkle Proof validation
  function checkProof(bytes32[] calldata _proof, bytes32 _merkleRoot) private view returns (bool) {
    return MerkleProof.verify(_proof, _merkleRoot, keccak256(abi.encodePacked(msg.sender)));
  }

  // Getters
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenExists(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function getHasMinted(address _address) public view returns (bool) {
    if (status == Status.LIST) {
      return hasMintedList[_address];
    } else {
      return hasMintedPublic[_address];
    }
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  // Setters
  function setBaseURI(string memory _URI) public onlyOwner {
    _baseTokenURI = _URI;
    emit ChangedBaseURIEvent(_URI);
  }

  function setTeamWalletAddress(address _address) external onlyOwner {
    teamWalletAddress = _address;
    emit ChangedTeamWallet(_address);
  }

  function setStatus(uint256 _status) external onlyOwner {
    // _status -> 0: CLOSED, 1: LIST, 2: PUBLIC
    require(_status >= 0 && _status <= 2, "Mint status must be between 0 and 2");
    status = Status(_status);
    emit ChangedStatusEvent(_status);
  }

  function setMerkleRoots(bytes32[2] calldata _merkleRoots) external onlyOwner {
    for (uint256 i = 0; i < merkleRoots.length; i++) {
      merkleRoots[i] = _merkleRoots[i];
      emit ChangedMerkleRoot(i, _merkleRoots[i]);
    }
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  // Withdraw
  function withdraw(address payable withdrawAddress) external payable nonReentrant onlyOwner {
    require(withdrawAddress != address(0), "Withdraw address cannot be zero");
    require(address(this).balance >= 0, "Not enough eth");
    payable(withdrawAddress).transfer(address(this).balance);
  }
}
