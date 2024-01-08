// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./LowGasSafeMath.sol";
import "./UniswapV2Library.sol";
import "./PairsLibrary.sol";
import "./IContractRegistry.sol";
import "./IOracle.sol";
import "./IWETH.sol";
import "./IDNDX.sol";


contract ExitFeeSeller is Ownable() {
  using TransferHelper for address;
  using LowGasSafeMath for uint256;

/* ==========  Constants  ========== */

  uint256 public constant minTwapAge = 30 minutes;
  uint256 public constant maxTwapAge = 2 days;
  IOracle public constant oracle = IOracle(0xFa5a44D3Ba93D666Bf29C8804a36e725ecAc659A);
  address public constant treasury = 0x78a3eF33cF033381FEB43ba4212f2Af5A5A0a2EA;
  IWETH public constant weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  IDNDX public constant dndx = IDNDX(0x262cd9ADCE436B6827C01291B84f1871FB8b95A3);

/* ==========  Storage  ========== */

  uint16 public twapDiscountBips = 500; // 5%
  uint16 public ethToTreasuryBips = 4000; // 40%

/* ==========  Structs  ========== */

  struct UniswapParams {
    address tokenIn;
    uint256 amountIn;
    address pair;
    bool zeroForOne;
    uint256 amountOut;
  }

/* ==========  Fallbacks  ========== */

  fallback() external payable { return; }
  receive() external payable { return; }

/* ==========  Constructor  ========== */

  constructor() {
    weth.approve(address(dndx), type(uint256).max);
  }

/* ==========  Token Transfer  ========== */

  /**
   * @dev Transfers full balance held by the owner of each provided token
   * to the seller contract.
   *
   * Because the seller will have to be enabled through a proposal and will
   * take several days to go into effect, it will not be possible to know the
   * precise balance to transfer ahead of time; instead, infinite approval will
   * be given and this function will be called to execute the transfers.
   */
  function takeTokensFromOwner(address[] memory tokens) external {
    uint256 len = tokens.length;
    address _owner = owner();
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      uint256 ownerBalance = IERC20(token).balanceOf(_owner);
      if (ownerBalance > 0) {
        token.safeTransferFrom(_owner, address(this), ownerBalance);
      }
    }
  }

/* ==========  Owner Controls  ========== */

  /**
   * @dev Sets the maximum discount on the TWAP that the seller will accept
   * for a trade in basis points, e.g. 500 means the token must be sold
   * for >=95% of the TWAP.
   */
  function setTWAPDiscountBips(uint16 _twapDiscountBips) external onlyOwner {
    require(_twapDiscountBips <= 1000, "Can not set discount >= 10%");
    twapDiscountBips = _twapDiscountBips;
  }

  /**
   * @dev Sets the portion of revenue that are received by the treasury in basis
   * points, e.g. 4000 means the treasury gets 40% of revenue and dndx gets 60%.
   */
  function setEthToTreasuryBips(uint16 _ethToTreasuryBips) external onlyOwner {
    require(_ethToTreasuryBips <= 10000, "Can not set bips over 100%");
    ethToTreasuryBips = _ethToTreasuryBips;
  }

  /**
   * @dev Return tokens to the owner. Can be used if there is a desired change
   * in the revenue distribution mechanism.
   */
  function returnTokens(address[] memory tokens) external onlyOwner {
    uint256 len = tokens.length;
    address _owner = owner();
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      if (token == address(0)) {
        uint256 bal = address(this).balance;
        if (bal > 0) _owner.safeTransferETH(bal);
      } else {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) token.safeTransfer(_owner, bal);
      }
    }
  }

/* ==========  Queries  ========== */

  function getBestPair(address token, uint256 amount) public view returns (address pair, uint256 amountOut) {
    bool zeroForOne = token < address(weth);
    (address token0, address token1) = zeroForOne ? (token, address(weth)) : (address(weth), token);
    uint256 amountUni;
    uint256 amountSushi;
    address uniPair = PairsLibrary.calculateUniPair(token0, token1);
    address sushiPair = PairsLibrary.calculateSushiPair(token0, token1);
    {
      (uint256 reserve0, uint256 reserve1) = PairsLibrary.tryGetReserves(uniPair);
      if (reserve0 > 0 && reserve1 > 0) {
        (uint256 reserveIn, uint256 reserveOut) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
        amountUni = UniswapV2Library.getAmountOut(amount, reserveIn, reserveOut);
      }
    }
    {
      (uint256 reserve0, uint256 reserve1) = PairsLibrary.tryGetReserves(sushiPair);
      if (reserve0 > 0 && reserve1 > 0) {
        (uint256 reserveIn, uint256 reserveOut) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
        amountSushi = UniswapV2Library.getAmountOut(amount, reserveIn, reserveOut);
      }
    }
    return amountUni >= amountSushi ? (uniPair, amountUni) : (sushiPair, amountSushi);
  }

  function getMinimumAmountOut(address token, uint256 amountIn) public view returns (uint256) {
    uint256 averageAmountOut = oracle.computeAverageEthForTokens(token, amountIn, minTwapAge, maxTwapAge);
    return averageAmountOut.sub(mulBips(averageAmountOut, twapDiscountBips));
  }

/* ==========  Swaps  ========== */

  function execute(address token, address pair, uint256 amountIn, uint256 amountOut) internal {
    token.safeTransfer(pair, amountIn);
    (uint256 amount0Out, uint256 amount1Out) = token < address(weth) ? (uint256(0), amountOut) : (amountOut, uint256(0));
    IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
  }

  function sellTokenForETH(address token) external {
    sellTokenForETH(token, IERC20(token).balanceOf(address(this)));
  }

  function sellTokenForETH(address token, uint256 amountIn) public {
    require(token != address(weth), "Can not sell WETH");
    uint256 minimumAmountOut = getMinimumAmountOut(token, amountIn);
    (address pair, uint256 amountOut) = getBestPair(token, amountIn);
    require(amountOut >= minimumAmountOut, "Insufficient output");
    execute(token, pair, amountIn, amountOut);
  }

/* ==========  Distribution  ========== */

  function distributeETH() external {
    uint256 bal = address(this).balance;
    if (bal > 0) weth.deposit{value: bal}();
    bal = weth.balanceOf(address(this));
    if (bal > 0) {
      uint256 ethToTreasury = mulBips(bal, ethToTreasuryBips);
      address(weth).safeTransfer(treasury, ethToTreasury);
      dndx.distribute(bal - ethToTreasury);
    }
  }

/* ==========  Utils  ========== */

  function mulBips(uint256 a, uint256 bips) internal pure returns (uint256) {
    return a.mul(bips) / uint256(10000);
  }
}