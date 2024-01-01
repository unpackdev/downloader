// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*
            ██████                                                                                  
           ████████         █████████     ██████████     ███  ████         ███                      
            ██████        █████████████ ██████████████   ████ ██████      ████                      
              ██        ████████  ████ ██████    ██████  ████ ███████     ████                      
              ██       █████          █████        █████ ████ █████████   ████                      
              ██       █████          ████         █████ ████ ████ ██████ ████                      
             ████      █████          ████         █████ ████ ████  ██████████                      
            █████       █████         █████        █████ ████ ████    ████████                      
           ████████      █████████████ ████████████████  ████ ████     ███████                      
          ████  ████      █████████████  ████████████    ████ ████       █████                      
        █████    █████        █████          ████                                                   
      ██████      ██████                                                                            
    ██████         ███████                                                                          
  ████████          ████████           ███████████  █████████████████        ████  ████ ████████████
 ████████           █████████        █████████████  ███████████████████      ████ █████ ████████████
█████████           ██████████     ███████          █████        ████████    ████ █████ ████        
██████████         ████████████    █████            █████        █████████   ████ █████ ████        
██████████████   ██████████████    █████   ████████ ████████████ ████ ██████ ████ █████ ███████████ 
███████████████████████████████    █████   ████████ ██████████   ████  ██████████ █████ ██████████  
███████████████████████████████    ██████      ████ █████        ████    ████████ █████ ████        
 █████████████████████████████      ███████████████ ████████████ ████      ██████ █████ ████████████
  ██████████████████████████          █████████████ █████████████████       █████ █████ ████████████
 */

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";

import "./ICoinGenieERC20.sol";

/**
 * @title CoinGenieERC20
 * @author @neuro_0x
 * @notice A robust and secure ERC20 token for the Coin Genie ecosystem. Inspired by APEX & TokenTool by Bitbond
 * @dev This ERC20 should only be deployed via the launchToken function of the CoinGenie contract.
 */
contract CoinGenieERC20 is ICoinGenieERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ICoinGenieERC20;

    /// @dev The fee recipients for the contract
    struct FeeTakers {
        address payable feeRecipient;
        address payable coinGenie;
        address payable affiliateFeeRecipient;
    }

    /// @dev The fee percentages for the contract
    struct FeePercentages {
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
        uint256 discountFeeRequiredAmount;
        uint256 discountPercent;
        uint256 coinGenieFeePercent;
    }

    /// @dev The decimals for the contract
    uint8 private constant _DECIMALS = 18;
    /// @dev The max basis points
    uint256 private constant _MAX_BPS = 10_000;
    /// @dev The max tax that can be set
    uint256 private constant _MAX_TAX = 500; // 5%
    /// @dev The min amount of eth required to open trading
    uint256 private constant _MIN_LIQUIDITY_ETH = 0.5 ether;
    /// @dev The min amount of this token required to open trading
    uint256 private constant _MIN_LIQUIDITY_TOKEN = 1 ether;
    /// @dev The platform liquidity addition fee
    uint256 private constant _LP_ETH_FEE_PERCENTAGE = 100; // 1%
    /// @dev The platform liquidity addition fee
    uint256 private constant _MIN_WALLET_PERCENT = 100; // 1%
    /// @dev The eth autoswap amount
    uint256 private constant _ETH_AUTOSWAP_AMOUNT = 0.025 ether;

    /// @dev The address of the Uniswap V2 Router
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /// @dev Mapping of holders and their balances
    mapping(address holder => uint256 balance) private _balances;
    /// @dev Mapping of holders and their allowances
    mapping(address holder => mapping(address spender => uint256 allowance)) private _allowances;
    /// @dev Mapping of holders and their whitelist status
    mapping(address holder => bool isWhiteListed) private _whitelist;
    /// @dev Mapping of fee recipients and the amount of eth they have received
    mapping(address feeRecipient => uint256 amountEthReceived) private _ethReceived;

    /// @dev The fee recipients for the contract
    FeeTakers private _feeTakers;
    /// @dev The fee percentages for the contract
    FeePercentages private _feeAmounts;

    /// @dev The $GENIE contract
    CoinGenieERC20 private _genie;

    /// @dev The address of the Uniswap V2 Pair
    address private _uniswapV2Pair;

    /// @dev The coin genie fee is set
    bool private _isFeeSet;
    /// @dev The trading status of the contract
    bool private _isTradingOpen;
    /// @dev The current swap status of the contract, used for reentrancy checks
    bool private _inSwap;
    /// @dev The swap status of the contract
    bool private _isSwapEnabled;

    /// @dev The name of the token
    string private _name;
    /// @dev The symbol of the token
    string private _symbol;
    /// @dev The total supply of the token
    uint256 private _totalSupply;

    /// @dev Prevents a reentrant call when trying to swap fees
    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /// @param name_ - the name of the token
    /// @param symbol_ - the ticker symbol of the token
    /// @param totalSupply_ - the totalSupply of the token
    /// @param feeRecipient_ - the address that will be the owner of the token and receive fees
    /// @param coinGenie_ - the address of the Coin Genie
    /// @param affiliateFeeRecipient_ - the address to receive the affiliate fee
    /// @param taxPercent_ - the percent in basis points to use as a tax
    /// @param maxBuyPercent_ - amount of tokens allowed to be transferred in one tx as a percent of the total supply
    /// @param maxWalletPercent_ - amount of tokens allowed to be held in one wallet as a percent of the total supply
    /// @param discountFeeRequiredAmount_ - the amount of tokens required to pay the discount fee
    /// @param discountPercent_ - the percent in basis points to use as a discount
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address payable feeRecipient_,
        address payable coinGenie_,
        address payable affiliateFeeRecipient_,
        uint256 taxPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 discountFeeRequiredAmount_,
        uint256 discountPercent_
    )
        payable
    {
        _setERC20Properties(name_, symbol_, totalSupply_);
        _setFeeRecipients(feeRecipient_, coinGenie_, affiliateFeeRecipient_);
        _setFeePercentages(taxPercent_, maxBuyPercent_, maxWalletPercent_, discountFeeRequiredAmount_, discountPercent_);
        _setWhitelist(feeRecipient_, coinGenie_, affiliateFeeRecipient_);

        _balances[feeRecipient_] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    /////////////////////////////////////////////////////////////////
    //                     Public/External                         //
    /////////////////////////////////////////////////////////////////

    // solhint-disable-next-line no-empty-blocks
    receive() external payable { }

    /// @dev see ICoinGenieERC20 name()
    function name() public view returns (string memory) {
        return string(abi.encodePacked(_name));
    }

    /// @dev see ICoinGenieERC20 symbol()
    function symbol() public view returns (string memory) {
        return string(abi.encodePacked(_symbol));
    }

    /// @dev see ICoinGenieERC20 decimals()
    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    /// @dev see ICoinGenieERC20 totalSupply()
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev see ICoinGenieERC20 feeRecipient()
    function feeRecipient() public view returns (address payable) {
        return _feeTakers.feeRecipient;
    }

    /// @dev see ICoinGenieERC20 affiliateFeeRecipient()
    function affiliateFeeRecipient() public view returns (address payable) {
        return _feeTakers.affiliateFeeRecipient;
    }

    /// @dev see ICoinGenieERC20 coinGenie()
    function coinGenie() public view returns (address payable) {
        return _feeTakers.coinGenie;
    }

    /// @dev see ICoinGenieERC20 genie()
    function genie() public view returns (address payable) {
        return payable(address(_genie));
    }

    /// @dev see ICoinGenieERC20 isTradingOpen()
    function isTradingOpen() public view returns (bool) {
        return _isTradingOpen;
    }

    /// @dev see ICoinGenieERC20 isSwapEnabled()
    function isSwapEnabled() public view returns (bool) {
        return _isSwapEnabled;
    }

    /// @dev see ICoinGenieERC20 taxPercent()
    function taxPercent() public view returns (uint256) {
        return _feeAmounts.taxPercent;
    }

    /// @dev see ICoinGenieERC20 maxBuyPercent()
    function maxBuyPercent() public view returns (uint256) {
        return _feeAmounts.maxBuyPercent;
    }

    /// @dev see ICoinGenieERC20 maxWalletPercent()
    function maxWalletPercent() public view returns (uint256) {
        return _feeAmounts.maxWalletPercent;
    }

    /// @dev see ICoinGenieERC20 discountFeeRequiredAmount()
    function discountFeeRequiredAmount() public view returns (uint256) {
        return _feeAmounts.discountFeeRequiredAmount;
    }

    /// @dev see ICoinGenieERC20 discountPercent()
    function discountPercent() public view returns (uint256) {
        return _feeAmounts.discountPercent;
    }

    /// @dev see ICoinGenieERC20 lpToken()
    function lpToken() public view returns (address) {
        return _uniswapV2Pair;
    }

    /// @dev see ICoinGenieERC20 balanceOf()
    function amountEthReceived(address feeRecipient_) public view returns (uint256) {
        return _ethReceived[feeRecipient_];
    }

    /// @dev see ICoinGenieERC20 balanceOf()
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @dev see ICoinGenieERC20 burn()
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @dev see ICoinGenieERC20 transfer()
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @dev see ICoinGenieERC20 allowance()
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @dev see ICoinGenieERC20 approve()
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @dev see ICoinGenieERC20 transferFrom()
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;
    }

    /// @dev see ICoinGenieERC20 manualSwap()
    function manualSwap(uint256 amount) external {
        if (msg.sender != _feeTakers.feeRecipient) {
            revert Unauthorized();
        }

        uint256 contractTokenBalance = _balances[address(this)];
        if (amount > contractTokenBalance) {
            revert InsufficientTokens(amount, contractTokenBalance);
        }

        _swapTokensForEth(amount);

        uint256 contractEthBalance = address(this).balance;
        if (contractEthBalance != 0) {
            _sendEthToFee(contractEthBalance);
        }
    }

    /// @dev see ICoinGenieERC20 createPairAndAddLiquidity()
    function createPairAndAddLiquidity(
        uint256 amountToLP,
        bool payInGenie
    )
        external
        payable
        onlyOwner
        nonReentrant
        returns (address)
    {
        uint256 value = msg.value;
        address from = _msgSender();
        _openTradingChecks(amountToLP, value);

        transfer(address(this), amountToLP);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), _totalSupply);

        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;
        if (payInGenie) {
            ethAmountToTreasury = (ethAmountToTreasury * _feeAmounts.discountPercent) / _MAX_BPS;
            ICoinGenieERC20(_genie).safeTransferFrom(from, _feeTakers.coinGenie, _feeAmounts.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value - ethAmountToTreasury;
        _uniswapV2Pair =
            IUniswapV2Factory(_UNISWAP_V2_ROUTER.factory()).createPair(address(this), _UNISWAP_V2_ROUTER.WETH());

        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), balanceOf(address(this)), 0, 0, from, block.timestamp
        );

        SafeERC20.safeIncreaseAllowance(ICoinGenieERC20(_uniswapV2Pair), address(_UNISWAP_V2_ROUTER), amountToLP);

        _isSwapEnabled = true;
        _isTradingOpen = true;

        if (ethAmountToTreasury != 0) {
            (bool success,) = _feeTakers.coinGenie.call{ value: ethAmountToTreasury }("");
            if (!success) {
                revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.coinGenie);
            }
        }

        emit TradingOpened(_uniswapV2Pair);

        return _uniswapV2Pair;
    }

    /// @dev see ICoinGenieERC20 addLiquidity()
    function addLiquidity(uint256 amountToLP, bool payInGenie) external payable nonReentrant {
        uint256 value = msg.value;
        address from = _msgSender();
        _addLiquidityChecks(amountToLP, value, from);

        uint256 currentContractBalance = _balances[address(this)];
        transfer(address(this), amountToLP);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), amountToLP);

        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;
        if (payInGenie) {
            ethAmountToTreasury = (ethAmountToTreasury * _feeAmounts.discountPercent) / _MAX_BPS;
            ICoinGenieERC20(_genie).safeTransferFrom(from, _feeTakers.coinGenie, _feeAmounts.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value - ethAmountToTreasury;
        SafeERC20.safeIncreaseAllowance(ICoinGenieERC20(_uniswapV2Pair), address(_UNISWAP_V2_ROUTER), amountToLP);
        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), amountToLP, 0, 0, from, block.timestamp
        );

        if (ethAmountToTreasury != 0) {
            (bool success,) = _feeTakers.coinGenie.call{ value: ethAmountToTreasury }("");
            if (!success) {
                revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.coinGenie);
            }
        }

        // If there is any eth left in the contract, send it to the fee recipient
        uint256 ethToRefund = address(this).balance;
        if (ethToRefund != 0) {
            _sendEthToFee(ethToRefund);
        }

        // If there is any token left in the contract, send it to the fee recipient
        uint256 newContractBalance = _balances[address(this)];
        if (currentContractBalance < newContractBalance) {
            _transfer(address(this), _feeTakers.feeRecipient, newContractBalance - currentContractBalance);
        }
    }

    /// @dev see ICoinGenieERC20 removeLiquidity()
    function removeLiquidity(uint256 amountToRemove) external nonReentrant {
        address from = _msgSender();
        ICoinGenieERC20(_uniswapV2Pair).safeTransferFrom(from, address(this), amountToRemove);
        _UNISWAP_V2_ROUTER.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this), amountToRemove, 0, 0, from, block.timestamp
        );
    }

    /// @dev see ICoinGenieERC20 setGenie()
    function setGenie(address genie_) external {
        if (address(_genie) != address(0)) {
            revert GenieAlreadySet();
        }

        _genie = CoinGenieERC20(payable(genie_));
        emit GenieSet(genie_);
    }

    /// @dev see ICoinGenieERC20 setMaxBuyPercent()
    function setMaxBuyPercent(uint256 maxBuyPercent_) external onlyOwner {
        if (maxBuyPercent_ > _MAX_BPS) {
            revert InvalidMaxBuyPercent(maxBuyPercent_);
        }

        _feeAmounts.maxBuyPercent = maxBuyPercent_;
        emit MaxBuyPercentSet(maxBuyPercent_);
    }

    /// @dev see ICoinGenieERC20 setMaxWalletPercent()
    function setMaxWalletPercent(uint256 maxWalletPercent_) external onlyOwner {
        if (maxWalletPercent_ > _MAX_BPS || maxWalletPercent_ < _MIN_WALLET_PERCENT) {
            revert InvalidMaxWalletPercent(maxWalletPercent_);
        }

        _feeAmounts.maxWalletPercent = maxWalletPercent_;
        emit MaxWalletPercentSet(maxWalletPercent_);
    }

    /// @dev see ICoinGenieERC20 setFeeRecipient()
    function setFeeRecipient(address payable feeRecipient_) external onlyOwner {
        _feeTakers.feeRecipient = feeRecipient_;
        transferOwnership(feeRecipient_);
        emit FeeRecipientSet(feeRecipient_);
    }

    /// @dev see ICoinGenieERC20 setCoinGenieFeePercent()
    function setCoinGenieFeePercent(uint256 coinGenieFeePercent_) external onlyOwner {
        if (coinGenieFeePercent_ > _MAX_BPS) {
            revert InvalidCoinGenieFeePercent();
        }

        if (_isFeeSet) {
            revert CoinGenieFeePercentAlreadySet();
        }

        _isFeeSet = true;
        _feeAmounts.coinGenieFeePercent = coinGenieFeePercent_;
    }

    /////////////////////////////////////////////////////////////////
    //                     Private/Internal                        //
    /////////////////////////////////////////////////////////////////

    /// @notice Approves a given amount for the spender.
    /// @dev This is a private function to encapsulate the logic for approvals.
    /// @param owner The address of the token holder.
    /// @param spender The address of the spender.
    /// @param amount The amount of tokens to approve.
    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0) || spender == address(0)) {
            revert ApproveFromZeroAddress();
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Handles the internal transfer of tokens, applying fees and taxes as needed.
    /// @dev This function implements restrictions and special cases for transfers.
    /// @param from The address sending the tokens.
    /// @param to The address receiving the tokens.
    /// @param amount The amount of tokens to transfer.
    function _transfer(address from, address to, uint256 amount) private {
        _checkTransferRestrictions(from, to, amount);

        uint256 totalTaxAmount;
        if (!_whitelist[from] && !_whitelist[to]) {
            if (from == _uniswapV2Pair && to != address(_UNISWAP_V2_ROUTER)) {
                uint256 maxBuyAmount = (_feeAmounts.maxBuyPercent * _totalSupply) / _MAX_BPS;
                if (amount > maxBuyAmount) {
                    revert ExceedsMaxAmount(amount, maxBuyAmount);
                }

                uint256 maxWalletAmount = (_feeAmounts.maxWalletPercent * _totalSupply) / _MAX_BPS;
                if (_balances[to] + amount > maxWalletAmount) {
                    revert ExceedsMaxAmount(_balances[to] + amount, maxWalletAmount);
                }
            }

            uint256 contractTokenBalance = _balances[address(this)];
            totalTaxAmount =
                (amount * _feeAmounts.taxPercent) / _MAX_BPS + (amount * _feeAmounts.coinGenieFeePercent) / _MAX_BPS;
            if (!_inSwap && to == _uniswapV2Pair && _isTradingOpen && contractTokenBalance >= 0) {
                _swapTokensForEth(_min(amount, contractTokenBalance));

                uint256 contractEthBalance = address(this).balance;
                if (contractEthBalance >= _ETH_AUTOSWAP_AMOUNT) {
                    _sendEthToFee(contractEthBalance);
                }
            }
        }

        if (totalTaxAmount != 0) {
            _balances[address(this)] += totalTaxAmount;
            emit Transfer(from, address(this), totalTaxAmount);
        }

        uint256 amountAfterTax = amount - totalTaxAmount;
        _balances[from] -= amount;
        _balances[to] += amountAfterTax;
        emit Transfer(from, to, amountAfterTax);
    }

    /// @notice Burns a given amount of tokens from the specified address.
    /// @dev Tokens are permanently removed from circulation.
    /// @param from The address from which tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function _burn(address from, uint256 amount) private {
        if (from == address(0)) {
            revert BurnFromZeroAddress();
        }

        uint256 balanceOfFrom = _balances[from];
        if (amount > balanceOfFrom) {
            revert InsufficientTokens(amount, balanceOfFrom);
        }

        unchecked {
            _balances[from] -= amount;
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    /// @notice Conducts checks for adding liquidity.
    /// @dev Used to enforce trading conditions and limits.
    /// @param amountToLP The amount of tokens intended for liquidity.
    /// @param value The amount of ETH provided for liquidity.
    /// @param from The address providing the liquidity.
    function _addLiquidityChecks(uint256 amountToLP, uint256 value, address from) private view {
        if (!_isSwapEnabled || !_isTradingOpen) {
            revert TradingNotOpen();
        }

        if (_balances[from] < amountToLP) {
            revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);
        }

        if (value < _MIN_LIQUIDITY_ETH) {
            revert InsufficientETH(value, _MIN_LIQUIDITY_ETH);
        }
    }

    /// @notice Checks conditions before opening trading.
    /// @dev Enforces initial liquidity requirements.
    /// @param amountToLP The amount of tokens intended for liquidity.
    /// @param value The amount of ETH provided for liquidity.
    function _openTradingChecks(uint256 amountToLP, uint256 value) private view {
        if (_isSwapEnabled || _isTradingOpen) {
            revert TradingAlreadyOpen();
        }

        if (amountToLP < _MIN_LIQUIDITY_TOKEN || _balances[owner()] < amountToLP) {
            revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);
        }

        if (value < _MIN_LIQUIDITY_ETH) {
            revert InsufficientETH(value, _MIN_LIQUIDITY_ETH);
        }
    }

    /// @notice Validates the addresses and amounts for transfers.
    /// @dev Throws errors for zero addresses or zero amounts.
    /// @param from The address sending the tokens.
    /// @param to The address receiving the tokens.
    /// @param amount The amount of tokens to transfer.
    function _checkTransferRestrictions(address from, address to, uint256 amount) private pure {
        if (from == address(0) || to == address(0)) {
            revert TransferFromZeroAddress();
        }

        if (amount == 0) {
            revert InsufficientTokens(amount, 0);
        }
    }

    /// @notice Swaps tokens for Ether.
    /// @dev Utilizes Uniswap for the token-to-ETH swap.
    /// @param tokenAmount The amount of tokens to swap for ETH.
    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UNISWAP_V2_ROUTER.WETH();
        _approve(address(this), address(_UNISWAP_V2_ROUTER), tokenAmount);
        _UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    /// @notice Distributes Ether to the specified fee recipients.
    /// @dev Divides and sends Ether based on predefined fee ratios.
    /// @param amount The total amount of Ether to distribute.
    function _sendEthToFee(uint256 amount) private {
        uint256 tax = _feeAmounts.taxPercent;
        uint256 feeRecipientShare = (amount * tax) / (tax + _feeAmounts.coinGenieFeePercent);
        uint256 coinGenieShare = amount - feeRecipientShare;

        address payable _coinGenie = _feeTakers.coinGenie;
        (bool successCoinGenie,) = _coinGenie.call{ value: coinGenieShare }("");
        if (!successCoinGenie) {
            revert TransferFailed(coinGenieShare, address(this), _coinGenie);
        }

        address payable _feeRecipient = _feeTakers.feeRecipient;
        (bool successFeeRecipient,) = _feeRecipient.call{ value: feeRecipientShare }("");
        _ethReceived[_feeRecipient] += feeRecipientShare;
        if (!successFeeRecipient) {
            revert TransferFailed(feeRecipientShare, address(this), _feeTakers.coinGenie);
        }

        emit EthSentToFee(feeRecipientShare, coinGenieShare);
    }

    /// @notice Returns the smaller of the two provided values.
    /// @param a First number.
    /// @param b Second number.
    /// @return The smaller value between a and b.
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Sets the properties for the ERC20 token.
    /// @dev Initializes the token's name, symbol, and total supply.
    /// @param name_ The name of the token.
    /// @param symbol_ The symbol of the token.
    /// @param totalSupply_ The total supply of the token.
    function _setERC20Properties(string memory name_, string memory symbol_, uint256 totalSupply_) private {
        _name = name_;
        _symbol = symbol_;

        if (totalSupply_ < 1 ether || totalSupply_ > 100_000_000_000 ether) {
            revert InvalidTotalSupply(totalSupply_);
        }
        _totalSupply = totalSupply_;
    }

    /// @notice Assigns addresses for fee recipients.
    /// @dev Sets addresses for the main fee recipient, Coin Genie, and affiliate fee recipient.
    /// @param feeRecipient_ The address of the main fee recipient.
    /// @param coinGenie_ The address for Coin Genie.
    /// @param affiliateFeeRecipient_ The address for the affiliate fee recipient.
    function _setFeeRecipients(
        address payable feeRecipient_,
        address payable coinGenie_,
        address payable affiliateFeeRecipient_
    )
        private
    {
        _feeTakers.feeRecipient = feeRecipient_;
        _feeTakers.coinGenie = coinGenie_;

        if (affiliateFeeRecipient_ == address(0)) {
            _feeTakers.affiliateFeeRecipient = coinGenie_;
        } else {
            _feeTakers.affiliateFeeRecipient = affiliateFeeRecipient_;
        }
    }

    /// @notice Configures fee percentages and related parameters.
    /// @dev Sets the tax percentage, max buy percentage, and other fee-related parameters.
    /// @param taxPercent_ The tax percentage on transactions.
    /// @param maxBuyPercent_ The maximum buy percentage.
    /// @param maxWalletPercent_ The maximum wallet percentage.
    /// @param discountFeeRequiredAmount_ The discount fee required amount.
    /// @param discountPercent_ The discount percentage.
    function _setFeePercentages(
        uint256 taxPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 discountFeeRequiredAmount_,
        uint256 discountPercent_
    )
        private
    {
        _feeAmounts.taxPercent = taxPercent_;
        _feeAmounts.maxBuyPercent = maxBuyPercent_;
        _feeAmounts.maxWalletPercent = maxWalletPercent_;
        _feeAmounts.discountFeeRequiredAmount = discountFeeRequiredAmount_;
        _feeAmounts.discountPercent = discountPercent_;
    }

    /// @notice Whitelists specified addresses.
    /// @dev Adds provided addresses to the whitelist.
    /// @param feeRecipient_ The address of the main fee recipient.
    /// @param coinGenie_ The address for Coin Genie.
    /// @param affiliateFeeRecipient_ The address for the affiliate fee recipient.
    function _setWhitelist(address feeRecipient_, address coinGenie_, address affiliateFeeRecipient_) private {
        _whitelist[feeRecipient_] = true;
        _whitelist[coinGenie_] = true;
        _whitelist[affiliateFeeRecipient_] = true;
        _whitelist[address(this)] = true;
    }
}
