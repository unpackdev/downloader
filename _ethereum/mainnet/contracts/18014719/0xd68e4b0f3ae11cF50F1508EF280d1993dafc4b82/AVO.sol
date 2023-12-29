// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title AvocadoToast
 * @author memesonmondays.eth
 * 
 *     ▓▓▓▓▓▓    ▓▓▓▓▓▓
 *   ▓▓░░░░░░▓▓▓▓░░░░░░▓▓
 * ▓▓░░░░░░░░░░░░░░░░░░░░▓▓
 * ▓▓░░░░██  ░░░░██  ░░░░▓▓
 *   ▓▓░░░░░░░░░░░░░░░░▓▓ 
 *   ▓▓░░░░░░░░░░░░░░░░▓▓
 *   ▓▓░░▓▓▓▓▓▓▓▓▓▓░░░░▓▓
 *   ▓▓░░░░░      ░░░░░▓▓ 
 *   ▓▓░░░░░░░░░░░░░░░░▓▓ 
 *   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
 * https://AvocadoToken.xyz
 * https://MemesOnMondays.com
 * https://x.com/MemesOnMondays
 * 
 * @notice Just like the delicious brunch dish, 
 * this memecoin is the perfect blend of thrill,
 * zest, and healthy investment strategies! True 
 * to its name, Avocado Toast doesn’t only represent 
 * a social phenomenon but is poised to combine the 
 * new age excitement of crypto with an avocado twist
 */

import "./ERC20.sol";

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    function mint(MintParams calldata params) external payable returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

contract AvocadoToast is ERC20 {
    /**
     * @notice Laughter is the best medicine,
     * almost as good for you as avocado toast!
     */
    function whyDidTheAvocadoCrossTheRoad() external pure returns (string memory) {
        return 'to get smashed on toast!';
    }
    /**
     * @dev these jokes cost hundreds of dollars to
     * deploy on Ethereum... maybe no one will see them
     */
    function whatIsAvocadosFavoriteMusic() external pure returns (string memory) {
        return 'Guac n roll!';
    }

    INonfungiblePositionManager posMan = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address weth;
    uint immutable uniswapSupply = 990_000_000 * 10 ** decimals();
    uint immutable devSupply = 10_000_000 * 10 ** decimals();
    uint24 constant fee = 500;
    uint160 sqrtPriceX96;
    int24 minTick;
    int24 maxTick;
    address public pool;
    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;

    constructor() ERC20("AvocadoToast", "AVO") {
        _mint(address(this), uniswapSupply);
        _mint(msg.sender, devSupply);
        if (block.chainid == 1 || block.chainid == 31337) {
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else {
            weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        }
        setupUniswapV3();
        pool = posMan.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }

    function setupUniswapV3() internal {
        if (address(this) < weth) {
            token0 = address(this);
            token1 = weth;
            sqrtPriceX96 = 35430489019307872761053455;
            amount0Desired = uniswapSupply;
            amount1Desired = 0;
            minTick = -154250;
            maxTick = 887270;
        } else {
            token0 = weth;
            token1 = address(this);
            sqrtPriceX96 = 177157811748422129510100785485839;
            amount0Desired = 0;
            amount1Desired = uniswapSupply;
            minTick = -887270;
            maxTick = 154250;
        }
    }

    /**
     * @notice 99% of liquidity is sent to Uniswap v3 and NFT LP token
     * is locked in the contract with no methods to remove or redeem it
     */
    function addLiquidity() external {
        IERC20(address(this)).approve(address(posMan), uniswapSupply);
        posMan.mint(INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: minTick,
            tickUpper: maxTick,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 1200
        }));
    }
}