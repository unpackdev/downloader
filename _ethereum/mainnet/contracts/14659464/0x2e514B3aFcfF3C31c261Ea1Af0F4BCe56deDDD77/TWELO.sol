// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * Twelo
 * Made by: Rainman, what a beautiful day for some rain.
 * website: https://twelo.io
 */

// ERC20 Interface
import "./Ownable.sol";
import "./IERC20.sol";

// Utility Libraries
import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";

// Uniswap Interfaces
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

// Main contract
contract TWELO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // Setting up Token
    string private _name = "Twelo";
    string private _symbol = "TWELO";
    uint8 private _decimals = 18;

    uint256 private _totalTokenSupply = 69690690690 * 10** _decimals;
    uint256 private _totalTokensBurnt;
    uint256 private _totalTaxesSentToTreasury;

    /**
    * Mappings
    */
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromTaxes;

    // Treasury address
    address payable public _treasuryAddress;

    // Treasury tax rate
    uint256 private _currentTaxForTreasury = 6;
    uint256 public _fixedTaxForTreasury = 6;

    // Default burn rate
    uint256 private _currentBurnRate = 3;
    uint256 public _fixedBurnRate = 3;

    // Uniswap default router
    address private uniDefault = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public immutable uniswapV2Router;

    bool private _inSwap = false;

    // Uniswap Pair
    address public immutable uniswapV2Pair;

    // In swap
    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(address payable treasuryAddress, address router) {
        require((treasuryAddress != address(0)), "Give me the treasury address");

        _treasuryAddress = treasuryAddress;
        balances[msg.sender] = _totalTokenSupply;

        // connect to uniswap router
        if (router == address(0)) {
            router = uniDefault;
        }

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        // Initiating the uniswap pair
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Pair = _uniswapV2Pair;
        uniswapV2Router = _uniswapV2Router;

        // Exclude owner, treasury, and this contract from fee
        _isExcludedFromTaxes[owner()] = true;
        _isExcludedFromTaxes[address(this)] = true;
        _isExcludedFromTaxes[_treasuryAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalTokenSupply);
    }

    receive() external payable {
        return;
    }

    // Helper functions
    function setTreasuryAddress(address payable treasuryAddress) external {
        require(_msgSender() == _treasuryAddress, "You cannot call this");
        require((treasuryAddress != address(0)), "Give me the treasury address");

        address _previousTreasuryAddress = _treasuryAddress;
        _treasuryAddress = treasuryAddress;

        _isExcludedFromTaxes[treasuryAddress] = true;
        _isExcludedFromTaxes[_previousTreasuryAddress] = false;
    }


    // Exclude from taxes (Contract a& Treasury)
    function excludeFromTaxes(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromTaxes[account] = excluded;
    }

    // Set burn rate
    function setBurnRate(uint256 burnRate) external onlyOwner {
        require(burnRate >= 0 && burnRate <= 3, "ERC20: tax out of band");

        _currentBurnRate = burnRate;
        _fixedBurnRate = burnRate;
    }

    // Set treasury tax
    function setTreasuryTax(uint256 tax) external onlyOwner {
        require(tax >= 0 && tax <= 6, "ERC20: tax out of band");

        _currentTaxForTreasury = tax;
        _fixedTaxForTreasury = tax;
    }

    // Send ETH to treasury
    function sendETHToTreasury() external onlyOwner {
        uint256 _contractETHBalance = address(this).balance;

        _sendETHToTreasury(_contractETHBalance);
    }

    // Swap tokens for ETH
    function swapTokensForEth(uint256 amount) external onlyOwner {
        _swapTokensForEth(amount);
    }

    // Standard ERC20 Functions
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()]
            .sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender]
            .add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender]
            .sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalTokenSupply;
    }

    function totalTokensBurnt() public view returns (uint256) {
        return _totalTokensBurnt;
    }

    function isExcludedFromTaxes(address account) public view returns (bool) {
        return _isExcludedFromTaxes[account];
    }

    function totalTaxesSentToTreasury() public view returns (uint256) {
        return _totalTaxesSentToTreasury;
    }

    function getETHBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from 0 address");
        require(spender != address(0), "ERC20: approve to 0 address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amountOfTokens
    ) private {
        require(sender != address(0), "ERC20: transfer from 0 address");
        require(recipient != address(0), "ERC20: transfer to 0 address");
        require(amountOfTokens > 0, "ERC20: Transfer more than zero");

        bool takeFee = true;

        if (_isExcludedFromTaxes[sender] || _isExcludedFromTaxes[recipient]) {
            takeFee = false;
        }

        bool buySide = false;

        if (sender == address(uniswapV2Pair)) {
            buySide = true;
        }

        if (!takeFee) {
            _setNoFees();
        } else if (buySide) {
            _setBuySideFees();
        } else {
            _setSellSideFees();
        }

        _tokenTransfer(sender, recipient, amountOfTokens);
        _restoreAllFees();
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amountOfTokens
    ) private {
        if (sender == _treasuryAddress && recipient == address(this)) {
            _manualBurn(amountOfTokens);
            return;
        }

        (
            uint256 totalTokens,
            uint256 tokensToTransfer,
            uint256 tokensToBeBurnt,
            uint256 taxesForTreasury
        ) = _getValues(amountOfTokens);

        _takeTreasuryTax(taxesForTreasury);
        _burnTokens(tokensToBeBurnt);

        balances[sender] = balances[sender].sub(totalTokens);
        balances[recipient] = balances[recipient].add(tokensToTransfer);

        emit Transfer(sender, recipient, tokensToTransfer);
    }

    function _manualBurn(uint256 tokenCount) private {
        balances[_treasuryAddress] = balances[_treasuryAddress].sub(tokenCount);
    }

    function _takeTreasuryTax(uint256 taxesForTreasury) private {
        balances[address(this)] = balances[address(this)].add(taxesForTreasury);
        _totalTaxesSentToTreasury = _totalTaxesSentToTreasury.add(taxesForTreasury);
    }

    function _burnTokens(uint256 tokensToBurn) private {
        _totalTokensBurnt = _totalTokensBurnt.add(tokensToBurn);
        _totalTokenSupply = _totalTokenSupply.sub(tokensToBurn);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // /generate the Uniswap pair: Token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap supporting fees on transfer
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(_treasuryAddress),
            block.timestamp
        );
    }

    // Send Eth to treasury
    function _sendETHToTreasury(uint256 amount) private {
        _treasuryAddress.transfer(amount);
    }

    // Set buy side fees, we don't burn tokens on the buy side
    function _setBuySideFees() private {
        _currentTaxForTreasury = _fixedTaxForTreasury;
        _currentBurnRate = 0;
    }

    // Set sell side fees, reduce treasury tax and,
    // add percenatage of token to be burnt making the token deflationary
    function _setSellSideFees() private {
        _currentTaxForTreasury = 3;
        _currentBurnRate = _fixedBurnRate;
    }

    // Set no fees
    function _setNoFees() private {
        _currentTaxForTreasury = 0;
        _currentBurnRate = 0;
    }

    // Restore fees
    function _restoreAllFees() private {
        _currentTaxForTreasury = _fixedTaxForTreasury;
        _currentBurnRate = _fixedBurnRate;
    }

    // Split amounts based on tax percentages
    function _getValues(uint256 amountOfTokens)
        private
        view
    returns (
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        (
            uint256 tokensToTransfer,
            uint256 tokensToBeBurnt,
            uint256 tokensForTreasury
        ) = _getTokenValues(amountOfTokens);

        return (
            amountOfTokens,
            tokensToTransfer,
            tokensToBeBurnt,
            tokensForTreasury
        );
    }

    // Get token values for transactions
    function _getTokenValues(uint256 amountOfTokens)
        private
        view
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        uint256 tokensToBeBurnt;
        if (_currentBurnRate == 0) {
            tokensToBeBurnt = amountOfTokens
            .mul(_currentBurnRate);
        } else {
            tokensToBeBurnt = amountOfTokens
            .mul(_currentBurnRate)
            .div(100);
        }

        uint256 tokensForTreasury;

        if (_currentTaxForTreasury == 0) {
            tokensForTreasury = amountOfTokens
            .mul(_currentTaxForTreasury);
        } else {
            tokensForTreasury = amountOfTokens
            .mul(_currentTaxForTreasury)
            .div(100);
        }

        uint256 tokensToTransfer = amountOfTokens.sub(tokensToBeBurnt).sub(tokensForTreasury);

        return (tokensToTransfer, tokensToBeBurnt, tokensForTreasury);
    }
}