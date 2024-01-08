pragma solidity ^0.8.0;

import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

/**
 * @notice ERC20 token with restricted loss-taking
 */
contract EmpireTest is ERC20, Pausable {
    using SafeMath for uint256;
    using Address for address payable;

    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private SUPPLY;
    uint256 private INITIAL_LIQUIDITY;

    address private _owner;

    address public _pair;

    uint256 private _openedAt;
    uint256 private _closedAt;

    mapping(address => uint256) public cooldownOf;

    /**
     * @notice deploy
     */
    constructor(uint256 supply) payable ERC20("Test", "TST") {
        _owner = msg.sender;

        SUPPLY = supply;
        INITIAL_LIQUIDITY = supply.mul(20).div(100);

        // mint to deployer
        _mint(msg.sender, SUPPLY);

        // setup uniswap pair and store address
        _pair = IUniswapV2Factory(IUniswapV2Router02(UNISWAP_ROUTER).factory())
        .createPair(WETH, address(this));

        // prepare to add liquidity
        _approve(address(this), UNISWAP_ROUTER, INITIAL_LIQUIDITY);

        // prepare to remove liquidity
        IERC20(_pair).approve(UNISWAP_ROUTER, type(uint256).max);
    }

    receive() external payable {}

    /**
     * @notice open trading
     * @dev sender must be owner
     * @dev trading must not yet have been opened
     */
    function open() external {
        require(msg.sender == _owner, "ERR: sender must be owner");
        require(_openedAt == 0, "ERR: already opened");

        _openedAt = block.timestamp;

        // add liquidity, set initial cost basis
        // _mint(address(this), SUPPLY);

        IUniswapV2Router02(UNISWAP_ROUTER).addLiquidityETH{
            value: address(this).balance
        }(
            address(this),
            INITIAL_LIQUIDITY,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /**
     * @notice close trading
     * @dev trading must not yet have been closed
     * @dev minimum time since open must have elapsed
     */
    function close() external {
        require(_openedAt != 0, "ERR: not yet opened");
        require(_closedAt == 0, "ERR: already closed");
        // require(block.timestamp > _openedAt + (1 days), "ERR: too soon"); // remove comment

        _closedAt = block.timestamp;

        (uint256 token, ) = IUniswapV2Router02(UNISWAP_ROUTER)
        .removeLiquidityETH(
            address(this),
            IERC20(_pair).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        _burn(address(this), token);
    }

    /**
     * @notice exchange BUFFDOGE for proportion of ETH in contract
     * @dev trading must have been closed
     */
    function liquidate() external {
        require(_closedAt > 0, "ERR: not yet closed");

        uint256 balance = balanceOf(msg.sender);

        require(balance != 0, "ERR: zero balance");

        uint256 payout = (address(this).balance * balance) / totalSupply();

        _burn(msg.sender, balance);
        payable(msg.sender).sendValue(payout);
    }

    /**
     * @notice withdraw remaining ETH from contract
     * @dev trading must have been closed
     * @dev minimum time since close must have elapsed
     */
    function liquidateUnclaimed() external {
        require(_closedAt > 0, "ERR: not yet closed");
        require(block.timestamp > _closedAt + (12 weeks), "ERR: too soon");
        payable(_owner).sendValue(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        // ignore minting and burning
        if (from == address(0) || to == address(0)) return;

        // ignore add/remove liquidity
        if (from == address(this) || to == address(this)) return;
        if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

        require(_openedAt > 0);

        // require(
        //     msg.sender == UNISWAP_ROUTER || msg.sender == _pair,
        //     "ERR: sender must be uniswap"
        // );

        if (from == _pair) {
            require(
                cooldownOf[to] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[to] = block.timestamp + (30 minutes);

            uint256 totalLiquidity = IERC20(address(this)).balanceOf(_pair);
            uint256 maxThreshold = totalLiquidity.mul(5) / 1000;

            require(amount >= maxThreshold, "Over 0.5% of total liquidity");
        } else if (to == _pair) {
            // blacklist Vitalik Buterin
            require(
                from != 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B /* revert message not returned by Uniswap */
            );
            require(
                cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[from] = block.timestamp + (30 minutes);
        }
    }

    /** Security */

    function pause() external {
        require(msg.sender == _owner, "ERR: sender must be owner");

        _pause();
    }

    function unpause() external {
        require(msg.sender == _owner, "ERR: sender must be owner");

        _unpause();
    }
}
