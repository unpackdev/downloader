// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./IAntiMevStrategy.sol";
import "./IPair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV3Factory.sol";
import "./IPoolV3.sol";

/**
 * @title OneDirectionPerBlockAntiMevStrategy
 * @dev OneDirectionPerBlockAntiMevStrategy contains the logic to prevent MEV bots from frontrunning transactions.
 * This strategy enforces that each address can perform only one transaction per direction per block, preventing sandwich attacks which operate in this manner.
 * It also provides mechanisms to whitelist certain addresses and factory contracts to allow for exceptions.
 */
contract OneDirectionPerBlockAntiMevStrategy is Ownable, IAntiMevStrategy {
  event SetFactoryWhitelist(address whitelist, uint8 version, bool isWhitelisted);
  event SetMEVWhitelist(address whitelist, bool isWhitelisted);

  error OnlyOneTransferPerBlockPerAddress(address);
  error OnlyBen();

  struct FactoryInfo {
    bool isWhitelisted;
    uint8 version;
  }

  address public ben;
  mapping(bytes32 accountHash => bool[2] directions) private accountTransferredPerBlock;
  mapping(address whitelist => bool isWhitelisted) public MEVWhitelist; // For certain addresses to be exempt from MEV like exchanges
  mapping(address factory => FactoryInfo factoryInfo) public factoryInfos;

  modifier onlyBen() {
    if (msg.sender != ben) {
      revert OnlyBen();
    }
    _;
  }

  /**
   * @param _ben The address of the Ben token contract
   *
   * Constructor initializes the contract with the address of the Ben token, which is required for access control.
   * The Ben token contract address cannot be changed after deployment.
   */
  constructor(address _ben) {
    ben = _ben;
  }

  /**
   * @notice Callback function to handle token transfers and enforce anti-MEV measures
   * @param _from The sender address
   * @param _to The receiver address
   * @param _amount The amount of tokens being transferred
   * @param _isTaxingInProgress A flag indicating whether a tax transaction is in progress
   *
   * This function is called during token transfers and enforces anti-MEV measures.
   * It ensures that each address can perform only one transaction per block, except for whitelisted addresses.
   * Additionally, it checks if the sender or receiver is a whitelisted pair contract to allow exceptions.
   */
  function onTransfer(address _from, address _to, uint256 _amount, bool _isTaxingInProgress) external override onlyBen {
    // If from or to an LP, then whitelist it from MEV
    if (_isTaxingInProgress || _from == _to || _amount == 0) {
      return;
    }

    bool fromIsWhitelisted = MEVWhitelist[_from];
    if (!fromIsWhitelisted) {
      fromIsWhitelisted = _isPair(_from);
    }

    bool toIsWhitelisted = MEVWhitelist[_to];
    if (!toIsWhitelisted) {
      toIsWhitelisted = _isPair(_to);
    }

    if (!fromIsWhitelisted) {
      bytes32 key = keccak256(abi.encodePacked(block.number, _from));
      if (accountTransferredPerBlock[key][1]) {
        revert OnlyOneTransferPerBlockPerAddress(_from);
      }
      accountTransferredPerBlock[key][0] = true;
    }
    if (!toIsWhitelisted) {
      bytes32 key = keccak256(abi.encodePacked(block.number, _to));
      if (accountTransferredPerBlock[key][0]) {
        revert OnlyOneTransferPerBlockPerAddress(_to);
      }
      accountTransferredPerBlock[key][1] = true;
    }
  }

  /**
   * @param _target The address to check
   * @return isPair A boolean indicating whether the address represents a pair contract
   *
   * Internal function to check if an address is a pair contract, such as a Uniswap LP token.
   * It verifies if the address is a contract, checks its factory, and determines if it is indeed a valid pair.
   */
  function _isPair(address _target) private view returns (bool isPair) {
    // Not a contract
    if (_target.code.length == 0) {
      return false;
    }

    IPair pairContract = IPair(_target);
    address factory;
    try pairContract.factory() returns (address _factory) {
      factory = _factory;
    } catch {
      return false;
    }

    // Possible pair, check if factory is whitelisted
    FactoryInfo memory factoryInfo = factoryInfos[factory];
    if (!factoryInfo.isWhitelisted) {
      return false;
    }

    // Check if this is actually an LP
    address token0;
    try pairContract.token0() returns (address _token0) {
      token0 = _token0;
    } catch {
      return false;
    }

    address token1;
    try pairContract.token1() returns (address _token1) {
      token1 = _token1;
    } catch {
      return false;
    }

    if (factoryInfo.version == 2) {
      // UniV2 pairs
      return IUniswapV2Factory(factory).getPair(token0, token1) == _target;
    } else if (factoryInfo.version == 3) {
      // UniV3 pairs
      try IPoolV3(_target).fee() returns (uint24 _fee) {
        return IUniswapV3Factory(factory).getPool(token0, token1, _fee) == _target;
      } catch {
        return false;
      }
    }
  }

  function _setMEVWhitelist(address _whitelist, bool _isWhitelisted) private {
    MEVWhitelist[_whitelist] = _isWhitelisted;
    emit SetMEVWhitelist(_whitelist, _isWhitelisted);
  }

  /**
   * @notice Set or update the whitelist status and version of a factory contract
   * @param _whitelist The address of the factory contract to whitelist or update
   * @param _version The version of the factory contract (e.g., 2 for Uniswap V2, 3 for Uniswap V3)
   * @param _isWhitelisted A boolean indicating whether to whitelist or remove the factory contract
   *
   * Allows the owner (treasury) to set or update the whitelist status of a factory contract.
   * Factory contracts are responsible for creating pairs and pools in decentralized exchanges.
   * Whitelisting a factory contract allows its pairs to be exempt from certain anti-MEV checks.
   */
  function setFactoryWhitelist(address _whitelist, uint8 _version, bool _isWhitelisted) external onlyOwner {
    factoryInfos[_whitelist].isWhitelisted = _isWhitelisted;
    factoryInfos[_whitelist].version = _version;
    emit SetFactoryWhitelist(_whitelist, _version, _isWhitelisted);
  }

  /**
   * @param _whitelist The address to add or remove from the MEV whitelist
   * @param _isWhitelisted A boolean indicating whether to add or remove the address from the whitelist
   *
   * Allows the owner (treasury) to add or remove addresses from the MEV whitelist.
   * Addresses on the whitelist are exempt from MEV checks
   */
  function setMEVWhitelist(address _whitelist, bool _isWhitelisted) external onlyOwner {
    _setMEVWhitelist(_whitelist, _isWhitelisted);
  }

  /**
   * @param _whitelists An array of addresses to add or remove from the MEV whitelist
   * @param _isWhitelisted An array of booleans indicating whether to add or remove addresses from the whitelist
   *
   * Allows the owner (treasury) to add or remove multiple addresses from the MEV whitelist simultaneously.
   * This is an efficient way to manage the whitelist for multiple addresses.
   */
  function setMEVWhitelists(address[] calldata _whitelists, bool[] calldata _isWhitelisted) external onlyOwner {
    for (uint i; i < _whitelists.length; i++) {
      _setMEVWhitelist(_whitelists[i], _isWhitelisted[i]);
    }
  }
}
