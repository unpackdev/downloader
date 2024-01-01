// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract GARY is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    uint256 public buyFees;
    uint256 public sellFees;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransaction(address indexed account, bool excluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("GARY", "$GARY ") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 480 * 1e12 * 1e18;

        maxTransactionAmount = ((totalSupply * 1) / 100); // 1% maxTransactionAmountTxn
        maxWallet = ((totalSupply * 2) / 100); // 2% max wallet

        buyFees = 5;
        sellFees = 5;

        excludeFromFees(msg.sender, true); // Owner address
        excludeFromFees(address(this), true); // CA
        excludeFromFees(address(0xdead), true); // Burn address

        excludeFromMaxTransaction(msg.sender, true); // Owner address
        excludeFromMaxTransaction(address(this), true); // CA
        excludeFromMaxTransaction(address(0xdead), true); // Burn address

        _mint(msg.sender, totalSupply);
    }

    function updateLimits(
        uint256 _maxTransactionAmount,
        uint256 _maxWallet
    ) external onlyOwner {
        if (_maxTransactionAmount > 0) {
            require(
                _maxTransactionAmount >= (totalSupply() * 1) / 100,
                "Cannot set maxTransactionAmount lower than 1%"
            );
            maxTransactionAmount = _maxTransactionAmount;
        }

        if (_maxWallet > 0) {
            require(
                _maxWallet >= (totalSupply() * 2) / 100,
                "Cannot set maxWallet lower than 2%"
            );
            maxWallet = _maxWallet;
        }
    }

    function removeLimits() external onlyOwner {
        maxTransactionAmount = totalSupply();
        maxWallet = totalSupply();
    }

    function excludeFromMaxTransaction(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[account] = excluded;
        emit ExcludeFromMaxTransaction(account, excluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateBuyFees(uint256 newBuyFees) external onlyOwner {
        buyFees = newBuyFees;
        require(buyFees <= 10, "Must keep buy fees at 10% or less");
    }

    function updateSellFees(uint256 newSellFees) external onlyOwner {
        sellFees = newSellFees;
        require(sellFees <= 10, "Must keep sell fees at 10% or less");
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
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
        if (from != owner() && to != owner() && to != address(0xdead)) {
            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        uint256 fees = 0;
        if (takeFee) {
            uint256 tokensForBurn;
            if (automatedMarketMakerPairs[to] && sellFees > 0) {
                fees = amount.mul(sellFees).div(100);
                tokensForBurn = (fees * 1) / sellFees;
            } else if (automatedMarketMakerPairs[from] && buyFees > 0) {
                fees = amount.mul(buyFees).div(100);
                tokensForBurn = (fees * 1) / buyFees;
            }

            if (fees > 0) {
                super._transfer(from, owner(), fees - tokensForBurn);
            }

            if (tokensForBurn > 0) {
                super._transfer(from, deadAddress, tokensForBurn);
                tokensForBurn = 0;
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }
}
