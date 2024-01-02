// SPDX-License-Identifier: MIT  

//Telegram - https://t.me/BradPortal  
//Twitter - https://twitter.com/Bradcoin_
//Website - https://bradcoin.wtf/  

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BG5YYJJJJJJJJJYYY55PPGB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@&#G5J??77!!~~~~~~~~~~~!!!77?JJY555PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@&B5J?77!~~~~~~~~~~~~~~~~~~~~~~~~~!7JPY7??JYYPG#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@BY??7!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!~~~~!!77?JY5G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@BY??!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!77?J5G#@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@#YJ?!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7??YG&@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@P7J!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7?JP&@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@Y??~~~~~~~~~~~~~~~~~~~~~~~~~!7?J!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7JJP@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@?J?~~~~~7??YJ~!7?J5~~~~~~!7??7!:YJ~~~~~!YY?~~~~~~~~~~~~7?!~~~~~~~~~~~7J?B@@@@@@@@@@@@@@@@
//@@@@@@@@@B?J7~!7???!^^GY??~:.57~!?J?7~:.   ?Y~~~!JJ^.~J?7~~~~~~!?J7!5?~~~~~~~~~~~!J?P@@@@@@@@@@@@@@@
//@@@@@@@#J?BP??7~^.   :7:.    !P?7~:        .P7~JJ~     :7J?7!!JJ~.  .?Y!~~~~~~~~~~~YJ5@@@@@@@@@@@@@@
//@@@@@@57JPP^.                 .             :5J~          :!77^       ^JJ7!!!!!!7?J?5J5@@@@@@@@@@@@@
//@@@@@@BGYJ~                 .~!!7!^                     ^~~~^.          :!!!!~~~!~.  P?G@@@@@@@@@@@@
//@@@@@@@@YY:               ^J5!^^^~5:                   ~G?!~7Y?.                     ^B7&@@@@@@@@@@@
//@@@@@@@@JY              ^?7^7P!~!!P^                 .??^^~~~~7Y:                     !YY@@@@@@@@@@@
//@@@@@@@@5J!^~^        ^55!:.!5.  ^5.                 5~  :GG.  :5.                     Y?@@@@@@@@@@@
//@@@@@@@@#!5?#?       :P:.^~777!~7?:                 .G!!~75Y^:..P.                     Y?@@@@@@@@@@@
//@@@@@@@@@G!B&B~.      77~^~!77!:    :^J7 .  .   7.  .Y!^::::^~!PJ                   .!PYY@@@@@@@@@@@
//@@@@@@@@@@G7P&&BY?     .:::.^! ^!!!YY#@BP#P5BGPP@BB?.~77!!~^^!?!                   :Y@@7B@@@@@@@@@@@
//@@@@@@@@@@@#JYGBPG57:       P#P&@G!7 ~?.^J?!^~~7PYYP?5@J .::::            : .^ ^J??5#@B?G@@@@@@@@@@@
//@@@@@@@@@@@@@G7J&&#@GGP! ~5P##@&5.~!7!!!~^^^~~~~!:   J##G?.             .^PYY#JP!Y#@BJJB@@@@@@@@@@@@
//@@@@@@@@@@@@@@@PJY!Y&@@@G5#@#J7P     ..:::::::::.      !#@#P7:.       .!5J#P&#&&&PYGY5@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@GJ?JP@#&&&@&GY?                         Y&@#B#G?. !~~B&#Y&P5J?GY5#G#@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@#5JY?5&&B&@JJ!.   !77!^        :J7:~^JB&@@@@#&#G#P&@GJ5YYPPPG#@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@#PYJY#@@##BBYYYPPBGPP?5^PY~^B&#B@#@@B5&#BP&@Y5PP57B@&@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@#PY55?PB#P##@@@5JB@@&@#@@&G#@BG#5YYJY5JYYY&#BB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#GGPPP55PPPGGPYGY5BGP55Y55JB###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&GP#BBBB###&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";

contract BRAD is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public tradingStartTimeStamp;
    uint256 public maxHoldingAmount;
    uint256 public maxTransactionAmount;
    uint256 private swapTokensAt;

    address public deployerWallet;
    address public marketingWallet;
    address public uniswapV2Pair;

    bool public limited;
    bool public swapEnabled;
    bool private swapping;
    

    mapping (address => bool) private _ExcludedFromFees;
    mapping (address => bool) private _ExcludedFromTransactionAmount;

    error CanOnlySetPairOnce(address);
    error InvalidPresalePrice(uint256);
    error ExceedsHoldingAmount(uint256);
    error ExceedsMaxTransactionAmount(uint256);
    error TradingHasNotStarted();
    error WithdrawFailed();

    constructor(
        uint256 _totalSupply, 
        address _marketingWallet
    ) ERC20("Brad Coin", "BRAD") {

        _mint(msg.sender, _totalSupply);

        swapTokensAt = (_totalSupply * 9) / 10_000;

        swapEnabled = true;

        deployerWallet = msg.sender;

        marketingWallet = _marketingWallet;


        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(address(this), true);
    }

    receive() external payable {}

    function commenceTrading(address _uniswapV2Pair) external onlyOwner {

        if (tradingStartTimeStamp != 0) revert CanOnlySetPairOnce(uniswapV2Pair);

        uniswapV2Pair = _uniswapV2Pair;
        tradingStartTimeStamp = block.timestamp;
    }

    function setLimits(
        bool _limited, 
        uint256 _maxHoldingAmount,
        uint256 _maxTransactionAmount
    ) external onlyOwner {
        limited = _limited;
        maxTransactionAmount = _maxTransactionAmount;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function toggleSwapping(bool _bool) external onlyOwner {
        swapEnabled = _bool;
    }

    function excludeFromFees(address _account, bool _excluded) public onlyOwner {
        _ExcludedFromFees[_account] = _excluded;
    }

    function excludeFromMaxTransaction(address _account, bool _excluded) public onlyOwner {
        _ExcludedFromTransactionAmount[_account] = _excluded;
    }

    function withdrawFunds(address payable _address) external onlyOwner {
        (bool success, ) = _address.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawTokens(address payable _address, address _tokenContract) external onlyOwner {
        uint256 balanceInContract = IERC20(_tokenContract).balanceOf(address(this));
        _transfer(address(this), _address, balanceInContract);
    }


    function _getTaxes(
        uint256 _currentTimestamp
    ) internal view returns (uint256 _buyTax, uint256 _sellTax, bool _eligibleForTax) {
        uint256 elapsedTime = _currentTimestamp - tradingStartTimeStamp;
        uint256 buyTax = 0;
        uint256 sellTax = 0;
        bool eligibleForTax = true;
        if (elapsedTime < 1 minutes) {
            buyTax = 0;
            sellTax = 0;
            eligibleForTax = true;
        } else if (elapsedTime >= 1 minutes && elapsedTime < 3 minutes) {
            buyTax = 0;
            sellTax = 0;
            eligibleForTax = true;
        } 

        return (buyTax, sellTax, eligibleForTax);
    }

    function _transfer(
        address from, 
        address to, 
        uint256 amount
    ) internal override {
        if (uniswapV2Pair == address(0) && from != address(0) && from != owner()) revert TradingHasNotStarted();

        if(
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping
        )
            {
                if (limited) {
                    if (from == uniswapV2Pair && !_ExcludedFromTransactionAmount[to]) {
                        if (amount > maxTransactionAmount) revert ExceedsMaxTransactionAmount(amount);
                        if (balanceOf(to) + amount > maxHoldingAmount) revert ExceedsHoldingAmount(amount);
                    }
                    else if (to == uniswapV2Pair && !_ExcludedFromTransactionAmount[from]) {
                        if (amount > maxTransactionAmount) revert ExceedsMaxTransactionAmount(amount);
                    }
                    else if (!_ExcludedFromTransactionAmount[to]) {
                        if (balanceOf(to) + amount > maxHoldingAmount) revert ExceedsHoldingAmount(amount);
                    }
                }
            }
        
        uint256 contractBalance = balanceOf(address(this));

        
        bool canSwap = contractBalance >= swapTokensAt;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            from != uniswapV2Pair &&
            !_ExcludedFromFees[from] &&
            !_ExcludedFromFees[to]
        ) {
            swapping = true;
            
            _swapBack(contractBalance);

            swapping = false;
        }

        bool takeFee = !swapping;

        
        if(_ExcludedFromFees[from] || _ExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            (uint256 buyTax, uint256 sellTax, bool eligibleForTax) = _getTaxes(block.timestamp);
            if (from == uniswapV2Pair && eligibleForTax) {
                uint256 tax = (amount * buyTax) / 100;
                super._transfer(from, address(this), tax);
                amount -= tax;
            }

            if (to == uniswapV2Pair && eligibleForTax) {
                uint256 tax = (amount * sellTax) / 100;
                super._transfer(from, address(this), tax);
                amount -= tax;
            }
        }
        super._transfer(from, to, amount);
    }

    function _swapBack(uint256 _contractBalance) private {
        if (_contractBalance == 0) { return; }

        // Swap tokens for ETH
        _swapTokensForEth(_contractBalance); 

        uint256 totalEth = address(this).balance;

        // Send ETH to marketing wallet
        (bool success,) = address(marketingWallet).call{value: totalEth}("");
    }


    function _swapTokensForEth(uint256 _tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
}