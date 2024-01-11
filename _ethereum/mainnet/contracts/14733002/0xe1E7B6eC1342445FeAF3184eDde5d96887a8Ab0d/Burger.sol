//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
 * Interfaces Grill contracts
 */
interface GrillC {
  function getTotalClaims(address _operator) external view returns (uint256);
}

/**
 * @title An erc-1155 nft contract.
 * @author DegenDeveloper.eth
 *
 * March 29th, 2022
 *
 * This contract allows addresses to mint tokens earned from AstroGrill
 * and/or RickstroGrill staking.
 *
 * The contract owner has the following permissions:
 * - toggle minting.
 * - toggle burning.
 * - update the URI for tokens.
 * - mint tokens for marketing/giveaways without restriction
 */
contract Burger is ERC1155, Ownable {
  using Counters for Counters.Counter;

  /// contract instances
  GrillC public immutable AstroGrill;
  GrillC public immutable RickstroGrill;

  Counters.Counter private totalMinted;
  Counters.Counter private totalBurned;

  bool private CAN_MINT = false;
  bool private CAN_BURN = false;

  /// lookup identifiers
  bytes32 constant MINTS = keccak256("CLAIMS");
  bytes32 constant BURNS = keccak256("BURNS");

  /// mapping for the number of mints/burns of each address
  mapping(bytes32 => mapping(address => Counters.Counter)) private stats;

  /**
   * @param _aGrillAddr The address of the astro grill
   * @param _rGrillAddr The address of the rickstro grill
   */
  constructor(address _aGrillAddr, address _rGrillAddr)
    ERC1155("burger.io/{}.json")
  {
    AstroGrill = GrillC(_aGrillAddr);
    RickstroGrill = GrillC(_rGrillAddr);
  }

  /// ============ OWNER FUNCTIONS ============ ///

  /**
   * Sets the URI for the collection
   * @param _URI The new URI
   */
  function setURI(string memory _URI) public onlyOwner {
    _setURI(_URI);
  }

  function toggleMinting() external onlyOwner {
    CAN_MINT = !CAN_MINT;
  }

  function toggleBurning() external onlyOwner {
    CAN_BURN = !CAN_BURN;
  }

  /**
   * Allows contract owner to mint tokens for giveaways/etc.
   * @param _amount The number of tokens to mint
   * @param _addr The address to mint the tokens to
   */
  function ownerMint(uint256 _amount, address _addr) external onlyOwner {
    uint256[] memory _ids = new uint256[](_amount);
    uint256[] memory _amounts = new uint256[](_amount);

    for (uint256 i = 0; i < _amount; i++) {
      totalMinted.increment();
      _ids[i] = totalMinted.current();
      _amounts[i] = 1;
    }

    _mintBatch(_addr, _ids, _amounts, "0x0");
  }

  /// ============ PUBLIC FUNCTIONS ============ ///

  /**
   * Mint tokens to caller
   * @param _amount The number of tokens to mint
   */
  function mintPublic(uint256 _amount) external {
    require(CAN_MINT, "BURGER: minting is not active");
    require(_amount > 0, "BURGER: must claim more than 0 tokens");
    require(
      stats[MINTS][msg.sender].current() + _amount <=
        AstroGrill.getTotalClaims(msg.sender) +
          RickstroGrill.getTotalClaims(msg.sender),
      "BURGER: caller cannot claim this many tokens"
    );

    uint256[] memory _ids = new uint256[](_amount);
    uint256[] memory _amounts = new uint256[](_amount);

    for (uint256 i = 0; i < _amount; i++) {
      stats[MINTS][msg.sender].increment();
      totalMinted.increment();
      _ids[i] = totalMinted.current();
      _amounts[i] = 1;
    }

    _mintBatch(msg.sender, _ids, _amounts, "0x0");
  }

  /**
   * Burns callers tokens and records amount burned
   * @param _ids Array of token ids caller is trying to burn
   */
  function burnPublic(uint256[] memory _ids) external {
    require(CAN_BURN, "BURGER: burning is not active");
    require(_ids.length > 0, "BURGER: must burn more than 0 tokens");

    uint256[] memory _amounts = new uint256[](_ids.length);

    for (uint256 i = 0; i < _ids.length; i++) {
      require(
        balanceOf(msg.sender, _ids[i]) > 0,
        "BURGER: caller is not token owner"
      );
      _amounts[i] = 1;
      stats[BURNS][msg.sender].increment();
      totalBurned.increment();
    }
    _burnBatch(msg.sender, _ids, _amounts);
  }

  /// ============ READ-ONLY FUNCTIONS ============ ///

  /**
   * @return _b If minting tokens is currently allowed
   */
  function isMinting() external view returns (bool _b) {
    return CAN_MINT;
  }

  /**
   * @return _b If burning tokens is currently allowed
   */
  function isBurning() external view returns (bool _b) {
    return CAN_BURN;
  }

  /**
   * @return _supply The number of tokens in circulation
   */
  function totalSupply() external view returns (uint256 _supply) {
    _supply = totalMinted.current() - totalBurned.current();
  }

  /**
   * @return _mints The number of tokens minted
   */
  function totalMints() external view returns (uint256 _mints) {
    _mints = totalMinted.current();
  }

  /**
   * @return _burns The number of tokens burned
   */
  function totalBurns() external view returns (uint256 _burns) {
    _burns = totalBurned.current();
  }

  /**
   * @param _operator The address to lookup
   * @return _remaining The number of tokens _operator can mint
   */
  function tokenMintsLeft(address _operator)
    external
    view
    returns (uint256 _remaining)
  {
    _remaining =
      AstroGrill.getTotalClaims(_operator) +
      RickstroGrill.getTotalClaims(_operator) -
      stats[MINTS][_operator].current();
  }

  /**
   * @param _operator The address to lookup
   * @return _mints The number of tokens _operator has minted
   */
  function tokenMints(address _operator)
    external
    view
    returns (uint256 _mints)
  {
    _mints = stats[MINTS][_operator].current();
  }

  /**
   * @return _burns The number of tokens _operator has burned
   */
  function tokenBurns(address _operator)
    external
    view
    returns (uint256 _burns)
  {
    _burns = stats[BURNS][_operator].current();
  }
}
