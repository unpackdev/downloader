/**
 *Submitted for verification at Etherscan.io on 2023-10-20
*/

/*
   VegaFi - Algorithmic Reflexivity

                                                 ,/
                                                //
                                              ,//
                                  ___   /|   |//
                              `__/\_ --(/|___/-/
                           \|\_-\___ __-_`- /-/ \.
                          |\_-___,-\_____--/_)' ) \
                           \ -_ /     __ \( `( __`\|
                           `\__|      |\)\ ) /(/|
   ,._____.,            ',--//-|      \  |  '   /
  /     __. \,          / /,---|       \       /
 / /    _. \  \        `/`_/ _,'        |     |
|  | ( (  \   |      ,/\'__/'/          |     |
|  \  \`--, `_/_------______/           \(   )/
| | \  \_. \,                            \___/\
| |  \_   \  \                                 \
\ \    \_ \   \   /                             \
 \ \  \._  \__ \_|       |                       \
  \ \___  \      \       |                        \
   \__ \__ \  \_ |       \                         |
   |  \_____ \  ____      |                        |
   | \  \__ ---' .__\     |        |               |
   \  \__ ---   /   )     |        \              /
    \   \____/ / ()(      \          `---_       /|
     \__________/(,--__    \_________.    |    ./ |
       |     \ \  `---_\--,           \   \_,./   |
       |      \  \_ ` \    /`---_______-\   \\    /
        \      \.___,`|   /              \   \\   \
         \     |  \_ \|   \              (   |:    |
          \    \      \    |             /  / |    ;
           \    \      \    \          ( `_'   \  |
            \.   \      \.   \          `__/   |  |
              \   \       \.  \                |  |
               \   \        \  \               (  )
                \   |        \  |              |  |
                 |  \         \ \              I  `
                 ( __;        ( _;            ('-_';
                 |___\        \___:            \___:

   Telegram:  https://t.me/vegafiportal
   Twitter/X: https://twitter.com/VegaFiOfficial
   Website:   https://vegafi.io
   Docs:      https://docs.vegafi.io
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";
import "./IERC20.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract VegaFi {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) public antibot;
    mapping(address => bool) public noMax;
    string public name = "VegaFi";
    string public symbol = "VGA";
    uint8 public decimals = 18;

    INonfungiblePositionManager public nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public pool;
    address public quant;
    uint256 public buyFee = 10000;
    uint256 public bolsterReward = 5000;
    uint256 public buyFeeBalance;
    uint256 public maxWalletPercent = 100;

    modifier onlyQuant() {
        require(msg.sender == quant, "Not quant!");
        _;
    }

    constructor() {
      quant = msg.sender;
      noMax[address(this)] = true; // Lets the smart contract collectAllFees

      uint amount = 10_000_000 * (10 ** 18);
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);

      address token0 = address(this) < WETH ? address(this) : WETH;
      address token1 = address(this) < WETH ? WETH : address(this);
      uint24 fee = 10000;
      uint160 sqrtPriceX96 = token0 == address(this) ? 100000000000000000000000000 : 62771017353866810000000000000000;

      pool = initializePool(token0, token1, fee, sqrtPriceX96);
    }

    // Creates UniswapV3 "address(this)-WETH" pool
    function initializePool(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) public returns (address) {
      return nonfungiblePositionManager.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }

    // ERC20 standard functions
    function transfer(address recipient, uint amount) public returns (bool) {
        require(antibot[msg.sender] == false, "Bot detected!");

        if (msg.sender == pool) {

          balanceOf[msg.sender] -= amount;

          uint amountNoFee = handleTaxedTokens(msg.sender, amount);

          if (!noMax[recipient]) {
            uint256 maxWallet = totalSupply * maxWalletPercent / 100_000;
            require(balanceOf[recipient] + amountNoFee <=  maxWallet, "Max wallet exceeded!");
          }

          balanceOf[recipient] += amountNoFee;
          emit Transfer(msg.sender, recipient, amountNoFee);
          return true;

        } else {
          balanceOf[msg.sender] -= amount;
          balanceOf[recipient] += amount;
          emit Transfer(msg.sender, recipient, amount);
          return true;
        }
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public returns (bool) {
        require(antibot[sender] == false, "Bot detected!");

        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    // Quant helpers
    function mintNewPosition(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint amount0Desired,
        uint amount1Desired,
        uint amount0Min,
        uint amount1Min
    ) public onlyQuant returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        IERC20(token0).approve(address(nonfungiblePositionManager), amount0Desired);
        IERC20(token1).approve(address(nonfungiblePositionManager), amount1Desired);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );
    }

    function collectAllFees(
        uint tokenId
    ) public onlyQuant returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function increaseLiquidityCurrentRange(
        address token0,
        address token1,
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd,
        uint amount0Min,
        uint amount1Min
    ) public onlyQuant returns (uint128 liquidity, uint amount0, uint amount1) {
        IERC20(token0).approve(address(nonfungiblePositionManager), amount0ToAdd);
        IERC20(token1).approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(
            params
        );
    }

    function decreaseLiquidityCurrentRange(
        uint tokenId,
        uint128 liquidity,
        uint amount0Min,
        uint amount1Min
    ) public onlyQuant returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
    }

    // Buy fee swap function
    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMinimum
    ) private returns (uint amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    // Deducts fee from buy orders
    function handleTaxedTokens(address sender, uint amount) private returns (uint) {
          uint256 _fee = amount * buyFee / 100_000;
          balanceOf[address(this)] += _fee;
          buyFeeBalance += _fee;
          emit Transfer(sender, address(this), _fee);

          return amount - _fee;
    }

    // Earn money by calling this function
    function bolsterLiquidityAndEarn() public {
        require(buyFeeBalance > 0);
        uint amountOut = swapExactInputSingleHop(address(this), WETH, 10000, buyFeeBalance, 0);
        buyFeeBalance = 0;

        uint reward = amountOut * bolsterReward / 100_000;
        IERC20(WETH).transfer(msg.sender, reward);
    }

    // Reflexivity insurance
    function upgradeQuant(address _quant) public onlyQuant {
      quant = _quant;
    }

    function modulateFees(uint256 _buyFee, uint256 _bolsterReward, uint256 _maxWalletPercent) public onlyQuant {
      buyFee = _buyFee;
      bolsterReward = _bolsterReward;
      maxWalletPercent = _maxWalletPercent;
    }

    function toggleAntibot(address target) public onlyQuant {
      antibot[target] = !antibot[target];
    }

    function changeNoMax(address target, bool value) public onlyQuant {
      noMax[target] = value;
    }

    // Emergency
    function rescue(address token) public onlyQuant {
      require(token != address(this) && token != WETH);

      if (token == 0x0000000000000000000000000000000000000000) {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
      } else {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
      }
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}
