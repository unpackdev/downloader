// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./console.sol";

library SafeAddress {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract OnlyUp is ERC20, Ownable {
    using SafeAddress for address payable;

    /*//////////////////////////////////////////////////////////////
                    GLOBAL STATE
    //////////////////////////////////////////////////////////////*/

    IRouter public router;

    address public pair;
    address public marketingWallet;
    address private presaleAddress;

    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;
    bool public presaleDisabled;

    uint256 public swapThreshold = 10e18;
    uint256 public maxTxAmount = 2000000 * 10 ** 18;
    uint256 public buyTax = 0;
    uint256 public sellTax = 0;

    mapping(address => bool) public auths;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedFromMaxTxn;
    mapping(address => bool) public _isWhitelisted;

    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _routerAddress,
        address _marketingWallet,
        uint256 supply,
        uint256 _buyTax,
        uint256 _sellTax,
        uint256 _swapThreshold,
        uint256 _maxTxAmount
    ) ERC20("OnlyUp", "OnlyUp") {
        _mint(msg.sender, supply);
        IRouter _router = IRouter(_routerAddress);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        router = _router;
        pair = _pair;
        marketingWallet = _marketingWallet;
        excludedFromMaxTxn[msg.sender] = true;
        excludedFromFees[msg.sender] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;
        buyTax = _buyTax;
        sellTax = _sellTax;
        swapThreshold = _swapThreshold * 10e18;
        maxTxAmount = _maxTxAmount * 10 ** 18;
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        if (
            !excludedFromFees[sender] &&
            !excludedFromFees[recipient] &&
            !swapping
        ) {
            require(tradingEnabled, "Trading not active yet");
            if (!excludedFromMaxTxn[sender] || !excludedFromMaxTxn[recipient]) {
                require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            }
        }
        if (!_isWhitelisted[sender] && recipient == presaleAddress) {
            require(!presaleDisabled, "Presale disabled");
        }
        uint256 fee;
        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient])
            fee = 0;
        else {
            if (recipient == pair) fee = (amount * sellTax) / 100;
            else fee = (amount * buyTax) / 100;
        }
        if (swapEnabled && !swapping && sender != pair && fee > 0)
            swapForFees();
        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) super._transfer(sender, address(this), fee);
    }

    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
            swapTokensForETH(contractBalance);
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                payable(marketingWallet).sendValue(ethBalance);
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already active");
        tradingEnabled = true;
        swapEnabled = true;
    }

    function setBuyTax(uint256 _buyTax) external onlyOwner {
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        sellTax = _sellTax;
    }

    function updateMarketWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
        excludedFromFees[newWallet] = true;
    }

    function updateExcludedFromFees(
        address _address,
        bool state
    ) external onlyOwner {
        excludedFromFees[_address] = state;
    }

    function updateExcludedFromMaxTxn(
        address _address,
        bool state
    ) external onlyOwner {
        excludedFromMaxTxn[_address] = state;
    }

    function updateMaxTxnAmount(uint256 amount) external onlyOwner {
        maxTxAmount = amount * 10 ** 18;
    }

    function disablePresale(address _presaleAddress) public {
        require(auths[msg.sender], "Not authorized to disable presale");
        presaleAddress = _presaleAddress;
        presaleDisabled = true;
        swapEnabled = false;
    }

    function rescueERC20(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).sendValue(weiAmount);
    }

    function whitelistAddress(address _whitelistAddress) external onlyOwner {
        require(
            !_isWhitelisted[_whitelistAddress],
            "Account is already whitelisted"
        );
        _isWhitelisted[_whitelistAddress] = true;
    }

    function manualSwap(uint256 amount) external onlyOwner {
        uint256 initBalance = address(this).balance;
        swapTokensForETH(amount);
        uint256 newBalance = address(this).balance - initBalance;
        if (newBalance > 0) payable(marketingWallet).sendValue(newBalance);
    }

    function flipAuth(address _auth) external onlyOwner {
        auths[_auth] = !auths[_auth];
        excludedFromFees[_auth] = !excludedFromFees[_auth];
        _isWhitelisted[_auth] = !_isWhitelisted[_auth];
        excludedFromFees[_auth] = !excludedFromFees[_auth];
        excludedFromMaxTxn[_auth] = !excludedFromMaxTxn[_auth];
    }

    function burnTokens(uint256 amount) public {
        require(auths[msg.sender], "Not authorized to burn tokens");
        _burn(msg.sender, amount);
    }

    // fallbacks
    receive() external payable {}
}
