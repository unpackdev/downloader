// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

/// @title MagicAI token 
contract MagicAI is ERC20, Ownable {
    /// custom errors
    error CannotRemoveMainPair();
    error ZeroAddressNotAllowed();
    error FeesLimitExceeds();
    error UpdateBoolValue();
    error ERC20TokenClaimFailed();
    error YouReNotAFeeWallet();
    error InvalidAmount();
    error EthClaimFailed();

    /// @notice Max limit on Buy / Sell fees
    uint256 public constant MAX_FEE_LIMIT = 20;
    /// @notice max total supply 1 billion tokens (18 decimals)
    uint256 private maxSupply = 1e9 * 1e18;
    /// @notice swap threshold at which collected fees tokens are swapped for ether
    uint256 public swapTokensAtAmount = 1e3 * 1e18;
    /// @notice check if it's a swap tx
    bool private inSwap = false;

    /// fees

    /// @notice buyFees 
    uint256 public buyFee;
    /// @notice sellFees 
    uint256 public sellFee;

    /// @notice feeWallet
    address public feeWallet;
    /// @notice uniswap V2 router address
    IUniswapV2Router02 public immutable uniswapV2Router;
    /// @notice uniswap V2 Pair address
    address public uniswapV2Pair;

    /// @notice mapping to manager liquidity pairs
    mapping(address => bool) public isAutomatedMarketMaker;
    /// @notice mapping to manage excluded address from/to fees
    mapping(address => bool) public isExcludedFromFees;

    //// EVENTS ////
    event FeesUpdated(uint16 indexed buyFees, uint16 indexed sellFees);

    
    constructor() ERC20("Magic Link AI", "MAGICAI") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D /// uniswap v2 router
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        isAutomatedMarketMaker[uniswapV2Pair] = true;

        buyFee = 20;
        sellFee = 40;

        feeWallet = address(0xA5447a451336862af9Dbfd7c539210c4Df6B5c2f);

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[feeWallet] = true;
        isExcludedFromFees[owner()] = true;
        _mint(msg.sender, maxSupply);
    }

    /// modifier  ///
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /// receive external ether
    receive() external payable {}

    /// @dev owner can claim other erc20 tokens, if accidently sent by someone
    /// @param _token: token address to be rescued
    /// @param _amount: amount to rescued

    function claimStuckedERC20(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 tkn = IERC20(_token);
        bool success = tkn.transfer(owner(), _amount);
        if (!success) {
            revert ERC20TokenClaimFailed();
        }
    }

    /// @dev stucked ether from contract if sent by someone accidently
    function claimStuckedEth() external {
         if(msg.sender != feeWallet){
            revert YouReNotAFeeWallet();
        }
        uint256 ethBalance = address(this).balance;
        (bool sent,) = payable(feeWallet).call{value: ethBalance}("");
        if(!sent){
            revert EthClaimFailed();
        }
    }

    /// @dev exclude or include a user from/to fees
    /// @param user: user address
    /// @param value: boolean value. true means excluded. false means included
    /// Requirements --
    /// zero address not allowed
    /// if a user is excluded already, can't exlude him again
    function excludeFromFees(address user, bool value) external onlyOwner {
        if (user == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (isExcludedFromFees[user] == value) {
            revert UpdateBoolValue();
        }
        isExcludedFromFees[user] = value;
    }

    /// @dev add or remove new pairs
    /// @param _newPair: address to be added or removed as pair
    /// @param value: boolean value, true means blacklisted, false means unblacklisted
    /// Requirements --
    /// address should not be zero
    /// Can not remove main pair
    /// can not add already added pairs  and vice versa
    function manageLiquidityPairs(address _newPair, bool value)
        external
        onlyOwner
    {
        if (_newPair == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_newPair == uniswapV2Pair) {
            revert CannotRemoveMainPair();
        }
        if (isAutomatedMarketMaker[_newPair] == value) {
            revert UpdateBoolValue();
        }
        isAutomatedMarketMaker[_newPair] = value;
    }

    /// @dev update fee fee wallet
    /// @param _newfeeWallet: new fee wallet address
    /// Requirements -
    /// Address should not be zero
    function updatefeeWallet(address _newfeeWallet) external onlyOwner {
        if (_newfeeWallet == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        feeWallet = _newfeeWallet;
    }

    /// @dev update taxes globally
    /// @param _feeBuy: buy fees
    /// @param _feeSell: sell fees
    /// Requirements --
    /// sum of buy and sell fees must be less than equals to MAX_FEE_LIMIT (20%);
    function updateTaxes(uint16 _feeBuy, uint16 _feeSell) external onlyOwner {
        if (_feeBuy + _feeSell > MAX_FEE_LIMIT) {
            revert FeesLimitExceeds();
        }
        buyFee = _feeBuy;
        sellFee = _feeSell;

        emit FeesUpdated(_feeBuy, _feeSell);
    }

    /// @dev remove tax globally
    function removeTaxes() external onlyOwner {
        buyFee = 0;
        sellFee = 0;
    }

    /// @dev update swap threshold
    function setSwapTokenAtAmount (uint256 amount) external onlyOwner {
        if(amount > totalSupply() / 100){
            revert InvalidAmount();
        }
        swapTokensAtAmount = amount;
    }

    /// @notice manage transfers, fees
    /// see {ERC20 - _transfer}
    /// requirements --
    /// from or to should not be zero
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (to == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        uint256 contractBalance = balanceOf(address(this));
        bool canSwapped = contractBalance >= swapTokensAtAmount;
        if (
            canSwapped &&
            !isAutomatedMarketMaker[from] &&
            !inSwap &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapTokensForEth(contractBalance);
        }

        bool takeFee = true;
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }
        uint256 fees = 0;
        if (takeFee) {
            if (isAutomatedMarketMaker[from] && buyFee > 0) {
                fees = (amount * buyFee) / 100;
            }
            if (isAutomatedMarketMaker[to] && sellFee > 0) {
                fees = (amount * sellFee) / 100;
            }
            super._transfer(from, address(this), fees);
            amount = amount - fees;
        }
        super._transfer(from, to, amount);
    }
   
   /// @dev manually swap the collected tax for eth
    function manualSwap () external {
        if(msg.sender != feeWallet){
            revert YouReNotAFeeWallet();
        }
        uint256 balance = balanceOf(address(this));
        swapTokensForEth(balance);
    }

    /// @notice manages tokens conversion to eth
    /// @param tokenAmount: tokens to be converted to eth
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(
                address(this),
                address(uniswapV2Router),
                type(uint256).max
            );
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            feeWallet,
            block.timestamp
        );
    }
}
