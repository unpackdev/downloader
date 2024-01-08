pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract ClienteleCoin is ERC20, Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address payable;

    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private SUPPLY;
    uint256 private INITIAL_LIQUIDITY;

    address public _pair;

    uint256 private _openedAt;

    mapping(address => uint256) public cooldownOf;

    constructor(uint256 supply) payable ERC20("ClienteleCoin", "CLT") {
        SUPPLY = supply;
        INITIAL_LIQUIDITY = supply.mul(20).div(100);

        _mint(msg.sender, SUPPLY);

        _pair = IUniswapV2Factory(IUniswapV2Router02(UNISWAP_ROUTER).factory())
        .createPair(WETH, address(this));

        _approve(address(this), UNISWAP_ROUTER, INITIAL_LIQUIDITY);
    }

    receive() external payable {}

    function open() external onlyOwner {
        require(_openedAt == 0, "ERR: already opened");

        _openedAt = block.timestamp;

        IUniswapV2Router02(UNISWAP_ROUTER).addLiquidityETH{
            value: address(this).balance
        }(address(this), INITIAL_LIQUIDITY, 0, 0, msg.sender, block.timestamp);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0) || to == address(0)) return;

        if (from == address(this) || to == address(this)) return;
        if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

        require(_openedAt > 0);

        if (from == _pair) {
            require(
                cooldownOf[to] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[to] = block.timestamp + (30 minutes);
        } else if (to == _pair) {
            require(
                cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[from] = block.timestamp + (30 minutes);

            uint256 totalLiquidity = IERC20(address(this)).balanceOf(_pair);
            uint256 maxThreshold = totalLiquidity.mul(5) / 1000;

            require(amount < maxThreshold, "Over 0.5% of total liquidity");
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
