// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

import "./console.sol";

// import "./Isoroom.sol"; // Genesis Isoroom Contract
import "./IsoToken.sol";

contract GenesisVault is Ownable, IERC721Receiver {
  uint256 public totalStaked;
  uint256 public baseRate;
  uint32 public constant genesisBirthday = 1642377600;
  
  mapping(uint16 => bool) public airdropClaimed;
  mapping(uint256 => Stake) public vault; 
  mapping(uint8 => bytes32) public tierRoot;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
    uint8 tier;
  }

  event BlockStaked(address owner, uint256 tokenId, uint256 value);
  event BlockUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  IERC721 nft; // Genesis isoroom Contract
  IsoToken token;

  constructor(IERC721 _nft, IsoToken _token, uint256 _baseRate) { 
    nft = _nft;
    token = _token;
    baseRate = _baseRate;
  }

  function updateBaseRate(uint256 _baseRate) external onlyOwner {
    baseRate = _baseRate;
  }

  function updateTierRoot(uint8 tier, bytes32 _hash) external onlyOwner {
    tierRoot[tier] = _hash;
  }

  function claimAirdrop(
    uint16[] calldata tokenIds,
    uint8[] calldata tiers,
    bytes32[][] memory tierProof
  ) 
    external
  {
    uint16 tokenId;
    uint256 earned = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(!airdropClaimed[tokenId], "Already claimed");
      require(nft.ownerOf(tokenId) == msg.sender, "Not your token");

      /**
       * Verify the tier is correct
       * @dev to align with merkle tree, use string token instead of int
       */
      string memory tokenStr = Strings.toString(tokenId);
      uint8 tier = tiers[i];
      bytes32[] memory proof = tierProof[i];
      bytes32 root = tierRoot[tier];
      bytes32 leaf = keccak256(abi.encodePacked(tokenStr));
      bool proofed = MerkleProof.verify(proof, root, leaf);
      require(proofed, "Tier not match");
      
      airdropClaimed[tokenId] = true;
      uint256 claimForDays = (block.timestamp - genesisBirthday) / 1 days;
      if (claimForDays > 19) claimForDays = 19;
      earned += baseRate * tier / 10 * claimForDays;
    }

    if (earned > 0) {
      token.mint(msg.sender, earned);
      emit Claimed(msg.sender, earned);
    }
  }

  function stake(
    uint16[] calldata tokenIds,
    uint8[] calldata tiers,
    bytes32[][] memory tierProof
  ) 
    external
  {
    require(nft.isApprovedForAll(msg.sender, address(this)), "Staking contract not approved");

    uint16 tokenId;
    totalStaked += tokenIds.length;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];

      require(airdropClaimed[tokenId], "Airdrop not claimed");
      require(nft.ownerOf(tokenId) == msg.sender, "Not your token");
      require(vault[tokenId].tokenId == 0, "Already staked");

      /**
       * Verify the tier is correct
       * @dev to align with merkle tree, use string token instead of int
       */
      string memory tokenStr = Strings.toString(tokenId);
      uint8 tier = tiers[i];
      bytes32[] memory proof = tierProof[i];
      bytes32 root = tierRoot[tier];
      bytes32 leaf = keccak256(abi.encodePacked(tokenStr));
      bool proofed = MerkleProof.verify(proof, root, leaf);
      require(proofed, "Tier not match");
      
      nft.transferFrom(msg.sender, address(this), tokenId);
      emit BlockStaked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp),
        tier: tier
      });
    }
  }

  function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    totalStaked -= tokenIds.length;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "Not an owner");

      delete vault[tokenId];
      emit BlockUnstaked(account, tokenId, block.timestamp);
      nft.transferFrom(address(this), account, tokenId);
    }
  }

  function _claim(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    uint256 earned = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];

      require(staked.owner == account, "Not an owner");

      uint48 stakedAt = staked.timestamp;
      earned += earningCalculator(staked.tier, stakedAt);

      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp),
        tier: staked.tier
      });
    }

    if (earned > 0) {
      token.mint(account, earned);
      emit Claimed(account, earned);
    }
  }

  function claim(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds);
  }

  function claimForAddress(address account, uint256[] calldata tokenIds) external {
      _claim(account, tokenIds);
  }

  function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds);
      _unstakeMany(msg.sender, tokenIds);
  }

  function earningCalculator(uint8 tier, uint48 stakedAt) internal view returns(uint256){
    return baseRate * tier / 10 * (block.timestamp - stakedAt) / 1 days;
  }

  function earningInfo(uint256[] calldata tokenIds) external view returns (uint256) {
    uint256 earned = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      
      Stake memory staked = vault[tokenId];

      uint48 stakedAt = staked.timestamp;
      earned += earningCalculator(staked.tier, stakedAt);
    }

    return earned;
  }

  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint16 genesisTotalSupply = 3000;
    for(uint i = 1; i <= genesisTotalSupply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {
    uint16 genesisTotalSupply = 3000;
    uint256[] memory tmp = new uint256[](genesisTotalSupply);

    uint256 index = 0;
    for(uint tokenId = 1; tokenId <= genesisTotalSupply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}