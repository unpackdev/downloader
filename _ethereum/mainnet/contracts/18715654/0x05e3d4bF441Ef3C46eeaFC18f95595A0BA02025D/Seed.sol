// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19; // to be modified .8.10 -> .8.19 new line

import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";

// import "./AccessControl.sol";

contract Seed is ERC20, Ownable {
    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_DEFAULT");
    // bytes32 public constant TOKEN_FACTORY = keccak256("TOKEN_FACTORY");
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    mapping(address => bool) public automatedMarketMakerPairs;

    bool private swapping = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => bool) public blocked;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    uint256 private launchBlock;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    struct Set {
        // new line suggested from auditor
        // Array of blackListedWallets
        address[] blackListedAddresses;
        // Mapping from element to its index in array;
        mapping(address => uint256) indexOf;
        // Mapping to track the existence of an element
        mapping(address => bool) inserted;
    }

    Set _blackListedAddresses;

    uint256 public buyTotalFees;
    uint256 public buyTreasuryFee;
    uint256 public buyBuybackFee;

    uint256 public sellTotalFees;
    uint256 public sellTreasuryFee;
    uint256 public sellBuybackFee;

    uint256 public constant FEE_FACTOR = 10; // Factor of 10.
    uint256 private constant _MAX_SWAP_FACTOR = 100000;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;

    address public treasuryWallet;
    address public buyBackWallet;

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

    modifier notBlocked(Set storage set, address walletAddress) {
        require(!_isBlocked(set, walletAddress), "Wallet has been blocked");
        _;
    }

    constructor(
        string memory _name,
        string memory _ticker,
        address _from,
        uint256 _supply
    ) ERC20(_name, _ticker) {
        // _grantRole(ADMIN_ROLE, _from);
        // _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        // Bonsai3 proxy rights to change address
        // _grantRole(TOKEN_FACTORY, msg.sender); // IS THERE ANY RISK CREATING THIS ROLE, SHOULD I ONLY GIVE A ROLE TO THE SALE OWNER?
        // Exchange Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ROUTER_CA);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        treasuryWallet = _from;
        buyBackWallet = _from;

        // FEES SET UP TO BE HIGH AND WE WILL ADVISE USER TO SET IN TOKEN MGMT
        buyTreasuryFee = 350; //  < 9.0% | 1.0%; >
        buyBuybackFee = 0; // < 9.0 | 1.0%; >

        sellTreasuryFee = 350; // < 9.0 | 1.0%; >
        sellBuybackFee = 0; // < 9.0 | 1.0%; >

        buyTotalFees = buyTreasuryFee + buyBuybackFee;
        sellTotalFees = sellTreasuryFee + sellBuybackFee;

        // Transaction Limits
        maxTransactionAmount = _supply; // 5_000_000  |  0.5% max txn
        swapTokensAtAmount = (_supply * 5) / _MAX_SWAP_FACTOR; // 50_000 | 0.005% swap wallet

        // liquidity deployer wallet
        // _isExcludedFromFees[msg.sender] = true; msg.sender should be the deploying wallet
        _isExcludedFromFees[_from] = true; // new line
        _mint(_from, _supply);
        emit TokenCreated(_supply, address(this));
    }

    receive() external payable {}

    fallback() external payable {}

    function enableTrading(bool flag) external onlyOwner {
        // require(!tradingActive, "Token launched"); // new line this has been removed so the owner can toggle on and off
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
        notBlocked(_blackListedAddresses, from)
    {
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
                fees = (amount * (sellTotalFees)) / FEE_FACTOR / 100;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                require(tradingActive = true, "Trading is not active"); // new line please let me know if this causes any issues the intention is to block all trading when tradingActive=false
                fees = (amount * buyTotalFees) / FEE_FACTOR / 100;
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

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        uint256 ethBalance = address(this).balance;

        uint256 ethForBuyBack = (ethBalance *
            (buyBuybackFee + sellBuybackFee)) / (buyTotalFees + sellTotalFees);

        uint256 ethForTreasury = ethBalance - ethForBuyBack;

        (success, ) = address(treasuryWallet).call{value: ethForTreasury}("");
        (success, ) = address(buyBackWallet).call{value: ethForBuyBack}("");
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
        maxTransactionAmount = newNumInEth * (10 ** 18);
    }

    function updateBuyTax(
        uint256 _treasuryTax, // 10 = 1%
        uint256 _buybackTax
    ) external onlyOwner {
        buyTreasuryFee = _treasuryTax;
        buyBuybackFee = _buybackTax;
        buyTotalFees = buyTreasuryFee + buyBuybackFee;
        require(buyTotalFees <= 10 * FEE_FACTOR); // max 10%
    }

    function updateSellTax(
        uint256 _treasuryTax, // 10 = 1%
        uint256 _buybackTax
    ) external onlyOwner {
        sellTreasuryFee = _treasuryTax;
        sellBuybackFee = _buybackTax;
        sellTotalFees = sellTreasuryFee + sellBuybackFee;
        require(sellTotalFees <= 10 * FEE_FACTOR); // max 10%
    }

    function multiBlock(address[] calldata blockees) external onlyOwner {
        _addMultiple(_blackListedAddresses, blockees);
    }

    function _addMultiple(
        Set storage set,
        address[] memory walletAddresses
    ) internal {
        for (uint256 i = 0; i < walletAddresses.length; i++) {
            if (!_isBlocked(set, walletAddresses[i])) {
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
            set.inserted[walletAddress] = true;
            set.indexOf[walletAddress] = set.blackListedAddresses.length;
            set.blackListedAddresses.push(walletAddress);
        }
    }

    // Check if Set contains the address
    function _isBlocked(
        Set storage set,
        address walletAddress
    ) internal view returns (bool) {
        return set.inserted[walletAddress];
    }

    // Function to remove an address from the set
    function removeAddress(address _address) external onlyOwner {
        // Ensure the address is in the set
        require(_blackListedAddresses.inserted[_address], "Address not in set");

        // Swap the address with the last element
        uint256 index = _blackListedAddresses.indexOf[_address];
        uint256 lastIndex = _blackListedAddresses.blackListedAddresses.length -
            1;
        address lastAddress = _blackListedAddresses.blackListedAddresses[
            lastIndex
        ];

        _blackListedAddresses.blackListedAddresses[index] = lastAddress;
        _blackListedAddresses.indexOf[lastAddress] = index;

        // Remove the last element
        _blackListedAddresses.blackListedAddresses.pop();

        // Delete the address from the mappings
        delete _blackListedAddresses.indexOf[_address];
        delete _blackListedAddresses.inserted[_address];
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
        require(buyTotalFees <= 10 * FEE_FACTOR); // max 10%
        require(sellTotalFees <= 10 * FEE_FACTOR); // max 10%
    }

    function changeTreasuryFee(
        uint256 _buyvalue,
        uint256 _sellvalue,
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
        uint256 _buyvalue,
        uint256 _sellvalue,
        address _wallet
    ) external onlyOwner returns (bool) {
        buyBuybackFee = _buyvalue;
        sellBuybackFee = _sellvalue;
        buyBackWallet = _wallet;
        _calculateNewFee();
        emit BuyBackFeeChanged(_buyvalue + _sellvalue, _wallet);
        return true;
    }
}
