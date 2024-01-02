// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";


/**
 * 
 *    ___            _      __     __    _____    __    _     ___            _   
 *   / __\  /\  /\  /_\    /__\   / /    \_   \  /__\  | |   / __\  /\  /\  /_\  
 *  / /    / /_/ / //_\\  / \//  / /      / /\/ /_\   / __) / /    / /_/ / //_\\ 
 * / /___ / __  / /  _  \/ _  \ / /___ /\/ /_  //__   \__ \/ /___ / __  / /  _  \
 * \____/ \/ /_/  \_/ \_/\/ \_/ \____/ \____/  \__/   (   /\____/ \/ /_/  \_/ \_/
 *                                                    |_| 
 * https://charlie-eth.com
 * https://t.me/Charlie_ETHPortal
 * https://twitter.com/Charlie_ETHER                                                                                                  
 *          
 *         
 *    
 */
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

contract Charlie is ERC20, Ownable {
    INonfungiblePositionManager posMan = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address constant marketing = 0x68b9eE151075E27C9F9C3d4CF080a3016D6C8616;
    uint immutable uniswapSupply = 480_000_000 * 10 ** decimals();
    uint immutable marketingSupply = 20_000_000 * 10 ** decimals();

    uint24 constant fee = 3000;
    uint160 sqrtPriceX96;
    int24 minTick;
    int24 maxTick;
    address public pool;
    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;



    constructor() ERC20("Charlie", "CHA") Ownable (msg.sender){
        _mint(address(this), uniswapSupply);
        _mint(marketing, marketingSupply);
        fixOrdering();
        pool = posMan.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }



    function fixOrdering() private {
        if (address(this) < weth) {
            token0 = address(this);
            token1 = weth;
            sqrtPriceX96 = 56022299269611287018253980;
            amount0Desired = uniswapSupply;
            amount1Desired = 0;
            minTick = -145080;
            maxTick = 887220;
        } else {
            token0 = weth;
            token1 = address(this);
            sqrtPriceX96 = 112040883463736372645278684184779;
            amount0Desired = 0;
            amount1Desired = uniswapSupply;
            minTick = -887220;
            maxTick = 145080;
        }
    }



    function addLiquidity() public onlyOwner {
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