// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ICasino.sol";

/*

      @@          @@@@@        @@@@@@     @@@@    @@@     @@@               
   @@@@@@@@@      @@@@@+     @@@@@@@@@@   @@@@    @@@     @@@    @@@@@@@@@   
  @@@    @@@     @@@ @@@     @@@    @@@   @@@@    @@@@    @@@   +@@@    @@@  
 @@@@    @@@     @@@ @@@     @@@    @@@@  @@@@    @@@@@   @@@   @@@@    @@@@ 
 @@@@            @@@ @@@     @@@@         @@@@    @@@@@@  @@@   @@@@    @@@@ 
 @@@@           @@@   @@@      @@@@@      @@@@   @@@@ @@@ @@@   @@@@    @@@@ 
 @@@@          @@@@   @@@@      @@@@@     @@@@   @@@@ @@@@@@@   @@@@    @@@@ 
 @@@@           @@@   @@@          @@@@   @@@@    @@@  @@@@@@   #@@@    @@@@.
 @@@@     =@@  @@@@@@@@@@@   @@@    @@@   @@@@    @@@   @@@@@   @@@@    @@@@ 
 @@@@    @@@   @@@@@@@*@@@   @@@    @@@   @@@@    @@@    @@@@   @@@@    @@@@ 
 @@@@    @@@   @@@     @@@   @@@@@@@@@@   @@@@    @@@     @@@    @@@    @@@@ 
  @@@@@@@@@    @@@     @@@%    @@@@@..    @@@@   @@@@     @@@     @@@@@@@@@  
   @@@@@@                                                           @@@@@    
                                 @#  @@@  *@                                 
                          @@@@@@*           .@@@@@@#          
                                                                             
                    @@@@@    @@@   @@@@@ @@@@@@ @@@@@@  @@                     
                   @@  @@   @@@@   @  @@   @@   @@      @@                     
                   @@      @@  @@  @  @@   @@   @@      @@                     
                   @@      @@  @@  @=-@@   @@   @@@@@@  @@                     
                   @@  @@  @@@@@@  @ @@    @@   @@      @@                     
                   @@  @@  @@  @@  @  @@   @@   @@      @@                   
                     @@    #*  @#  @   @%  @@   @%%%%@  %@@@@@@      


    website: https://www.casinocartel.xyz/
    twitter: https://twitter.com/CasinoCartel_
    discord: https://discord.com/invite/nwpuwBWryU
    docs:    https://casino-cartel.gitbook.io/casino-cartel/
*/

contract Cartel is ERC20, Ownable {
    using SafeMath for uint256;

    ICasino public casinoManager;
    address public presaleManager;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    /// @notice dead address to burn tokens
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    /// @notice tax address, only used if auto swapping is disabled
    address public taxAddress = 0x580cB9dC536Fa441fFe812FFAD3E66D068fB305F;
    /// @notice casino address, prize pool tax is sent here
    address public prizePoolAddress = 0x1A976F22b23fD5F0f40769479bD79B02AFeD05f5;
    /// @notice pay devs for hard work
    address public devAddress = 0x1c5C455419d3c33291d41E9783ab333F15D17f81;
    /// @notice for safety, initial liquidity can only be added once
    bool public initialLiquidityAdded = false;
    /// @notice trading will be closed to prevent sniping bots
    bool private tradingOpen = false;
    /// @notice 60% before open trading to catch snipers
    uint256 public buyTax;
    /// @notice 60% before open trading to catch snipers
    uint256 public sellTax;
    /// @notice tax sharing ratio, 50% burned, 40% to casino prize pool, 10% to dev
    uint256[] public taxSharing = [50, 40, 10];
    /// @notice auto swap allow to swap tokens for eth automatically when tax is paid
    bool public swapEnabled = true;
    /// @notice used to prevent swapping when already swapping
    bool private swapping = false;
    /// @notice min balance to swap tokens for eth, 0.1% of total supply
    uint256 public swapTokensAtAmount = (totalSupply() / 1000);

    mapping(address => bool) private _isExcludedFromFees;

    event Burn(address from, uint256 value);

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    modifier onlyCasinoManager() {
        require(
            msg.sender == address(casinoManager),
            "Caller is not the casino manager"
        );
        _;
    }

    modifier onlyPresaleManager() {
        require(
            msg.sender == presaleManager,
            "Caller is not the presale manager"
        );
        _;
    }

    constructor(
        address uniV2Router,
        uint256 initialBuyTax,
        uint256 initialSellTax
    ) ERC20("Casino Cartel", "CARTEL") {
        uniswapV2Router = IUniswapV2Router02(uniV2Router);

        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        uniswapV2Router = uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        buyTax = initialBuyTax;
        sellTax = initialSellTax;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(taxAddress, true);
        excludeFromFees(prizePoolAddress, true);
        excludeFromFees(address(casinoManager), true);  
        excludeFromFees(devAddress, true); 
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0)) revert("ERC20: transfer from the zero address");
        if (to == address(0)) revert("ERC20: transfer to the zero address");
        if (amount <= 0) revert ("Transfer amount must be greater than zero");

        if (
            swapEnabled && 
            !swapping && 
            !_isExcludedFromFees[from] && 
            !_isExcludedFromFees[to] && 
            from != address(uniswapV2Pair)
        ) {
            swapAndSendToFee();
        }

        bool takeFee = !swapping;

        uint256 fees = 0;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        if (takeFee) {
            // sell
            if (to == address(uniswapV2Pair) && sellTax > 0) {
                fees = amount.mul(sellTax).div(100);
            }
            // buy
            else if (from == address(uniswapV2Pair) && buyTax > 0) {
                fees = amount.mul(buyTax).div(100);
            }

            if (fees > 0) {
                uint256 burnAmount = fees.mul(taxSharing[0]).div(100);
                super._transfer(from, deadAddress, burnAmount);
                super._transfer(from, address(this), fees - burnAmount);
            }
            amount -= fees;
        }

        /* 
            When casino manager is set, each $CARTEL tranfer will 
            check if the jackpot is available to be won. Casino manager 
            will directly transfer the jackpot to the winner 🎰
        */
        if (address(casinoManager) != address(0x0)) casinoManager.checkJackpot();
        super._transfer(from, to, amount);
    }

    function swapAndSendToFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapTokensAtAmount) {
            swapTokensForEth(contractBalance);
            uint256 ethBalance = address(this).balance;

            uint256 prizePoolShare = ethBalance.mul(taxSharing[1]).div(100);
            uint256 devShare = ethBalance.mul(taxSharing[2]).div(100);

            (bool sucess,) = prizePoolAddress.call{value: prizePoolShare}("");
            (sucess,) = devAddress.call{value: devShare}("");
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function mintInitialLiquidity(
        uint256 tokenAmount
    ) external payable onlyOwner {
        if (initialLiquidityAdded) revert("Initial liquidity already added");

        _mint(owner(), tokenAmount);

        initialLiquidityAdded = true;
    }

    function openTrading(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        if (tradingOpen) revert("Trading is already open");
        setBuyTax(_buyTax);
        setSellTax(_sellTax);
        tradingOpen = true;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setSellTax(uint256 value) public onlyOwner {
        sellTax = value;
    }

    function setBuyTax(uint256 value) public onlyOwner {
        buyTax = value;
    }

    function setSwapEnabled(bool _autoSwap) external onlyOwner {
        swapEnabled = _autoSwap;
    }

    function setPresaleManager(address _presaleManager) external onlyOwner {
        presaleManager = _presaleManager;
    }

    function setCasinoManager(address payable casino) external onlyOwner {
        casinoManager = ICasino(casino);
    }

    function setTeamWallet (address payable _newAddress) external onlyOwner {
        devAddress = _newAddress;
    }

    function setTaxAddress(address payable _newAddress) external onlyOwner {
        taxAddress = _newAddress;
    }

    function sendTokenBalanceToTaxAddress() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        _transfer(address(this), taxAddress, balance);
    }

    function setPrizePoolAddress(
        address payable _prizePool
    ) external onlyOwner {
        prizePoolAddress = _prizePool;
    }

    function mintFromCasino(
        address account,
        uint256 amount
    ) external onlyCasinoManager {
        _mint(account, amount);
    }

    function mintFromPresale(
        address to,
        uint256 amount
    ) external onlyPresaleManager {
        _mint(to, amount);
    }

}
