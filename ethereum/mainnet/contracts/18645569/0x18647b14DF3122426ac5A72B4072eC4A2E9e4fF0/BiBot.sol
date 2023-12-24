// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./ERC20.sol";
import "./Ownable.sol";
import "./Library.sol";
import "./IERC20.sol";

contract BiBot is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public revShareWallet;
    address public teamWallet;

    uint256 public swapTokensAtAmount;

    bool public swapEnabled = true;
    uint public buyTotalFees;
    uint256 public buyRevShareFee;
    uint256 public buyTeamFee;
    uint256 public sellTotalFees;
    uint256 public sellRevShareFee;
    uint256 public sellTeamFee;
    uint256 public tokensForRevShare;
    uint256 public tokensForTeam;
    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event revShareWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );
    event teamWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("BIBOT", "BBT") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;
        uint256 _buyRevShareFee = 4;
        uint256 _buyTeamFee = 6;
        //40 % team  60% share
        uint256 _sellRevShareFee = 4;
        uint256 _sellTeamFee = 6;
        uint256 totalSupply = 100_000_000 * 1e18;

        swapTokensAtAmount = (totalSupply * 5) / 10000000; // 0.005%

        buyRevShareFee = _buyRevShareFee;
        buyTeamFee = _buyTeamFee;
        buyTotalFees = buyRevShareFee + buyTeamFee;
        sellRevShareFee = _sellRevShareFee;
        sellTeamFee = _sellTeamFee;
        sellTotalFees = sellRevShareFee + sellTeamFee;
        revShareWallet = owner(); // set as revShare wallet
        teamWallet = owner();

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _revShareFee,
        uint256 _teamFee
    ) external onlyOwner {
        buyRevShareFee = _revShareFee;
        buyTeamFee = _teamFee;
        buyTotalFees = buyRevShareFee + buyTeamFee;
        require(buyTotalFees <= 5, "Buy fees must be <= 50.");
    }

    function updateSellFees(
        uint256 _revShareFee,
        uint256 _teamFee
    ) external onlyOwner {
        sellRevShareFee = _revShareFee;
        sellTeamFee = _teamFee;
        sellTotalFees = sellRevShareFee + sellTeamFee;
        require(sellRevShareFee <= 5, "Sell fees must be <= 50.");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateRevShareWallet(
        address newRevShareWallet
    ) external onlyOwner {
        emit revShareWalletUpdated(newRevShareWallet, revShareWallet);
        revShareWallet = newRevShareWallet;
    }

    function updateTeamWallet(address newWallet) external onlyOwner {
        emit teamWalletUpdated(newWallet, teamWallet);
        teamWallet = newWallet;
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

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(1000);
                tokensForTeam += (fees * sellTeamFee) / sellTotalFees;
                tokensForRevShare += (fees * sellRevShareFee) / sellTotalFees;
            }
            // on buy
            if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(1000);
                tokensForTeam += (fees * buyTeamFee) / buyTotalFees;
                tokensForRevShare += (fees * buyRevShareFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForTeam;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }
        
        swapTokensForEth(totalTokensToSwap);

        tokensForTeam = 0;

        super._transfer(address(this), revShareWallet, tokensForRevShare);

        tokensForRevShare = 0;

        (success, ) = address(teamWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckBibot() external onlyOwner {
        uint256 balance = IERC20(address(this)).balanceOf(address(this));
        IERC20(address(this)).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawStuckToken(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }


}
