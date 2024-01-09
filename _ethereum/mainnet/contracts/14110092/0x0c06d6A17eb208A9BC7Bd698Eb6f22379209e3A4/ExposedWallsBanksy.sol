// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title ExposedWallsBanksy
 * @author thenftprofessor@protonmail.com
 * @notice Implements the Exposed Walls Banksy (EWB) collection contract.
 */
contract ExposedWallsBanksy is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  bytes32 public merkleRoot;
  uint256 public whitelistSales;
  uint256 public defaultSales;
  uint256 public tokenPrice = 0.3 ether;
  uint256 constant MAX_SUPPLY = 10000;
  uint256 constant WHITELIST_MAX = 4000;
  uint256 public whitelistTokensCount;
  uint16[] private tokenPool;
  address public shareholder1 = 0x5db8Bb85D6065f95350d8AE3934D72Ad0aB3Ae7E;
  address public shareholder2 = 0x04d59D5699E1B28161eA972fFD81a6705bFEB8A3;
  address public shareholder3 = 0x3C0EcBB13359F3Ae982853c0BEbd1747D97A3ca3;
  bool public paused;
  bool public revealed;
  bool public isPoolSet;
  bool public freezedMetadata;

  event Mint(uint256 indexed tokenId);
  event MintWhitelist(uint256 amount, address indexed to, uint256 addToWhitelistSales);
  event MintDefault(uint256 amount, address indexed to, uint256 addToDefaultSales);

  modifier onlyShareholder() {
    require(
      msg.sender == shareholder1 ||
        msg.sender == shareholder2 ||
        msg.sender == shareholder3,
      "The caller is not a shareholder"
    );
    _;
  }

  modifier onlyCompletedPool() {
    require(isPoolSet, "Wait until all tokens are available");
    _;
  }

  constructor(string memory baseURI_, bytes32 _merkleRoot)
    ERC721("Exposed Walls Banksy", "EWB")
  {
    baseURI = baseURI_;
    merkleRoot = _merkleRoot;
  }

  function mint(
    bytes32[] calldata _merkleProof,
    uint256 _mintAmount,
    uint256 _clientNumber
  ) public payable nonReentrant onlyCompletedPool {
    require(!paused, "Please wait until unpaused");
    require(_mintAmount > 0, "Mint at least one token");
    require(
      _mintAmount <= tokenPool.length,
      "Not enough tokens left to mint that many"
    );
    require(msg.value == tokenPrice * _mintAmount, "Incorrect ether amount");

    if (      
      whitelistTokensCount < WHITELIST_MAX &&
      isWhitelisted(msg.sender, _merkleProof)
    ) {
      if(whitelistTokensCount + _mintAmount <= WHITELIST_MAX) {
        whitelistSales += msg.value;
        whitelistTokensCount += _mintAmount;
        emit MintWhitelist(_mintAmount, msg.sender, msg.value);
      } else {
        uint256 toDefault = whitelistTokensCount + _mintAmount - WHITELIST_MAX;
        uint256 toWhitelist = _mintAmount - toDefault;
        uint256 addToWhitelistSales = msg.value * toWhitelist / _mintAmount;
        uint256 addToDefaultSales = msg.value * toDefault / _mintAmount;
        emit MintDefault(toDefault, msg.sender, addToDefaultSales);
        emit MintWhitelist(toWhitelist, msg.sender, addToWhitelistSales);
        whitelistSales += addToWhitelistSales;
        defaultSales += addToDefaultSales;
        
        whitelistTokensCount = WHITELIST_MAX;
      }
    } else {
      defaultSales += msg.value;
      emit MintDefault(_mintAmount, msg.sender, msg.value);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _mint(msg.sender, _clientNumber, i);
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "tokenID does not exist");

    string memory currentBaseURI = _baseURI();
    return
      string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
  }

  function isWhitelisted(address _user, bytes32[] calldata _merkleProof)
    public
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(_user));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function totalSupply() external view returns (uint256) {
    return isPoolSet ? MAX_SUPPLY - tokenPool.length : 0;
  }

  ///@notice This function mint one token for each address of the given list.
  function airdropList(address[] memory _users, uint256 _clientNumber)
    external
    onlyOwner
    nonReentrant
    onlyCompletedPool
  {
    require(tokenPool.length - _users.length >= 0, "Not this many tokens left");

    for (uint256 i = 0; i < _users.length; i++) {
      _mint(_users[i], _clientNumber, i);
    }
  }

  ///@notice This function mint _amount of token to the given address.
  function airdropUser(
    address _user,
    uint256 _amount,
    uint256 _clientNumber
  ) external onlyOwner nonReentrant onlyCompletedPool {
    require(tokenPool.length - _amount >= 0, "Not this many tokens left");

    for (uint256 i = 0; i < _amount; i++) {
      _mint(_user, _clientNumber, i);
    }
  }

  function withdraw() external nonReentrant onlyShareholder {
    uint256 shareholder1Allowance = (5700 * whitelistSales) / 10000; // 57%
    uint256 shareholder2Allowance = (4000 * whitelistSales) / 10000; // 40%
    uint256 shareholder3Allowance = (300 * whitelistSales) / 10000; // 3%

    shareholder1Allowance += (8200 * defaultSales) / 10000; // 82%
    shareholder2Allowance += (1500 * defaultSales) / 10000; // 15%
    shareholder3Allowance += (300 * defaultSales) / 10000; // 3%

    (bool success, ) = payable(shareholder1).call{
      value: shareholder1Allowance
    }("");
    require(success);
    (success, ) = payable(shareholder2).call{ value: shareholder2Allowance }(
      ""
    );
    require(success);
    (success, ) = payable(shareholder3).call{ value: shareholder3Allowance }(
      ""
    );
    require(success);

    whitelistSales = 0;
    defaultSales = 0;
  }

  function setBaseURI(string memory _newURI) external onlyOwner {
    require(!freezedMetadata, "Metadata is frozen");
    baseURI = _newURI;
  }

  function setPaused(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function setWhitelist(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    tokenPrice = _newPrice;
  }

  function freezeMetadata() external onlyOwner {
    freezedMetadata = true;
  }

  function updateShareholder1(address _newWallet) external {
    require(msg.sender == shareholder1, "Only shareholder 1");
    shareholder1 = _newWallet;
  }

  function updateShareholder2(address _newWallet) external {
    require(msg.sender == shareholder2, "Only shareholder 2");
    shareholder2 = _newWallet;
  }

  function updateShareholder3(address _newWallet) external {
    require(msg.sender == shareholder3, "Only shareholder 3");
    shareholder3 = _newWallet;
  }

  function pushTokenIds(uint16 _amount) external {
    require(!isPoolSet, "All tokens were added");

    uint16 from = uint16(tokenPool.length);
    require(from + _amount <= MAX_SUPPLY, "Not enough slots in the tokenPool");

    for (uint16 tokenId = from + 1; tokenId <= from + _amount; tokenId++) {
      tokenPool.push(tokenId); // token ids
    }

    if (tokenPool.length == MAX_SUPPLY) {
      isPoolSet = true;
    }
  }

  function _mint(
    address _user,
    uint256 _clientNumber,
    uint256 _iterator
  ) internal {
    uint256 index = _random(_clientNumber + _iterator);
    uint256 _tokenId = uint256(tokenPool[index]);
    _safeMint(_user, _tokenId);
    tokenPool[index] = tokenPool[tokenPool.length - 1];
    tokenPool.pop();
    emit Mint(_tokenId);
  }

  function _random(uint256 counter) internal view returns (uint256) {
    uint256 value = uint256(
      keccak256(
        abi.encode(block.difficulty, block.timestamp, counter, msg.sender)
      )
    );
    return (value % tokenPool.length);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenPoolCount() public view returns (uint256) {
    return tokenPool.length;
  }
}
