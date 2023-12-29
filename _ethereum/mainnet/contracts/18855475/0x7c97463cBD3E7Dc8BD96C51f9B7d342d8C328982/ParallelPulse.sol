// SPDX-License-Identifier: AGPL-3.0-or-later
pragma abicoder v2;
pragma solidity ^0.7.5;
import "./EnumerableSet.sol";
import "./IERC2612Permit.sol";
import "./IERC20.sol";
import "./ERC20Permit.sol";
import "./VaultOwned.sol";
import "./IWETH.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";

contract ParallelPulse is ERC20Permit, VaultOwned {
    using SafeMath for uint256;

    IUniswapV2Router public router =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    address private treasury;

    uint256 public buyTax = 5;

    uint256 public sellTax = 5;

    mapping(address => bool) private _isExcludedFromTaxes;

    mapping(address => bool) public automatedMarketMakerPairs;

    receive() external payable {}

    constructor() ERC20("ParallelPulse.xyz", "PULSE", 18) {
        _mint(msg.sender, 1_000_000_000 * 1e18);

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        treasury = msg.sender;

        excludeFromTaxes(owner(), true);
        excludeFromTaxes(address(this), true);
        excludeFromTaxes(address(0xdead), true);
    }

    function excludeFromTaxes(address account, bool excluded) public onlyOwner {
        _isExcludedFromTaxes[account] = excluded;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function removeTaxes() external onlyOwner {
        buyTax = 0;
        sellTax = 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool takeTax = true;

        if (_isExcludedFromTaxes[from] || _isExcludedFromTaxes[to]) {
            takeTax = false;
        }
        uint256 taxes = 0;
        if (takeTax) {
            if (automatedMarketMakerPairs[to] && sellTax > 0) {
                taxes = amount.mul(sellTax).div(100);
            } else if (automatedMarketMakerPairs[from] && buyTax > 0) {
                taxes = amount.mul(buyTax).div(100);
            }
            if (taxes > 0) {
                super._transfer(from, treasury, taxes);
            }

            amount -= taxes;
        }

        super._transfer(from, to, amount);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
}
