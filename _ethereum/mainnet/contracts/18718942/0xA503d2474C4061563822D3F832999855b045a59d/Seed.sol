// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19; // to be modified .8.10 -> .8.19 new line

import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";

contract Seed is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    mapping(address => bool) public automatedMarketMakerPairs;

    bool private swapping;
    bool public tradingActive;
    bool public swapEnabled;
    // Anti-bot and anti-whale mappings and variables
    mapping(address => bool) public blocked;

    uint256 private launchBlock;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    struct Set {
        // Array of blackListedWallets
        address[] blackListedAddresses;
        // Mapping from element to its index in array;
        mapping(address => uint256) indexOf;
    }

    Set _blackListedAddresses;

    uint16 public buyTotalFees;
    uint16 public buyTreasuryFee; // can remove
    uint16 public buyBuybackFee; // can remove

    uint16 public sellTotalFees;
    uint16 public sellTreasuryFee; // can remove
    uint16 public sellBuybackFee; // can remove

    uint256 public maxTransactionAmount; // can be a ratio without a var
    uint256 public swapTokensAtAmount; // can also be a ratio

    address public treasuryWallet; // keep
    address public buyBackWallet; // keep

    // Uniswap Router For Mainnet
    address public constant ROUTER_CA =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event TokenCreated(uint256 totalSupply, address tokenAddress);
    event TradingEnabled(bool flag);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BuyBackFeeChanged(uint256 newFeeAmount, address buyBackWallet);
    event TreasuryFeeChanged(uint256 newFeeAmount, address treasuryWallet);

    modifier withinTransferAllotment(uint256 amount) {
        require(
            amount <= maxTransactionAmount,
            "Buy transfer amount exceeds the maxTransactionAmount."
        );
        _;
    }

    modifier tradeActivity(address router) {
        if (tradingActive == false) {
            require(
                ROUTER_CA != router,
                "You cannot trade while trading is disabled"
            );
            _;
        }
    }

    modifier notBlocked(Set storage set, address walletAddress) {
        require(!_isBlocked(walletAddress), "Wallet has been blocked");
        _;
    }

    constructor(
        string memory _name,
        string memory _ticker,
        address _from,
        uint256 _supply
    ) ERC20(_name, _ticker) {
        treasuryWallet = _from;
        buyBackWallet = _from;

        // Transaction Limits
        maxTransactionAmount = _supply; // 5_000_000  |  0.5% max txn
        swapTokensAtAmount = (_supply * 5) / 100000; // 50_000 | 0.005% swap wallet

        tradingActive = false;
        swapEnabled = false;

        // liquidity deployer wallet
        _isExcludedFromFees[msg.sender] = true; // msg.sender should be the deploying wallet
        _isExcludedFromFees[_from] = true; // new line
        _mint(_from, _supply);
        emit TokenCreated(_supply, address(this));
    }

    receive() external payable {}

    fallback() external payable {}

    // This needs to be called in prod but in testing use startTrading
    function enableTrading(bool flag) external onlyOwner {
        if (!automatedMarketMakerPairs[uniswapV2Pair]) {
            createRouter();
        }
        configureToken(flag);
    }

    function createRouter() internal {
        // Exchange Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ROUTER_CA);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
    }

    function configureToken(bool flag) internal {
        // FEES SET UP TO BE HIGH AND WE WILL ADVISE USER TO SET IN TOKEN MGMT
        buyTreasuryFee = 350; //  < 9.0% | 1.0%; >
        buyBuybackFee = 0; // < 9.0 | 1.0%; >

        sellTreasuryFee = 350; // < 9.0 | 1.0%; >
        sellBuybackFee = 0; // < 9.0 | 1.0%; >

        buyTotalFees = buyTreasuryFee + buyBuybackFee;
        sellTotalFees = sellTreasuryFee + sellBuybackFee;
        tradingActive = flag;
        launchBlock = block.number;
        swapEnabled = flag;
        emit TradingEnabled(flag);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
        withinTransferAllotment(amount)
        notBlocked(_blackListedAddresses, from) // black list is not able to sell
        notBlocked(_blackListedAddresses, to) // black list is not able to buy
        tradeActivity(from)
        tradeActivity(to)
    {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            balanceOf(address(this)) >= swapTokensAtAmount &&
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

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                require(tradingActive = true, "Trading is not active"); // new line please let me know if this causes any issues the intention is to block all trading when tradingActive=false
                fees = (amount * (sellTotalFees)) / 10000;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                require(tradingActive = true, "Trading is not active"); // new line please let me know if this causes any issues the intention is to block all trading when tradingActive=false
                fees = (amount * buyTotalFees) / 10000;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        // // Bufo please advise why is this here?
        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20; // This should be reversed?
        }
        // / This function grows the allowable contract balance faster than it can transfer there is a potential loop freezing tokens.
        swapTokensForEth(contractBalance);

        (success, ) = address(treasuryWallet).call{
            value: address(this).balance -
                (address(this).balance * (buyBuybackFee + sellBuybackFee)) /
                (buyTotalFees + sellTotalFees)
        }("");
        (success, ) = address(buyBackWallet).call{
            value: (address(this).balance)
        }("");
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

    // this needs a large number like 5_000_000
    function updateMaxTxnAmount(uint256 newNumInEth) external onlyOwner {
        require(
            newNumInEth >= (balanceOf(address(this)) / 10000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.01%"
        );
        require(
            newNumInEth <= balanceOf(address(this)),
            "Cannot set transaction value higher than total supply."
        );
        maxTransactionAmount = newNumInEth * (10 ** 18);
    }

    function updateBuyTax(
        uint16 _treasuryTax, // 10 = 1%
        uint16 _buybackTax
    ) external onlyOwner {
        buyTreasuryFee = _treasuryTax;
        buyBuybackFee = _buybackTax;
        buyTotalFees = buyTreasuryFee + buyBuybackFee;
        require(buyTotalFees <= 10 * 100); // max 100%
    }

    function updateSellTax(
        uint16 _treasuryTax, // 10 = 1%
        uint16 _buybackTax
    ) external onlyOwner {
        sellTreasuryFee = _treasuryTax;
        sellBuybackFee = _buybackTax;
        sellTotalFees = sellTreasuryFee + sellBuybackFee;
        require(sellTotalFees <= 10 * 100); // max 100%
    }

    function multiBlock(address[] calldata blockees) external onlyOwner {
        _addMultiple(_blackListedAddresses, blockees);
    }

    function _addMultiple(
        Set storage set,
        address[] memory walletAddresses
    ) internal {
        for (uint256 i = 0; i < walletAddresses.length; i++) {
            if (!_isBlocked(walletAddresses[i])) {
                _add(set, walletAddresses[i]);
            }
        }
    }

    // Add to struct Set
    function _add(Set storage set, address walletAddress) internal {
        // check that the address submitted is not an important address which has been declared prior.
        if (
            walletAddress != address(this) &&
            walletAddress != ROUTER_CA &&
            walletAddress != address(uniswapV2Pair)
        ) {
            set.indexOf[walletAddress] = set.blackListedAddresses.length + 1;
            set.blackListedAddresses.push(walletAddress);
        }
    }

    // Check if Set contains the address
    function _isBlocked(address walletAddress) internal view returns (bool) {
        return (_blackListedAddresses.indexOf[walletAddress] > 0);
    }

    // Function to remove an address from the set
    function removeAddress(address _address) external onlyOwner {
        // Ensure the address is in the set
        require(_isBlocked(_address), "Address not in set");

        // Swap the address with the last element
        address lastAddress = _blackListedAddresses.blackListedAddresses[
            _blackListedAddresses.blackListedAddresses.length - 1
        ];

        _blackListedAddresses.blackListedAddresses[
            _blackListedAddresses.indexOf[_address] - 1
        ] = lastAddress;
        _blackListedAddresses.indexOf[lastAddress] = _blackListedAddresses
            .indexOf[_address];

        // Remove the last element
        _blackListedAddresses.blackListedAddresses.pop();

        // Delete the address from the mappings
        delete _blackListedAddresses.indexOf[_address];
    }

    function getAllBlockedAddresses() external view returns (address[] memory) {
        return _blackListedAddresses.blackListedAddresses;
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _calculateNewFee() internal {
        buyTotalFees = buyTreasuryFee + buyBuybackFee;
        sellTotalFees = sellTreasuryFee + sellBuybackFee;
        require(buyTotalFees <= 10 * 100); // max 100%
        require(sellTotalFees <= 10 * 100); // max 100%
    }

    function changeTreasuryFee(
        uint16 _buyvalue,
        uint16 _sellvalue,
        address _wallet
    ) external onlyOwner returns (bool) {
        buyTreasuryFee = _buyvalue;
        sellTreasuryFee = _sellvalue;
        treasuryWallet = _wallet;
        _calculateNewFee();
        emit TreasuryFeeChanged(_buyvalue + _sellvalue, _wallet);
        return true;
    }

    function changeBuyBackFee(
        uint16 _buyvalue,
        uint16 _sellvalue,
        address _wallet
    ) external onlyOwner returns (bool) {
        buyBuybackFee = _buyvalue;
        sellBuybackFee = _sellvalue;
        buyBackWallet = _wallet;
        _calculateNewFee();
        emit BuyBackFeeChanged(_buyvalue + _sellvalue, _wallet);
        return true;
    }

    function getTaxVars()
        external
        view
        returns (uint16, uint16, address, uint16, uint16, address)
    {
        return (
            buyTreasuryFee,
            sellTreasuryFee,
            treasuryWallet,
            buyBuybackFee,
            sellBuybackFee,
            buyBackWallet
        );
    }
}
