// SPDX-License-Identifier: MIT

// Please visit https://playfi.studio for more info
pragma solidity 0.8.21;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/// @title PlayFi Token Contract
/// @notice Upgradeable ERC20 with 2% fee taken on sells
/// @author Evi Nova (Tranquil Flow)
contract PlayFi is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    IDEXRouter public router;
    address public pair;
    address payable public feeReceiver;
    mapping (address => bool) public isFeeExempt;
    bool public tradingEnabled;
    bool public swapEnabled;
    bool public inSwap;
    uint public sellFee;
    uint public buyFee;
    uint public totalFeesGenerated;
    uint public swapMinimum;
    uint public swapMaximum;

    modifier swapping() { 
        inSwap = true; _; inSwap = false;
    }

    event FeeExemptSet(address indexed wallet, bool isExempt);
    event SwapSettingsSet(uint minimum, uint maximum, bool enabled);
    event FeeValuesSet(uint newSellFee, uint newBuyFee);

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    /// @dev Initializes the contract, should be called immediately after deployment
    function initialize() initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ERC20_init("PlayFi", "PLAYFI");
        _mint(msg.sender, 12_000_000 ether);   // 12,000,000 PLAYFI tokens

        // Initialize Variables
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap on Ethereum
        sellFee = 50;    // 5.0%
        buyFee = 50;     // 5.0%
        swapMaximum = totalSupply() / 400; //0.25%     30,000 tokens
        swapMinimum = totalSupply() / 10000; //0.01%     1,200 tokens
        swapEnabled = true;
        feeReceiver = payable(0x78c29C6C95cF3F582C557B5849fca4CF9eECaC51);

        isFeeExempt[address(this)] = true;
        isFeeExempt[owner()] = true;
        isFeeExempt[feeReceiver] = true;

        _approve(address(this), address(router), type(uint256).max); // Approve the router to spend tokens
        pair = IDEXFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
    }

    /// @notice Transfer function that takes a fee on sells and buys
    /// @param sender The address sending tokens
    /// @param recipient The address receiving tokens
    /// @param amount The amount of tokens being transferred
    function _update(address sender, address recipient, uint amount) internal override {
        require(tradingEnabled == true || msg.sender == owner() || sender == address(this), "Trading not enabled");
        uint transferAmount = amount;

        // If it is a sell, take the sellFee
        if(pair == recipient && !isFeeExempt[sender]) {
            uint feeAmount = (amount * sellFee) / 1000;
            super._update(sender, address(this), feeAmount);
            transferAmount -= feeAmount;

            // If conditions met, tokens on contract are sold for ETH
            if (shouldSwapBack()) {
                swapBack();
            }
        }

        // If it is a buy, take the buyFee
        if(pair == sender && !isFeeExempt[sender]) {
            uint feeAmount = (amount * buyFee) / 1000;
            super._update(sender, address(this), feeAmount);
            transferAmount -= feeAmount;
        }

        // Transfer tokens
        super._update(sender, recipient, transferAmount);
    }

    /// @notice Determines if a swap back of tokens on the contract should occur
    /// @dev Checks that a swap is not currently occuring to prevent reentrancy
    /// @dev Checks that swapEnabled is true
    /// @dev Checks that the amount of tokens on the contract is greater than swapMinimum
    function shouldSwapBack() internal view returns (bool) {
        return
        !inSwap &&
        swapEnabled &&
        balanceOf(address(this)) > swapMinimum;
    }

    /// @notice Swaps tokens held on the contract (fees) for ETH and transfers to feeReceiver
    function swapBack() internal swapping {
        uint swapAmount;
        uint contractBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // If contract is holding more tokens than swapMaximum, only sell swapMaximum amount
        if (contractBalance > swapMaximum) {
            swapAmount = swapMaximum;
        } else {
            swapAmount = contractBalance;
        }

        // Swap tokens for ETH
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            path[0],
            block.timestamp + 20
        );

        // Record the fees generated from the swap
        uint feesGenerated = address(this).balance;
        totalFeesGenerated += feesGenerated;

        // Transfer the fees to feeReceiver
        bool success;
        (success, ) = address(feeReceiver).call{
            value: feesGenerated
        }("");

    }

    /// @notice Launches the token to begin trading
    /// @dev The msg.value is the amount of ETH to use for liquidity 
    /// @param tokenAmount The amount of PLAYFI tokens to use for liquidity
    function launch(uint tokenAmount) external payable onlyOwner {
        require(tradingEnabled == false, "Trading already enabled");
        super._update(msg.sender, address(this), tokenAmount);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        tradingEnabled = true;
    }

    /// @dev Changes an address to be registered as exempt from fees or not
    /// @param holder The address to change fee exemption status
    /// @param exempt False = Pays fees, True = Exempt from fees
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isFeeExempt[holder] = exempt;
        emit FeeExemptSet(holder, exempt);
    }

    /// @dev Changes the settings around swapBack()
    /// @param _swapMinimum The minimum amount of tokens a contract must hold before swapBack() executes
    /// @param _swapMaximum The maximum amount of tokens that will be swapped in swapBack()
    /// @param _enabled False = No swapBack(), True = swapBack() executes
    function setSwapBackSettings(uint _swapMinimum, uint _swapMaximum, bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        swapMinimum = _swapMinimum;
        swapMaximum = _swapMaximum;
        emit SwapSettingsSet(swapMinimum, swapMaximum, swapEnabled);
    }

    /// @dev Changes the fee percent on buys and sells
    /// @dev Value of 1 = 0.1% fee, value of 10 = 1% fee
    /// @param _sellFee The % fee to take on all sells
    /// @param _buyFee The % fee to take on all buys
    function setFeeSettings(uint _sellFee, uint _buyFee) external onlyOwner {
        require(_sellFee <= 100 && _buyFee <= 100, "Max fee is 10 percent");
        sellFee = _sellFee;
        buyFee = _buyFee;
        emit FeeValuesSet(sellFee, buyFee);
    }

    receive() external payable {}
}