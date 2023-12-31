// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./IAntiMevStrategy.sol";
import "./IPair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV3Factory.sol";
import "./IPoolV3.sol";

/// @title
/// @author Ben Coin Collective
/// @notice This contains the logic necessary for blocking MEV bots from frontrunning transactions.
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

  constructor(address _ben) {
    ben = _ben;
  }

  function onTransfer(
    address _from,
    address _to,
    uint256 /*_amount*/,
    bool _isTaxingInProgress
  ) external override onlyBen {
    // If from or to an LP, then whitelist it from MEV
    if (_isTaxingInProgress) {
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

  function _isPair(address _target) private view returns (bool) {
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
      uint24 fee;
      try IPoolV3(_target).fee() returns (uint24 _fee) {
        fee = _fee;
      } catch {
        return false;
      }

      return IUniswapV3Factory(factory).getPool(token0, token1, fee) == _target;
    }
  }

  function _setMEVWhitelist(address _whitelist, bool _isWhitelisted) private {
    MEVWhitelist[_whitelist] = _isWhitelisted;
    emit SetMEVWhitelist(_whitelist, _isWhitelisted);
  }

  function setFactoryWhitelist(address _whitelist, uint8 _version, bool _isWhitelisted) external onlyOwner {
    factoryInfos[_whitelist].isWhitelisted = _isWhitelisted;
    factoryInfos[_whitelist].version = _version;
    emit SetFactoryWhitelist(_whitelist, _version, _isWhitelisted);
  }

  function setMEVWhitelist(address _whitelist, bool _isWhitelisted) external onlyOwner {
    _setMEVWhitelist(_whitelist, _isWhitelisted);
  }

  function setMEVWhitelists(address[] calldata _whitelists, bool[] calldata _isWhitelisted) external onlyOwner {
    for (uint i; i < _whitelists.length; i++) {
      _setMEVWhitelist(_whitelists[i], _isWhitelisted[i]);
    }
  }
}
