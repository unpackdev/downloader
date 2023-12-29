//SPDX-License-Identifier: MIT

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
//                   SOCIALS                      //
//         WEB: https://linqchad.vip/             //
//    TELEGRAM: https://t.me/LinQChad             //
//    TWITTER: https://twitter.com/LinQChadERC    //        
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

pragma solidity ^0.8.10;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract linQChad is ERC20, Ownable {

    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isTxMaxExcluded;
    mapping(address => bool) public automatedMarketMakerPairs;

    address public linqAddress = address(0x3e34eabF5858a126cb583107E643080cEE20cA64);
    address public constant deadAddress = address(0xdead);
    address public teamWallet;
    address public uniswapV2Pair;

    bool public isLimitActive;
    bool public isTradingOpen;
    bool public swapEnabled;
    bool private swapping;
  
    uint256 public bAutobuyFee = 4;
    uint256 public bLpFee = 0;
    uint256 public bTeamFee = 2;
    uint256 public buyTotalFees = bLpFee + bTeamFee + bAutobuyFee;

    uint256 public sAutobuyFee = 4;
    uint256 public sLpFee = 0;
    uint256 public sTeamFee = 2;
    uint256 public sellTotalFees = sLpFee + sTeamFee + sAutobuyFee;

    uint256 public _autoBuyTokenShare;
    uint256 public _LpTokenShare;
    uint256 public _teamTokenShare;

    uint256 public maxTX;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;

    event ExcludeFromFees(address Acc, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("linQChad", "LINQCHAD") {
        uint256 totalSupply = 1_000_000_000 * 1e18;
        _mint(msg.sender, totalSupply);
    }

    function initContract() external onlyOwner {
   
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this),uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        isLimitActive = true;
        isTradingOpen = false;
        swapEnabled = false;

        maxTX = 10000000 * 1e18;
        maxWallet = 20000000 * 1e18;
        swapTokensAtAmount = (this.totalSupply() * 5) / 10000;

        excludeFromFee(owner(), true);
        excludeFromFee(address(this), true);
        excludeFromFee(address(0xdead), true);

        _excludeFromMaxTx(owner(), true);
        _excludeFromMaxTx(address(this), true);
        _excludeFromMaxTx(address(0xdead), true);
        _excludeFromMaxTx(address(uniswapV2Router), true);
        _excludeFromMaxTx(address(uniswapV2Pair), true);
    }

    function launchLinQChad() external onlyOwner {
        isTradingOpen = true;
        swapEnabled = true;
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

        if (isLimitActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!isTradingOpen) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // buying
                if (automatedMarketMakerPairs[from] && !_isTxMaxExcluded[to]) {
                    require(
                        amount <= maxTX,
                        "Buy transfer amount exceeds the maxTX."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //selling
                else if (
                    automatedMarketMakerPairs[to] && !_isTxMaxExcluded[from]
                ) {
                    require(
                        amount <= maxTX,
                        "Sell transfer amount exceeds the maxTX."
                    );
                } else if (!_isTxMaxExcluded[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
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
            swap();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                _LpTokenShare += (fees * sLpFee) / sellTotalFees;
                _teamTokenShare += (fees * sTeamFee) / sellTotalFees;
                _autoBuyTokenShare += (fees * sAutobuyFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                _LpTokenShare += (fees * bLpFee) / buyTotalFees;
                _teamTokenShare += (fees * bTeamFee) / buyTotalFees;
                _autoBuyTokenShare += (fees * bAutobuyFee) / buyTotalFees;
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function autoBuyLinq(uint256 ethAmt) private {
        if (ethAmt > 0) {
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = linqAddress;
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: ethAmt
            }(0, path, teamWallet, block.timestamp);
        }
    }

    function swap() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _LpTokenShare +
            _autoBuyTokenShare +
            _teamTokenShare;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * _LpTokenShare) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForTeam = ethBalance.mul(_teamTokenShare).div(
            totalTokensToSwap - (_LpTokenShare / 2)
        );
        uint256 ethForBuyback = ethBalance.mul(_autoBuyTokenShare).div(
            totalTokensToSwap - (_LpTokenShare / 2)
        );

        uint256 ethForLiquidity = ethBalance - ethForBuyback - ethForTeam;

        _LpTokenShare = 0;
        _autoBuyTokenShare = 0;
        _teamTokenShare = 0;

        (success, ) = address(teamWallet).call{value: ethForTeam}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                _LpTokenShare
            );
        }
        autoBuyLinq(ethForBuyback);
    }

    function isExcludedFromFees(address Acc) public view returns (bool) {
        return _isExcludedFromFees[Acc];
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function removeLimits() external onlyOwner returns (bool) {
        isLimitActive = false;
        return true;
    }

    function updateMaxTx(uint256 amount) external onlyOwner {
        require(
            amount >= ((totalSupply() * 5) / 1000) / 1e18,
            "must be bigger than 0.5%"
        );
        maxTX = amount * (10**18);
    }

    function setSwapLimit(uint256 amt) external onlyOwner returns (bool) {
        require(
            amt >= (totalSupply() * 1) / 100000,
            "Swap limit must be higher than 0.001% total supply."
        );
        require(
            amt <= (totalSupply() * 5) / 1000,
            "Swap limit cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = amt;
        return true;
    }


    function setSwapEnabled(bool action) external onlyOwner {
        swapEnabled = action;
    }

    function _excludeFromMaxTx(address newAdd, bool action) public onlyOwner {
        _isTxMaxExcluded[newAdd] = action;
    }

    function updateBuyFees(
        uint256 _autoFee,
        uint256 _lpFee,
        uint256 _teamFee
    ) external onlyOwner {
        bAutobuyFee = _autoFee;
        bLpFee = _lpFee;
        bTeamFee = _teamFee;
        buyTotalFees = bAutobuyFee + bLpFee + bTeamFee;
        require(buyTotalFees <= 6);
    }

    function updateSellFees(
        uint256 _autoSFee,
        uint256 _lpSFee,
        uint256 _teamSFee
    ) external onlyOwner {
        sAutobuyFee = _autoSFee;
        sLpFee = _lpSFee;
        sTeamFee = _teamSFee;
        sellTotalFees = sAutobuyFee + sLpFee + sTeamFee;
        require(sellTotalFees <= 6);
    }

    function excludeFromFee(address Acc, bool excluded) public onlyOwner {
        _isExcludedFromFees[Acc] = excluded;
        emit ExcludeFromFees(Acc, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner{
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function resetTeamWallet(address newWallet) external onlyOwner {
        teamWallet = newWallet;
    }

    function withdrawStuckEth(address newAdd) external onlyOwner {
        (bool success, ) = newAdd.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}
}
