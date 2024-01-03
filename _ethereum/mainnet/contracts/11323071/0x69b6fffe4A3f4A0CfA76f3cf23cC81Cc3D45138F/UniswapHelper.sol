// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Whitelist.sol";
import "./Console.sol";

contract UniswapHelper is Whitelist, ReentrancyGuard {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping (bytes32 => uint) _hasPath;
  mapping (bytes32 => mapping (uint => address)) _paths;

  IUniswapV2Factory public constant UNI_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  IUniswapV2Router02 public constant UNI_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

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

  function _removeLiquidityDeflationary(address tokenA, address tokenB, uint256 amount, uint256 minA, uint256 minB) internal returns (uint256 amountA, uint256 amountB) {
    uint256 befA = IERC20(tokenA).balanceOf(address(this));
    uint256 befB = IERC20(tokenB).balanceOf(address(this));
    UNI_ROUTER.removeLiquidity(tokenA, tokenB, amount, minA, minB, address(this), now.add(1800));
    uint256 aftA = IERC20(tokenA).balanceOf(address(this));
    uint256 aftB = IERC20(tokenB).balanceOf(address(this));
    amountA = aftA.sub(befA, 'deflat');
    amountB = aftB.sub(befB, 'deflat');
  }

  function withdrawToToken(address token, uint256 amount, address dest, IUniswapV2Pair pair, uint256 minA, uint256 minB, uint256 slippageA, uint256 slippageB) onlyWhitelist nonReentrant external {
    address token0 = pair.token0();
    address token1 = pair.token1();
    IERC20(address(pair)).safeApprove(address(UNI_ROUTER), 0);
    IERC20(address(pair)).safeApprove(address(UNI_ROUTER), amount * 2);
    (uint amount0, uint amount1) = _removeLiquidityDeflationary(token0, token1, amount, minA, minB);
    if (token == token0) {
      IERC20(token0).safeTransfer(dest, amount0);
    } else {
      _swapWithSlippage(token0, token, amount0, slippageA, dest);
    }
    if (token == token1) {
      IERC20(token1).safeTransfer(dest, amount1);
    } else {
      _swapWithSlippage(token1, token, amount1, slippageB, dest);
    }
  }

  function _swapWithSlippage(address from, address to, uint256 amount, uint256 slippage, address dest) internal returns(uint256 swapOut) {
    string memory path = Path.path(from, to);
    uint256 out = _estimateOut(from, to, amount);
    uint256 min = amountWithSlippage(out, slippage);
    swapOut = _swap(path, amount, min, dest);
  }

  function swap(string memory name, uint256 amount, uint256 minOut, address dest) onlyWhitelist nonReentrant external returns (uint256 swapOut) {
    swapOut = _swap(name, amount, minOut, dest);
  }

  function _swap(string memory name, uint256 amount, uint256 minOut, address dest) internal returns (uint256 swapOut) {
    bytes32 key = keccak256(abi.encodePacked(name));
    uint256 length = _hasPath[key];
    require(length > 0, Console.concat('path not found ', name));

    // Copy array
    address[] memory swapPath = new address[](length);
    for (uint i = 0; i < length; i++) {
      swapPath[i] = _paths[key][i];
    }

    IERC20 token = IERC20(swapPath[0]);
    IERC20 to = IERC20(swapPath[swapPath.length - 1]);
    token.safeApprove(address(UNI_ROUTER), 0);
    token.safeApprove(address(UNI_ROUTER), amount * 2);
    uint256 bef = to.balanceOf(dest);
    UNI_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, minOut, swapPath, dest, now.add(1800));
    uint256 aft = to.balanceOf(dest);
    swapOut = aft.sub(bef, '!swapOut');
  }

  function amountWithSlippage(uint256 amount, uint256 slippage) internal pure returns (uint256 out) {
    out = slippage == 0 ? 0 : amount.sub(amount.mul(slippage).div(SLIPPAGE_BASE));
  }

  function getAmountOut(IUniswapV2Pair pair, address token, uint256 amount) external view returns (uint256 optimal) {
    optimal = _getAmountOut(pair, token, amount);
  }

  function _getAmountOut(IUniswapV2Pair pair, address token, uint256 amount) internal view returns (uint256 optimal) {
    uint256 reserve0;
    uint256 reserve1;
    if (pair.token0() == token) {
      (reserve0, reserve1, ) = pair.getReserves();
    } else {
      (reserve1, reserve0, ) = pair.getReserves();
    }
    optimal = UNI_ROUTER.getAmountOut(amount, reserve0, reserve1);
  }

  function quote(IUniswapV2Pair pair, address token, uint256 amount) external view returns (uint256 optimal) {
    optimal = _quote(pair, token, amount);
  }

  function _quote(IUniswapV2Pair pair, address token, uint256 amount) internal view returns (uint256 optimal) {
    uint256 reserve0;
    uint256 reserve1;
    if (pair.token0() == token) {
      (reserve0, reserve1, ) = pair.getReserves();
    } else {
      (reserve1, reserve0, ) = pair.getReserves();
    }
    optimal = UNI_ROUTER.quote(amount, reserve0, reserve1);
  }

  function _estimateOut(address from, address to, uint256 amount) internal view returns (uint256 swapOut) {
    string memory path = Path.path(from, to);
    bytes32 key = keccak256(abi.encodePacked(path));
    uint256 length = _hasPath[key];
    require(length > 0, Console.concat('path not found ', path));

    swapOut = amount;
    for (uint i = 0; i < length - 1; i++) {
      address first = _paths[key][i];
      IUniswapV2Pair pair = IUniswapV2Pair(UNI_FACTORY.getPair(first, _paths[key][i + 1]));
      require(address(pair) != address(0), 'swap pair not found');
      swapOut = _getAmountOut(pair, first, swapOut);
    }
  }

  function estimateOut(address from, address to, uint256 amount) external view returns (uint256 swapOut) {
    require(amount > 0, '!amount');
    swapOut = _estimateOut(from, to, amount);
  }

  function estimateOuts(address[] memory pairs, uint256[] memory amounts) external view returns (uint256[] memory swapOut) {
    require(pairs.length.div(2) == amounts.length, 'pairs!=amounts');
    swapOut = new uint256[](amounts.length);
    for (uint256 i = 0; i < pairs.length; i+=2) {
      uint256 ai = i.div(2);
      swapOut[ai] = _estimateOut(pairs[i], pairs[i+1], amounts[ai]);
    }
  }

}
