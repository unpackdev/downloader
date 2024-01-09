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

  bool public presaleActive;
  bool public publicSaleActive;

  uint128 public constant MINT_PRICE = 0.08 ether;

  uint8 private constant SKIM_MILK_ID = 0;
  uint8 private constant ONE_PERCENT_MILK_ID = 1;
  uint8 private constant TWO_PERCENT_MILK_ID = 2;
  uint8 private constant WHOLE_MILK_ID = 3;
  uint8 private constant MUTANT_MILK_ID = 4;

  uint8 private constant MAX_TX_MINT = 8;
  uint8 private constant MAX_WHITELIST_MINT = 4;

  uint16 private maxClaimMints;
  uint16 private maxPaidMints;
  uint16 private claimMints;
  uint16 private paidMints;
  uint16[5] private claimMilks;
  uint16[5] private paidMilks;

  ILBAC private lbac;
  address private verifier;
  mapping(uint16 => bool) private claimedTokens;
  mapping(address => uint16) private whitelistMints;

  function initialize(address _verifier, address _lbac) public initializer {
    __ERC1155_init("https://teenrebelapeclub.com/api/metadata/");
    __Ownable_init_unchained();
    __ReentrancyGuard_init_unchained();

    maxClaimMints = 5000;
    maxPaidMints = 3888;
    claimMilks = [2500, 1500, 500, 500, 0];
    paidMilks = [1940, 1164, 388, 388, 8];

    presaleActive = false;
    publicSaleActive = false;
    verifier = _verifier;
    lbac = ILBAC(_lbac);
  }

  function startPresale() external onlyOwner {
    presaleActive = true;
  }

  function startPublicSale() external onlyOwner {
    publicSaleActive = true;

    // Move remaining presale claims to public mints
    paidMilks[SKIM_MILK_ID] += claimMilks[SKIM_MILK_ID];
    paidMilks[ONE_PERCENT_MILK_ID] += claimMilks[ONE_PERCENT_MILK_ID];
    paidMilks[TWO_PERCENT_MILK_ID] += claimMilks[TWO_PERCENT_MILK_ID];
    paidMilks[WHOLE_MILK_ID] += claimMilks[WHOLE_MILK_ID];
    paidMilks[MUTANT_MILK_ID] += claimMilks[MUTANT_MILK_ID];
    maxPaidMints += maxClaimMints - claimMints;
    maxClaimMints = claimMints;
    claimMilks = [0, 0, 0, 0, 0];
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

  function presaleClaim(uint16[] calldata tokenIds, uint256[] calldata milkIds, uint256[] calldata amounts, bytes calldata sig) external nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(presaleActive && !publicSaleActive, "not active");
    require(claimMints + tokenIds.length <= maxClaimMints, "supply exhausted");
    require(isValidClaim(tokenIds, milkIds, amounts, sig), "unauthorized");

    uint16 i;
    for (; i < tokenIds.length; i++) {
      require(lbac.ownerOf(tokenIds[i]) == msg.sender, "not owner");
      require(!claimedTokens[tokenIds[i]], "already claimed");
      claimedTokens[tokenIds[i]] = true;
    }
    for (i = 0; i < milkIds.length; i++) {
      require(claimMilks[milkIds[i]] >= amounts[i], "claims exhausted");
      claimMilks[milkIds[i]] -= uint16(amounts[i]);
    }

    claimMints += uint16(tokenIds.length);
    _mintBatch(msg.sender, milkIds, amounts, "");
  }

  function presaleMint(uint16 amount, bytes calldata sig) external payable nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(presaleActive && !publicSaleActive, "not active");
    require(paidMints + amount <= maxPaidMints, "supply exhausted");
    require(amount * MINT_PRICE == msg.value, "invalid payment");
    require(amount > 0 && whitelistMints[msg.sender] + amount <= MAX_WHITELIST_MINT, "invalid amount");
    require(isValidMint(msg.sender, sig), "unauthorized");

    uint256[] memory milkIds = new uint256[](5);
    uint256[] memory amounts = new uint256[](5);
    milkIds[1] = 1; milkIds[2] = 2; milkIds[3] = 3; milkIds[4] = 4;
    uint16 milkId;
    for (uint16 i; i < amount; i++) {
      milkId = getNextPaidMilkId(i);
      amounts[milkId]++;
      paidMilks[milkId]--;
    }

    paidMints += amount;
    whitelistMints[msg.sender] += amount;
    _mintBatch(msg.sender, milkIds, amounts, "");
  }

  function publicMint(uint16 amount) external payable nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(publicSaleActive, "not active");
    require(paidMints + amount <= maxPaidMints, "supply exhausted");
    require(amount * MINT_PRICE == msg.value, "invalid payment");
    require(amount > 0 && amount <= MAX_TX_MINT, "invalid amount");

    uint256[] memory milkIds = new uint256[](5);
    uint256[] memory amounts = new uint256[](5);
    milkIds[1] = 1; milkIds[2] = 2; milkIds[3] = 3; milkIds[4] = 4;
    uint16 milkId;
    for (uint16 i; i < amount; i++) {
      milkId = getNextPaidMilkId(i);
      amounts[milkId]++;
      paidMilks[milkId]--;
    }

    paidMints += amount;
    _mintBatch(msg.sender, milkIds, amounts, "");
  }

  function generateClaimHash(uint16[] calldata tokenIds, uint256[] calldata milkIds, uint256[] calldata amounts) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenIds, milkIds, amounts));
  }

  function isValidClaim(uint16[] calldata tokenIds, uint256[] calldata milkIds, uint256[] calldata amounts, bytes calldata sig) private view returns (bool) {
    return ECDSAUpgradeable.recover(generateClaimHash(tokenIds, milkIds, amounts).toEthSignedMessageHash(), sig) == verifier;
  }

  function generateMintHash(address account) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  function isValidMint(address account, bytes calldata sig) private view returns (bool) {
    return ECDSAUpgradeable.recover(generateMintHash(account).toEthSignedMessageHash(), sig) == verifier;
  }

  function getNextPaidMilkId(uint16 offset) private view returns (uint8) {
    unchecked {
      uint256 nextId = uint256(keccak256(abi.encodePacked(paidMints))) % (maxPaidMints - paidMints - offset);
      nextId -= paidMilks[SKIM_MILK_ID];        if (nextId > maxPaidMints) return SKIM_MILK_ID;
      nextId -= paidMilks[ONE_PERCENT_MILK_ID]; if (nextId > maxPaidMints) return ONE_PERCENT_MILK_ID;
      nextId -= paidMilks[TWO_PERCENT_MILK_ID]; if (nextId > maxPaidMints) return TWO_PERCENT_MILK_ID;
      nextId -= paidMilks[WHOLE_MILK_ID];       if (nextId > maxPaidMints) return WHOLE_MILK_ID;
      nextId -= paidMilks[MUTANT_MILK_ID];      if (nextId > maxPaidMints) return MUTANT_MILK_ID;
    }
    revert("mints exhausted");
  }

  function ownerMint(address to, uint256[] calldata milkIds, uint256[] calldata amounts) external onlyOwner {
    require(milkIds.length == amounts.length, "length mismatch");

    uint256 totalMints;
    for (uint16 i; i < milkIds.length; i++) {
      require(paidMilks[milkIds[i]] >= amounts[i], "mints exhausted");
      paidMilks[milkIds[i]] -= uint16(amounts[i]);
      totalMints += amounts[i];
    }

    paidMints += uint16(totalMints);
    _mintBatch(to, milkIds, amounts, "");
  }

  function getRemainingClaimMilks() external view returns (uint16[5] memory) {
    return [
      claimMilks[SKIM_MILK_ID],
      claimMilks[ONE_PERCENT_MILK_ID],
      claimMilks[TWO_PERCENT_MILK_ID],
      claimMilks[WHOLE_MILK_ID],
      claimMilks[MUTANT_MILK_ID]
    ];
  }

  function getRemainingPaidMilks() external view returns (uint16[5] memory) {
    return [
      paidMilks[SKIM_MILK_ID],
      paidMilks[ONE_PERCENT_MILK_ID],
      paidMilks[TWO_PERCENT_MILK_ID],
      paidMilks[WHOLE_MILK_ID],
      paidMilks[MUTANT_MILK_ID]
    ];
  }

  function getMintCounts() external view returns(uint16[2] memory) {
    return [ claimMints, paidMints ];
  }

  /**
   * Ennumerate tokens by owner.
   */
  function tokensOf(address owner) external view returns (uint16[5] memory) {
    return [
      uint16(balanceOf(owner, SKIM_MILK_ID)),
      uint16(balanceOf(owner, ONE_PERCENT_MILK_ID)),
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
    uint256 balance = address(this).balance;
    payable(0x1Ff269813ECFff82cb608C32B8b37A08b7334339).transfer(balance * 30 / 100);
    payable(0x48987e3d27927c34E2Afe526c671352D68d69238).transfer(balance * 12 / 100);
    payable(0x3Efce8bd4903711D9C1393bDfE319Fe482085778).transfer(balance * 12 / 100);
    payable(0x37E8E5fCf5969A54eF86aBACA35EF6Cd2c8D5da4).transfer(balance * 12 / 100);
    payable(0x1c9A0a18a47BbB622b986b805483EC2192BE75BC).transfer(balance * 12 / 100);
    payable(0xbbaAf85F87aBC8B288925D5886FBc0DCB1ae8f57).transfer(balance * 12 / 100);
    payable(0x1F03D6222Be7E7f9a3EA1788bE2ffb601803E953).transfer(balance * 5  / 100);
    payable(0xF6D860F29326bac24306A6Fa623a357B93245213).transfer(balance * 5  / 100);
  }
}
