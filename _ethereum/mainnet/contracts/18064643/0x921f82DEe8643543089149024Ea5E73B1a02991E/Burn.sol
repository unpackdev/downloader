// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title BURN🔥
 * @author memesonmondays.eth
 *   ⠀⠀⠀⠀⠀⠀⢱⣆⠀⠀⠀⠀⠀⠀
 *   ⠀⠀⠀⠀⠀⠀⠈⣿⣷⡀⠀⠀⠀⠀
 *   ⠀⠀⠀⠀⠀⠀⢸⣿⣿⣷⣧⠀⠀⠀
 *   ⠀⠀⠀⠀⡀⢠⣿⡟⣿⣿⣿⡇⠀⠀
 *   ⠀⠀⠀⠀⣳⣼⣿⡏⢸⣿⣿⣿⢀⠀
 *   ⠀⠀⠀⣰⣿⣿⡿⠁⢸⣿⣿⡟⣼⡆
 *   ⢰⢀⣾⣿⣿⠟⠀⠀⣾⢿⣿⣿⣿⣿
 *   ⢸⣿⣿⣿⡏⠀⠀⠀⠃⠸⣿⣿⣿⡿
 *   ⢳⣿⣿⣿⠀⠀   ⠀⠀⢹⣿⡿⡁
 *   ⠀⠹⣿⣿⡄⠀⠀⠀⠀⠀⢠⣿⡞⠁
 *   ⠀⠀⠈⠛⢿⣄⠀⠀⠀⣠⠞⠋⠀
 *           ⠙⠋⠀
 * https://BurnToken.xyz
 * https://MemesOnMondays.com
 * https://x.com/MemesOnMondays
 * 
 * @notice a celebration of burning man 2023 which closes
 * today. This token has a built in burn mechanism, any
 * tokens burnt are automatically matched by the team
 * 
 * 99% of tokens sent to Uniswap v3 liquidity pool,
 * 1% team allocation (50% locked and burnable 1 week),
 * contract renounced, LP position locked in contract.
 */

import "./ERC20.sol";
import "./Ownable.sol";

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

contract Burn is ERC20, Ownable {

    INonfungiblePositionManager posMan = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address weth;
    uint immutable uniswapSupply = 990_000_000 * 10 ** decimals();
    uint immutable teamSupply = 5_000_000 * 10 ** decimals();
    uint immutable teamSupplyLocked = 5_000_000 * 10 ** decimals();
    address public team;
    uint public deployedTimestamp;
    uint24 constant fee = 3000;
    string tokenName = unicode"BURN🔥";
    uint160 sqrtPriceX96;
    int24 minTick;
    int24 maxTick;
    address public pool;
    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;

    constructor() ERC20(tokenName, tokenName) {
        team = msg.sender;
        deployedTimestamp = block.timestamp;
        _mint(address(this), uniswapSupply + teamSupplyLocked);
        _mint(msg.sender, teamSupply);
        if (block.chainid == 1 || block.chainid == 31337) {
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else {
            weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        }
        setupUniswapV3();
        pool = posMan.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }

    function burn(uint _amount) public {
        _burn(_msgSender(), _amount);
        _burn(address(this), _amount); // match with teams locked funds
    }

    function withdrawAnythingLeft() public {
        require (block.timestamp > deployedTimestamp + 7 days, "too soon");
        uint bal = balanceOf(address(this));
        transfer(team, bal);
    }

    function setupUniswapV3() internal {
        if (address(this) < weth) {
            token0 = address(this);
            token1 = weth;
            sqrtPriceX96 = 7922427122162318518285487;
            amount0Desired = uniswapSupply;
            amount1Desired = 0;
            minTick = -184200;
            maxTick = 887220;
        } else {
            token0 = weth;
            token1 = address(this);
            sqrtPriceX96 = 792280926924313289846529216293289;
            amount0Desired = 0;
            amount1Desired = uniswapSupply;
            minTick = -887220;
            maxTick = 184200;
        }
    }

    /**
     * @notice 99% of liquidity is sent to Uniswap v3 and NFT LP token
     * is locked in the contract with no methods to remove or redeem it
     * Ownership renounced at end of this function
     */
    function addLiquidity() external onlyOwner {
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
        renounceOwnership();
    }
}