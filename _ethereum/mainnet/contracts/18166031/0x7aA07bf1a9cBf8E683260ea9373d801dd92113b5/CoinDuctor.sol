// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )  external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract CoinDuctor is Ownable, ERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public presaleContractAddress;

    bool private swapping = false;
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public maxWallet;
    uint256 public totalFees;
    uint256 public swapTokensAtAmount;

    address public teamWallet;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    modifier onlyPresale {
        require(msg.sender == presaleContractAddress, "Sender must be presale");
        _;
    }

    constructor(
        address _uniswapV2RouterAddress,
        address _teamWallet,
        uint256 _totalSupply
    ) ERC20("CoinDuctor", "CDR") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        totalFees = 25;

        swapTokensAtAmount = (_totalSupply * 5) / 10000; // 0.05%

        maxWallet = (_totalSupply * 2) / 100; // 2%;
        teamWallet = address(_teamWallet);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}

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

        if (limitsInEffect && tradingActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (automatedMarketMakerPairs[to] && totalFees > 0) {
                fees = amount.mul(totalFees).div(100);
            } else if (automatedMarketMakerPairs[from] && totalFees > 0) {
                fees = amount.mul(totalFees).div(100);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool success;

        if (contractTokenBalance > swapTokensAtAmount * 20) {
            contractTokenBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractTokenBalance);

        (success, ) = address(teamWallet).call{value: address(this).balance}("");
    }

    function enableTrading() external onlyPresale {
        require(!tradingActive, "trading is already active");

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        tradingActive = true;
        swapEnabled = true;
    }

    function setTotalFees(uint8 totalFees_) public onlyOwner {
        totalFees = totalFees_;
    }

    function setMaxWallet(uint256 maxWallet_) public onlyOwner {
        require(maxWallet_ >= (super.totalSupply() * 1) / 100, "maxWallet cannot be lower than 1% of totalSupply");
        require(maxWallet_ <= (super.totalSupply() * 10) / 100, "maxWallet cannot be higher than 10% of totalSupply");

        maxWallet = maxWallet_;
    }

    function setTeamWallet(address teamWallet_) public onlyOwner {
        teamWallet = teamWallet_;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setPresaleContractAddress(address presaleContractAddress_) public onlyOwner {
        presaleContractAddress = presaleContractAddress_;
        excludeFromFees(presaleContractAddress_, true);
    }

    function setLimitsInEffect(bool limitsInEffect_) external onlyOwner {
        limitsInEffect = limitsInEffect_;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawStuckTokens() external onlyOwner {
        super._transfer(address(this), owner(), balanceOf(address(this)));
    }

    function withdrawStuckEth() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");

        require(success);
    }
}
