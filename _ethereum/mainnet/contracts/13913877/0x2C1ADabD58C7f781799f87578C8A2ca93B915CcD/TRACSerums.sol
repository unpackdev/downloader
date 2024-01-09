//  _________  _________   _______  __________
// /__     __\|    _____) /   .   \/    _____/
//    |___|   |___|\____\/___/ \___\________\

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./ILBAC.sol";

contract TRACSerums is ERC1155Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32;

  uint8 public constant NON_FAT_MILK_ID = 0;
  uint8 public constant SKIM_MILK_ID = 1;
  uint8 public constant TWO_PERCENT_MILK_ID = 2;
  uint8 public constant WHOLE_MILK_ID = 3;
  uint8 public constant MUTANT_MILK_ID = 4;

  uint16 public mints;
  uint16 public constant MAX_MINTS = 5004;
  uint16[5] private remainingMints;

  uint48 public claimTime;
  uint48 public publicSaleTime;

  ILBAC private lbac;
  address public verifier;
  mapping(uint16 => bool) claimedTokens;

  uint128 public maxPublicMint;
  uint128 public constant PUBLIC_MINT_PRICE = 0.06 ether;

  function initialize(uint48 _claimTime, uint48 _publicSaleTime, address _verifier, address _lbac, uint16 _maxPublicMint) public initializer {
    __ERC1155_init("https://teenrebelapeclub.com/api/metadata/");
    __Ownable_init();
    __ReentrancyGuard_init();

    remainingMints = [2500, 1500, 500, 500, 4];

    claimTime = _claimTime;
    publicSaleTime = _publicSaleTime;
    verifier = _verifier;
    lbac = ILBAC(_lbac);
    maxPublicMint = _maxPublicMint;
  }

  function update(uint48 _claimTime, uint48 _publicSaleTime, uint16 _maxPublicMint) external onlyOwner {
    claimTime = _claimTime;
    publicSaleTime = _publicSaleTime;
    maxPublicMint = _maxPublicMint;
  }

  struct CheckResponse { uint16 tokenId; address owner; bool claimed; }

  function checkTokens(uint16[] calldata tokenIds) external view returns (CheckResponse[] memory checks) {
    checks = new CheckResponse[](tokenIds.length);
    for (uint16 i; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];
      checks[i] = CheckResponse({
        tokenId: tokenId,
        owner: lbac.ownerOf(tokenId),
        claimed: claimedTokens[tokenId]
      });
    }
  }

  function checkOwnerOf(address owner) external view returns (CheckResponse[] memory checks) {
    uint256 tokenCount = lbac.balanceOf(owner);
    checks = new CheckResponse[](tokenCount);
    for (uint16 i; i < tokenCount; i++) {
      uint16 tokenId = uint16(lbac.tokenOfOwnerByIndex(owner, i));
      checks[i] = CheckResponse({
        tokenId: tokenId,
        owner: owner,
        claimed: claimedTokens[tokenId]
      });
    }
  }

  function claim(uint16[] calldata tokenIds, uint256[] calldata milkIds, uint256[] calldata amounts, bytes calldata sig) external nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(block.timestamp >= claimTime, "not active");
    require(isValidClaim(tokenIds, milkIds, amounts, sig), "unauthorized");
    require(mints + tokenIds.length <= MAX_MINTS, "mints exhausted");

    uint16 i;
    for (; i < tokenIds.length; i++) {
      require(lbac.ownerOf(tokenIds[i]) == msg.sender, "not owner");
      claimedTokens[tokenIds[i]] = true;
    }
    for (i = 0; i < milkIds.length; i++) {
      require(remainingMints[milkIds[i]] >= amounts[i], "mints exhausted");
      remainingMints[milkIds[i]] -= uint16(amounts[i]);
    }

    mints += uint16(tokenIds.length);
    _mintBatch(msg.sender, milkIds, amounts, "");
  }

  function mint(uint16 amount) external payable nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(block.timestamp >= publicSaleTime, "not active");
    require(amount * PUBLIC_MINT_PRICE == msg.value, "invalid payment");
    require(amount > 0 && amount <= maxPublicMint, "invalid amount");
    require(mints + amount <= MAX_MINTS, "mints exhausted");

    uint256[] memory milkIds = new uint256[](5);
    uint256[] memory amounts = new uint256[](5);
    milkIds[1] = 1; milkIds[2] = 2; milkIds[3] = 3; milkIds[4] = 4;
    uint16 milkId;
    for (uint16 i; i < amount; i++) {
      milkId = getNextMilkId(i);
      amounts[milkId]++;
      remainingMints[milkId]--;
    }

    mints += amount;
    _mintBatch(msg.sender, milkIds, amounts, "");
  }

  function generateClaimHash(uint16[] calldata tokenIds, uint256[] calldata milkIds, uint256[] calldata amounts) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenIds, milkIds, amounts));
  }

  function isValidClaim(uint16[] calldata tokenIds, uint256[] calldata milkIds, uint256[] calldata amounts, bytes calldata sig) public view returns (bool) {
    return ECDSAUpgradeable.recover(
      generateClaimHash(tokenIds, milkIds, amounts).toEthSignedMessageHash(),
      sig
    ) == verifier;
  }

  function getNextMilkId(uint16 offset) private view returns (uint8) {
    unchecked {
      uint256 nextId = uint256(keccak256(abi.encodePacked(mints))) % (MAX_MINTS - mints - offset);
      nextId -= remainingMints[NON_FAT_MILK_ID];     if (nextId > MAX_MINTS) return NON_FAT_MILK_ID;
      nextId -= remainingMints[SKIM_MILK_ID];        if (nextId > MAX_MINTS) return SKIM_MILK_ID;
      nextId -= remainingMints[TWO_PERCENT_MILK_ID]; if (nextId > MAX_MINTS) return TWO_PERCENT_MILK_ID;
      nextId -= remainingMints[WHOLE_MILK_ID];       if (nextId > MAX_MINTS) return WHOLE_MILK_ID;
      nextId -= remainingMints[MUTANT_MILK_ID];      if (nextId > MAX_MINTS) return MUTANT_MILK_ID;
    }
    revert("mints exhausted");
  }

  function ownerMint(address to, uint256[] calldata milkIds, uint256[] calldata amounts) external onlyOwner {
    require(milkIds.length == amounts.length, "length mismatch");

    uint256 totalMints;
    for (uint16 i; i < milkIds.length; i++) {
      require(remainingMints[milkIds[i]] >= amounts[i], "mints exhausted");
      remainingMints[milkIds[i]] -= uint16(amounts[i]);
      totalMints += amounts[i];
    }

    mints += uint16(totalMints);
    _mintBatch(to, milkIds, amounts, "");
  }

  function getRemainingMints() external view returns (uint16[5] memory) {
    return [
      remainingMints[NON_FAT_MILK_ID],
      remainingMints[SKIM_MILK_ID],
      remainingMints[TWO_PERCENT_MILK_ID],
      remainingMints[WHOLE_MILK_ID],
      remainingMints[MUTANT_MILK_ID]
    ];
  }

  /**
   * Ennumerate tokens by owner.
   */
  function tokensOf(address owner) external view returns (uint16[5] memory) {
    return [
      uint16(balanceOf(owner, NON_FAT_MILK_ID)),
      uint16(balanceOf(owner, SKIM_MILK_ID)),
      uint16(balanceOf(owner, TWO_PERCENT_MILK_ID)),
      uint16(balanceOf(owner, WHOLE_MILK_ID)),
      uint16(balanceOf(owner, MUTANT_MILK_ID))
    ];
  }

  /**
   * @notice returns the metadata uri for a given id
   *
   * @param id the card id to return metadata for
   */
  function uri(uint256 id) public view override returns (string memory) {
    require(id >= 0 && id < 5, "URI: nonexistent token");

    return string(abi.encodePacked(super.uri(0), StringsUpgradeable.toString(id)));
  }

  /**
   * Allows withdrawing funds.
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}