// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";

contract Illiquid is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 public constant BASE = 10**18;
    uint256 public constant DEV_FEE = 8;
    uint256 public liquidateTokensAtAmount = 1_000_000_000 * BASE; // minimum held in token contract to process fees

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public constant devAddress =
        0x198245020540F70814eCab6E4b9d54bD52ebE99e;
    bool private liquidating;
    bool public tradingEnabled; // whether the token can already be traded
    bool public isProcessing;
    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before trading starts
    mapping(address => bool) public canTransferBeforeTradingIsEnabled;

    event ExcludeFromFees(address indexed account, bool exclude);

    constructor() ERC20("ILLIQUID CAPITAL DAO", "ILLIQUID") {
        // exclude from paying fees or having max transaction amount
        address _owner = 0x10985bF226a6DD7a839C9F526DA02Bf6e4B7f8B7;
        _transferOwnership(_owner);
        _excludeFromFees(_owner, true);
        _excludeFromFees(address(this), true);
        // enable owner wallet to send tokens before presales are over.
        canTransferBeforeTradingIsEnabled[_owner] = true;
        _mint(_owner, 699_000_000_000 * BASE); // 699B tokens

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        //  Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
    }

    receive() external payable {}

    // view functions

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }


    // state functions
    // // owner restricted
    function activate() public onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    function addTransferBeforeTrading(address account) external onlyOwner {
        require(account != address(0), "Sets the zero address");
        canTransferBeforeTradingIsEnabled[account] = true;
    }

    function excludeFromFees(address account, bool exclude) public onlyOwner {
        _excludeFromFees(account, exclude);
    }
    function _excludeFromFees(address account, bool exclude) private {
        require(
            _isExcludedFromFees[account] != exclude,
            "Already has been assigned!"
        );
        _isExcludedFromFees[account] = exclude;
        emit ExcludeFromFees(account, exclude);
    }

    function updateAmountToLiquidateAt(uint256 liquidateAmount)
        external
        onlyOwner
    {
        require(
            (liquidateAmount >= 100_000_000 * BASE) &&
                (10_000_000_000 * BASE >= liquidateAmount),
            "should be 100M <= value <= 1B"
        );
        require(
            liquidateAmount != liquidateTokensAtAmount,
            "value already assigned!"
        );
        liquidateTokensAtAmount = liquidateAmount;
    }

    // emergency fee processing switch
    function switchProcessing(bool _isProcessing) external onlyOwner{
        require(isProcessing != _isProcessing);
        isProcessing = _isProcessing;
    }
    // private
    function sendEth(address account, uint256 amount) private {
        (bool success, ) = account.call{value: amount}("");
        require(success, "failed withdraw");
    }

    function swapAndSend(uint256 tokens) private {
        swapTokensForETH(tokens);
        uint256 dividends = address(this).balance;
        sendEth(devAddress, dividends);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the JoeTrader pair path of token -> ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of eth
            path,
            address(this),
            block.timestamp
        );
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        // blacklisting check

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool tradingIsEnabled = tradingEnabled;
        bool areMeet = !liquidating && tradingIsEnabled;
        bool hasContracts = isContract(from) || isContract(to);
        bool isFromLP = from == uniswapV2Pair;
        // only whitelisted addresses can make transfers before the public presale is over.
        if (!tradingIsEnabled) {
            //turn transfer on to allow for whitelist form/mutlisend presale
            require(
                canTransferBeforeTradingIsEnabled[from],
                "Trading is not enabled"
            );
        }

        if (hasContracts) {
            if (areMeet) {
                uint256 contractTokenBalance = balanceOf(address(this));

                bool canSwap = contractTokenBalance >= liquidateTokensAtAmount;

                if (canSwap && !isFromLP && isProcessing) {
                    liquidating = true;

                    swapAndSend(contractTokenBalance);

                    liquidating = false;
                }
            }

            bool takeFee = tradingIsEnabled && !liquidating;

            // if any account belongs to _isExcludedFromFee account then remove the fee
            if (
                _isExcludedFromFees[from] ||
                _isExcludedFromFees[to] ||
                (isFromLP && to == address(uniswapV2Router)) // third condition is for liquidity removing
            ) takeFee = false;

            if (takeFee) {
                uint256 fees = amount.mul(DEV_FEE).div(100);
                amount = amount.sub(fees);

                super._transfer(from, address(this), fees);
            }
        }
        super._transfer(from, to, amount);
    }
}
