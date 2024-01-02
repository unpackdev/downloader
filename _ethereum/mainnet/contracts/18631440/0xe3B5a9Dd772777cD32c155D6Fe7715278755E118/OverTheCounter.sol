pragma solidity ^0.8.21;

import "./ERC20.sol";

/******************************************************************************************************\
                     ██████╗ ██╗   ██╗███████╗██████╗     ████████╗██╗  ██╗███████╗                    |
                    ██╔═══██╗██║   ██║██╔════╝██╔══██╗    ╚══██╔══╝██║  ██║██╔════╝                    |
                    ██║   ██║██║   ██║█████╗  ██████╔╝       ██║   ███████║█████╗                      |
                    ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗       ██║   ██╔══██║██╔══╝                      |
                    ╚██████╔╝ ╚████╔╝ ███████╗██║  ██║       ██║   ██║  ██║███████╗                    |
                     ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝       ╚═╝   ╚═╝  ╚═╝╚══════╝                    |
                      ██████╗ ██████╗ ██╗   ██╗███╗   ██╗████████╗███████╗██████╗                      |
                     ██╔════╝██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗                     |
                     ██║     ██║   ██║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝                     |
                     ██║     ██║   ██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗                     |
                     ╚██████╗╚██████╔╝╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║                     |
                      ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝                     |
******************************************************************************************************/
/*            A minimually invasive slow release token to tepid any bots most fervent desires.
 *          A token designed to power the next generation zero slippage over the counter exchange.
 */

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
}

uint256 constant TRUE = 2;
uint256 constant FALSE = 1;

contract OverTheCounter is ERC20 {
    address public uniswapV2pair;
    uint256 public initialLiquidity;
    uint256 blockListed;
    uint256 antisnipe = TRUE;

    error SlowTokenRelease();

    constructor() ERC20("OverTheCounter", "OTC", 18) {
        _mint(msg.sender, 1000000 * 1e18);
        IUniswapV2Router router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        uniswapV2pair = factory.createPair(address(this), router.WETH());
    }
    
    function maxBuyAmount() public view returns (uint256) {
        if(antisnipe == TRUE && block.number - blockListed < 300) {
            return (initialLiquidity / 300) * (block.number - blockListed);
        }
        else {
            return type(uint256).max;
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if(antisnipe == TRUE && blockListed > 0 && msg.sender == uniswapV2pair) {
            if( block.number - blockListed < 300) {
                uint256 maxAmount = maxBuyAmount();
                if(amount > maxAmount) revert SlowTokenRelease();
            }
            else {
                antisnipe = FALSE;
            }
        }
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if(antisnipe == TRUE && blockListed == 0 && to == uniswapV2pair) {
            initialLiquidity = amount;
            blockListed = block.number;
        }
        return super.transferFrom(from, to, amount);
    }
}

