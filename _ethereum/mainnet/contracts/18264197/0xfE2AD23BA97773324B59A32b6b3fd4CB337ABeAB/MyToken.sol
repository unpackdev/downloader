// SPDX-License-Identifier: MIT                        

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";

contract MyToken is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public tradingStartTimeStamp;
    uint256 public maxHoldingAmount;
    uint256 public maxTransactionAmount;
    uint256 private swapTokensAt;
    uint256 public buyTax = 5;
    uint256 public sellTax = 5;

    address public deployerWallet;
    address public marketingWallet;
    address public bankWallet;
    address public uniswapV2Pair;

    bool public limited;
    bool public swapEnabled;
    bool private swapping;
    
    uint256 public transferDelay = 0 seconds; // Added delay for transactions
    mapping (address => uint256) private lastTransferTimestamp; // Added mapping to keep track of last transfer time per address

    mapping (address => bool) private _ExcludedFromFees;
    mapping (address => bool) private _ExcludedFromTransactionAmount;
    mapping (address => bool) private _blacklisted;

    error CanOnlySetPairOnce(address);
    error InvalidPresalePrice(uint256);
    error ExceedsHoldingAmount(uint256);
    error ExceedsMaxTransactionAmount(uint256);
    error TradingHasNotStarted();
    error WithdrawFailed();
    error TransferTooSoon(); // Added error for transfer delay

    constructor(
        uint256 _totalSupply, 
        address _marketingWallet,
        address _bankWallet
    ) ERC20("Elysion", "ELY") {

        _mint(msg.sender, _totalSupply);

        swapTokensAt = (_totalSupply * 1) / 10000;

        swapEnabled = true;

        deployerWallet = msg.sender;

        marketingWallet = _marketingWallet;

        bankWallet = _bankWallet;

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(bankWallet, true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(bankWallet, true);
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
        IERC20(_tokenContract).transfer(_address, balanceInContract);
    }


   function _getTaxes(
        uint256 _currentTimestamp
    ) internal view returns (uint256 _buyTax, uint256 _sellTax, bool _eligibleForTax) {
        uint256 elapsedTime = _currentTimestamp - tradingStartTimeStamp;
        bool eligibleForTax = true;
        if (elapsedTime < 2 minutes) {
            _buyTax = 30;
            _sellTax = 30;
            eligibleForTax = true;
        } else if (elapsedTime >= 2 minutes && elapsedTime < 5 minutes) {
            _buyTax = 10;
            _sellTax = 10;
            eligibleForTax = true;
        } else {
            _buyTax = buyTax;
            _sellTax = sellTax;
        }

        return (_buyTax, _sellTax, eligibleForTax);
    }

    function setBuyTax(uint256 _buyTax) external onlyOwner {
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        sellTax = _sellTax;
    }

    function blacklistAddresses(address[] calldata accounts, bool value) external onlyOwner {
        for (uint i=0; i<accounts.length; i++) {
            _blacklisted[accounts[i]] = value;
        }
    }

    function isBlacklisted(address account) public view returns(bool) {
        return _blacklisted[account];
    }

    function _transfer(
        address from, 
        address to, 
        uint256 amount
    ) internal override {
        require(!_blacklisted[from], "Address is blacklisted");
        require(!_blacklisted[to], "Address is blacklisted");

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
                // Added delay check
                if (from != uniswapV2Pair && to != uniswapV2Pair) {
                    if (block.timestamp - lastTransferTimestamp[from] < transferDelay) revert TransferTooSoon();
                    lastTransferTimestamp[from] = block.timestamp;
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
            (uint256 buyTaxResult, uint256 sellTaxResult, bool eligibleForTax) = _getTaxes(block.timestamp);
            if (from == uniswapV2Pair && eligibleForTax) {
                uint256 tax = (amount * buyTaxResult) / 100;
                super._transfer(from, address(this), tax);
                amount -= tax;
            }

            if (to == uniswapV2Pair && eligibleForTax) {
                uint256 tax = (amount * sellTaxResult) / 100;
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
        uint256 halfEth = totalEth / 2;

        // Send 50% of ETH to bank wallet
        (bool successBank,) = address(bankWallet).call{value: halfEth}("");
        require(successBank, "Transfer to bank wallet failed");

        // Send 50% of ETH to marketing wallet
        (bool successMarketing,) = address(marketingWallet).call{value: halfEth}("");
        require(successMarketing, "Transfer to marketing wallet failed");
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

    function setTransferDelay(uint256 newDelay) public onlyOwner {
        transferDelay = newDelay;
    }
}