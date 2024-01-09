//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ICritterzMetadata.sol";
import "./ERC721Stakable.sol";

contract Critterz is ERC721Stakable, ReentrancyGuardUpgradeable {
  uint256 internal constant MAX_SUPPLY = 4096;
  uint256 internal constant RESERVE_SUPPLY = 192;
  uint256 internal constant PUBLIC_SUPPLY = MAX_SUPPLY - RESERVE_SUPPLY;
  uint256 internal constant PRICE = 0.05 ether;
  uint256 internal constant MAX_MINT_PER_TRANSACTION = 4;
  uint256 internal constant WHITELIST_MAX_MINT_PER_WALLET = 2;

  address public metadataAddress;

  bytes32 public whitelistMerkleRoot;
  bytes32 public ogWhitelistMerkleRoot;
  string public whitelistURI;
  string public ogWhitelistURI;

  bool public whitelistMintOpen;
  bool public publicMintOpen;

  uint256 public totalSupply;

  uint256 internal _reserveMinted;

  mapping(address => uint256) public whitelistMintedCounts;

  event WhitelistMintOpen();
  event PublicMintOpen();

  function initialize(address _stakingAddress, address _metadataAddress)
    public
    initializer
  {
    __ERC721Stakable_init("Critterz", "CRTZ");
    __ReentrancyGuard_init_unchained();

    stakingAddress = _stakingAddress;
    metadataAddress = _metadataAddress;
  }

  /*
  WRITE FUNCTIONS
  */

  function mint(uint256 amount, bool stake) external payable noContract {
    require(
      totalSupply + amount <= PUBLIC_SUPPLY,
      "Critterz supply limit reached"
    );
    require(publicMintOpen, "Public minting closed");
    require(msg.value == PRICE * amount, "Critterz price mismatch");
    require(amount <= MAX_MINT_PER_TRANSACTION, "Amount too large");
    _mintHelper(msg.sender, amount, stake);
  }

  function whitelistMint(
    uint256 amount,
    bool stake,
    bytes32[] calldata whitelistProof
  ) external payable onlyWhitelist(whitelistProof) {
    uint256 whitelistMintedCount = whitelistMintedCounts[msg.sender];
    uint256 newWhitelistMintedCount = whitelistMintedCount + amount;
    require(
      totalSupply + amount <= PUBLIC_SUPPLY,
      "Critterz supply limit reached"
    );
    require(whitelistMintOpen, "Whitelist minting closed");
    require(
      newWhitelistMintedCount <= WHITELIST_MAX_MINT_PER_WALLET,
      "Whitelist mint amount too large"
    );
    require(msg.value == PRICE * amount, "Critterz price mismatch");

    whitelistMintedCounts[msg.sender] = newWhitelistMintedCount;
    _mintHelper(msg.sender, amount, stake);
  }

  function ogWhitelistMint(
    uint256 amount,
    bool stake,
    bytes32[] calldata whitelistProof
  ) external payable onlyOgWhitelist(whitelistProof) {
    uint256 whitelistMintedCount = whitelistMintedCounts[msg.sender];
    uint256 newWhitelistMintedCount = whitelistMintedCount + amount;
    uint256 freeMints = whitelistMintedCount == 0 ? 1 : 0;
    require(
      totalSupply + amount <= PUBLIC_SUPPLY,
      "Critterz supply limit reached"
    );
    require(whitelistMintOpen, "Whitelist minting closed");
    require(
      newWhitelistMintedCount <= WHITELIST_MAX_MINT_PER_WALLET + 1,
      "OG whitelist mint amount too large"
    );
    require(
      msg.value == PRICE * (amount - freeMints),
      "Critterz price mismatch"
    );

    whitelistMintedCounts[msg.sender] = newWhitelistMintedCount;
    _mintHelper(msg.sender, amount, stake);
  }

  function _mintHelper(
    address account,
    uint256 amount,
    bool stake
  ) internal nonReentrant {
    require(amount > 0, "Amount too small");
    uint256 _totalSupply = totalSupply;
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(
        stake ? stakingAddress : account,
        _totalSupply + i,
        abi.encode(account)
      );
    }
    // this could be vulnerable to reentracy attacks
    totalSupply += amount;
  }

  /*
  READ FUNCTIONS
  */

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    ICritterzMetadata metadataContract = ICritterzMetadata(metadataAddress);
    // reveal metadata if seed is set
    if (metadataContract.seed() > 0) {
      return metadataContract.getMetadata(tokenId, false, new string[](0));
    } else {
      return
        metadataContract.getPlaceholderMetadata(
          tokenId,
          false,
          new string[](0)
        );
    }
  }

  function availableWhitelistMint(bytes32[] memory whitelistProof)
    external
    view
    returns (uint256)
  {
    if (_inWhitelist(whitelistProof)) {
      return WHITELIST_MAX_MINT_PER_WALLET - whitelistMintedCounts[msg.sender];
    } else {
      return 0;
    }
  }

  function availableOgWhitelistMint(bytes32[] memory whitelistProof)
    external
    view
    returns (uint256)
  {
    if (_inOgWhitelist(whitelistProof)) {
      return
        WHITELIST_MAX_MINT_PER_WALLET + 1 - whitelistMintedCounts[msg.sender];
    } else {
      return 0;
    }
  }

  function _verify(
    bytes32[] memory proof,
    bytes32 root,
    address _address
  ) internal pure returns (bool) {
    return
      MerkleProof.verify(proof, root, keccak256(abi.encodePacked(_address)));
  }

  function _inWhitelist(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, whitelistMerkleRoot, msg.sender);
  }

  function _inOgWhitelist(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, ogWhitelistMerkleRoot, msg.sender);
  }

  /*
  OWNER FUNCTIONS
  */

  function setPublicMintOpen(bool open) external onlyOwner {
    publicMintOpen = open;
    emit PublicMintOpen();
  }

  function setWhitelistMintOpen(bool open) external onlyOwner {
    whitelistMintOpen = open;
    emit WhitelistMintOpen();
  }

  function setMetadataAddress(address _metadataAddress) external onlyOwner {
    metadataAddress = _metadataAddress;
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
    external
    onlyOwner
  {
    whitelistMerkleRoot = _whitelistMerkleRoot;
  }

  function setWhitelistURI(string calldata _whitelistURI) external onlyOwner {
    whitelistURI = _whitelistURI;
  }

  function setOgWhitelistMerkleRoot(bytes32 _ogWhitelistMerkleRoot)
    external
    onlyOwner
  {
    ogWhitelistMerkleRoot = _ogWhitelistMerkleRoot;
  }

  function setOgWhitelistURI(string calldata _ogWhitelistURI)
    external
    onlyOwner
  {
    ogWhitelistURI = _ogWhitelistURI;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function reserveMint(
    address to,
    uint256 amount,
    bool stake
  ) public onlyOwner {
    uint256 newReserveMinted = _reserveMinted + amount;
    require(
      totalSupply + amount <= MAX_SUPPLY,
      "Critterz supply limit reached"
    );
    require(newReserveMinted <= RESERVE_SUPPLY, "Reserve mint limit reached");
    _reserveMinted = newReserveMinted;
    _mintHelper(to, amount, stake);
  }

  /*
  MODIFIER
  */

  modifier noContract() {
    address account = msg.sender;
    require(account == tx.origin, "Caller is a contract");
    uint256 size = 0;
    assembly {
      size := extcodesize(account)
    }
    require(size == 0, "Caller is a contract");
    _;
  }

  modifier onlyWhitelist(bytes32[] memory whitelistProof) {
    require(_inWhitelist(whitelistProof), "Caller is not whitelisted");
    _;
  }

  modifier onlyOgWhitelist(bytes32[] memory whitelistProof) {
    require(_inOgWhitelist(whitelistProof), "Caller is not OG whitelisted");
    _;
  }
}
