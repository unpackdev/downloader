// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Whitelist.sol";
import "./Console.sol";
import "./IProtocolHelper.sol";

contract BaseHelper is Whitelist, ReentrancyGuard, IProtocolHelper {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping (bytes32 => uint) _hasPath;
  mapping (bytes32 => mapping (uint => address)) _paths;

  uint256 public constant MIN_AMOUNT = 5;
  uint256 public constant MIN_SWAP_AMOUNT = 1000; // should be ok for most coins
  uint256 public constant MIN_SLIPPAGE = 1; // .01%
  uint256 public constant MAX_SLIPPAGE = 1000; // 10%
  uint256 public constant SLIPPAGE_BASE = 10000;

   constructor () public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
  }

  function setupRoles(address admin, address harvester) onlyDefaultAdmin external {
    _setup(ROLE_HARVESTER, harvester);
    _setupDefaultAdmin(admin);
  }

  function addPath(string memory name, address[] memory path) onlyHarvester external {
    bytes32 key = keccak256(abi.encodePacked(name));
    require(_hasPath[key] == 0, 'path exists');
    require(path.length > 0, 'invalid path');

    _hasPath[key] = path.length;
    mapping (uint => address) storage spath = _paths[key];
    for (uint i = 0; i < path.length; i++) {
      spath[i] = path[i];
    }
  }

  function removePath(string memory name) onlyHarvester external {
    bytes32 key = keccak256(abi.encodePacked(name));
    uint length = _hasPath[key];
    require(length > 0, 'path not found exists');

    _hasPath[key] = 0;
    mapping (uint => address) storage spath = _paths[key];
    for (uint i = 0; i < length; i++) {
      spath[i] = address(0);
    }
  }

  function pathExists(address from, address to) external view returns(bool) {
    string memory name = Path.path(from, to);
    bytes32 key = keccak256(abi.encodePacked(name));
    uint256 length = _hasPath[key];
    if (length == 0) return false;
    address first = _paths[key][0];
    if (from != first) return false;
    address last = _paths[key][length - 1];
    if (to != last) return false;
    return true;
  }

  function swap(string memory /* name */, uint256 /* amount */, uint256 /*  minOut */, address /*  dest */) onlyWhitelist nonReentrant override virtual external returns (uint256 swapOut) {
    swapOut = 0;
  }

}
