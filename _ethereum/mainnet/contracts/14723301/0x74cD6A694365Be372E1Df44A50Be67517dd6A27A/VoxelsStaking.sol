// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ECDSA.sol";

interface IVoxelsNFT is IERC721 {
  function totalSupply() external view returns (uint256);

  function wires(uint256) external view returns (uint256);

  function stages(uint256) external view returns (uint256);
}

contract VoxelsStaking is
  Initializable,
  OwnableUpgradeable,
  IERC721Receiver,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using EnumerableSet for EnumerableSet.UintSet;
  using ECDSA for bytes32;

  // Mapping from an address to manage and control states
  mapping(address => bool) public admins;

  IVoxelsNFT public voxelsNFT;
  IERC20 public wireToken;

  struct RankRequest {
    uint256[] tokenIds;
    uint256[] ranks;
    string nonce;
  }

  uint256 public expiration;
  // 1 $WIRE per day = 173,611,111,111,111
  uint256 public rate;
  // Rate of Multiplier if all Three Voxel Groups are staked
  uint256 public multiplierRate;

  uint256 public totalStaked;
  uint256 public voxelTotalSupply; // 4242 voxels
  uint256 public genesisTotalSupply; // 1414 genesises
  bool public claimActive;

  address internal _signer;

  mapping(address => EnumerableSet.UintSet) private _deposits;
  mapping(address => mapping(uint256 => uint256)) public _depositBlocks;
  mapping(string => bool) private _nonce;
  mapping(uint256 => uint256) private lastRank;
  mapping(address => mapping(uint256 => uint256)) public cubeTypesStaked;

  modifier onlyAdmin() {
    require(admins[msg.sender], "Only Admin can execute");
    _;
  }

  function initialize(
    address _voxelsNFT,
    uint256 _rate,
    uint256 _multiplierRate,
    uint256 _expiration,
    address _wireToken
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    voxelsNFT = IVoxelsNFT(_voxelsNFT);
    rate = _rate;
    multiplierRate = _multiplierRate;
    expiration = block.timestamp + _expiration;
    wireToken = IERC20(_wireToken);
    _signer = 0xbd137bd879C99e5B13e1bce1C617FdB4b0478E91;
    voxelTotalSupply = 4242;
    genesisTotalSupply = 1414;
    admins[msg.sender] = true;
    pause();
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function setRate(uint256 _rate) public onlyAdmin {
    rate = _rate;
  }

  function setMultiplierRate(uint256 _multiplierRate) public onlyAdmin {
    multiplierRate = _multiplierRate;
  }

  function setExpiration(uint256 _expiration) public onlyAdmin {
    expiration = block.timestamp + _expiration;
  }

  function setVoxelTotalSupply(uint256 _voxelTotalSupply) external onlyAdmin {
    voxelTotalSupply = _voxelTotalSupply;
  }

  function setGenesisTotalSupply(uint256 _genesisTotalSupply)
    external
    onlyAdmin
  {
    genesisTotalSupply = _genesisTotalSupply;
  }

  function depositsOf(address account) public view returns (uint256[] memory) {
    EnumerableSet.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[](depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = depositSet.at(i);      
    }

    return tokenIds;
  }

  function calculateRewards(
    address account,
    uint256[] memory tokenIds,
    uint256[] memory ranks
  ) public view returns (uint256) {
    require(tokenIds.length == ranks.length, "Ranks must be matched");

    uint256 reward = 0;
    uint256 i;
    uint256 multiplerCheck;

    for (i = 0; i < tokenIds.length; i++) {
      multiplerCheck |= 1 << (2**((tokenIds[i] - 1) / 1414));
    }

    for (i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      uint16 isDeposited = _deposits[account].contains(tokenId) ? 1 : 0;

      reward +=
        _getStakingRate(
          tokenId,
          ranks[i],
          multiplerCheck == 22 ? multiplierRate : 100
        ) *
        isDeposited *
        (Math.min(block.timestamp, expiration) - _depositBlocks[account][tokenId]) * 1e18
        / 1 days;
    }

    return reward;
  }

  function claimRewards(bytes calldata requestData, bytes calldata signature)
    public
    whenNotPaused
  {
    (
      uint256[] memory tokenIds,
      uint256[] memory ranks,
    )  = _validateRequest(requestData, signature);

    uint256 reward = calculateRewards(msg.sender, tokenIds, ranks);
    uint256 blockCur = Math.min(block.timestamp, expiration);

    for (uint256 i; i < tokenIds.length; i++) {
      _depositBlocks[msg.sender][tokenIds[i]] = blockCur;
      lastRank[tokenIds[i]] = ranks[i];
    }

    if (reward > 0) {
      IERC20(wireToken).transfer(msg.sender, reward);
    }
  }

  function _validateRequest(
    bytes calldata requestData,
    bytes calldata signature
  )
    internal
    returns (
      uint256[] memory,
      uint256[] memory,
      string memory
    )
  {
    RankRequest memory request = abi.decode(requestData, (RankRequest));

    uint256[] memory tokenIds = request.tokenIds;
    uint256[] memory ranks = request.ranks;
    string memory nonce = request.nonce;
    require(!_nonce[nonce], "Already used");

    bytes32 requestHash = keccak256(
      abi.encodePacked(address(this), msg.sender, requestData)
    );

    address signerFromHash = requestHash.toEthSignedMessageHash().recover(
      signature
    );
    require(signerFromHash == _signer, "Invalid Signer");
    _nonce[nonce] = true;
    return (tokenIds, ranks, nonce);
  }

  function deposit(bytes calldata requestData, bytes calldata signature)
    external
    whenNotPaused
  {
    RankRequest memory request = abi.decode(requestData, (RankRequest));
    uint256[] memory tokenIds = request.tokenIds;    
    require(msg.sender != address(voxelsNFT), "Invalid address");
    claimRewards(requestData, signature);

    for (uint256 i; i < tokenIds.length; i++) {
      voxelsNFT.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
      _deposits[msg.sender].add(tokenIds[i]);
    }

    totalStaked += tokenIds.length;
  }

  function withdraw(bytes calldata requestData, bytes calldata signature)
    external
    whenNotPaused
    nonReentrant
  {
    RankRequest memory request = abi.decode(requestData, (RankRequest));
    uint256[] memory tokenIds = request.tokenIds;
    claimRewards(requestData, signature);

    for (uint256 i; i < tokenIds.length; i++) {
      require(
        _deposits[msg.sender].contains(tokenIds[i]),
        "Staking: token not deposited"
      );
      _deposits[msg.sender].remove(tokenIds[i]);

      voxelsNFT.safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
    }

    totalStaked -= tokenIds.length;
  }

  function withdrawTokens() external onlyAdmin {
    uint256 tokenSupply = wireToken.balanceOf(address(this));
    wireToken.transfer(msg.sender, tokenSupply);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function addAdmin(address admin_) external onlyOwner {
    admins[admin_] = true;
  }

  function removeAdmin(address admin_) external onlyOwner {
    admins[admin_] = false;
  }

  function _getWeight(
    uint256 _tokenId,
    uint256 _rank
  ) internal view returns (uint256) {
    uint256 lastRankForTokenId = lastRank[_tokenId];
    uint256 rankAvgWithExponential = _rank * 10000;
    if(lastRankForTokenId > 0 && lastRankForTokenId != _rank) {
      rankAvgWithExponential = _rank + lastRankForTokenId * 10000 / 2;      
    }

    uint256 totalSupply = _tokenId <= voxelTotalSupply
      ? voxelTotalSupply
      : genesisTotalSupply;
    uint256 _totalStaked = totalStaked > 0 ? totalStaked : 1; 

    return (
      (voxelsNFT.totalSupply() * totalSupply) /
      (_totalStaked * rankAvgWithExponential)
    );
  }

  function _getStakingRate(
    uint256 _tokenId,
    uint256 _rank,
    uint256 _multiplierRate
  ) internal view returns (uint256) {
    uint256 extraRate = _tokenId <= voxelTotalSupply
      ? _multiplierRate
      : (voxelsNFT.wires(_tokenId) + 2) * (voxelsNFT.stages(_tokenId) + 1) * 100;
    return rate * (1 + _getWeight(_tokenId, _rank)) * extraRate / 100;
  }

  function setSigner(address signer) external onlyAdmin {
    _signer = signer;
  }
}
