//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
import "./Delegatable.sol";
import "./IBlock.sol";

contract Block is
  ERC20Upgradeable,
  Delegatable,
  IBlock,
  ReentrancyGuardUpgradeable
{
  using ECDSA for bytes32;

  address public oracleAddress;

  uint256 public constant MINT_ROLE = 1;
  uint256 public constant BURN_ROLE = 2;

  mapping(address => uint256) public latestClaims;

  function initialize(address _oracleAddress) public initializer {
    __ERC20_init("Block", "BLOCK");
    __Delegatable_init();
    __ReentrancyGuard_init_unchained();
    oracleAddress = _oracleAddress;
  }

  /*
  WRITE FUNCTIONS
  */

  function burnFrom(address account, uint256 amount)
    external
    virtual
    override
    onlyDelegate(BURN_ROLE)
  {
    _burn(account, amount);
  }

  function claim(
    address to,
    uint256 amount,
    uint256 startBlockNumber,
    uint256 endBlockNumber,
    bytes calldata signature
  ) external virtual override nonReentrant {
    require(
      _verify(
        _hashClaimMessage(to, amount, startBlockNumber, endBlockNumber),
        signature
      ),
      "Invalid signature"
    );
    require(
      startBlockNumber == latestClaims[to] &&
        endBlockNumber > startBlockNumber &&
        endBlockNumber < block.number,
      "Invalid block range"
    );
    latestClaims[to] = endBlockNumber;
    _mint(to, amount);
  }

  /*
  READ FUNCTIONS
  */

  function _verify(bytes32 messageHash, bytes memory signature)
    internal
    view
    returns (bool)
  {
    return
      messageHash.toEthSignedMessageHash().recover(signature) == oracleAddress;
  }

  function _hashClaimMessage(
    address to,
    uint256 amount,
    uint256 startBlockNumber,
    uint256 endBlockNumber
  ) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(to, amount, startBlockNumber, endBlockNumber));
  }

  /*
  OWNER FUNCTIONS
  */

  function setOracleAddress(address _oracleAddress) external onlyOwner {
    oracleAddress = _oracleAddress;
  }
}
