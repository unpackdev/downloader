// SPDX-License-Identifier: MIT 

pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MockUniswapV2.sol";

contract OwlRouter is Context, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    // address of the OWL token
    address private _owlAddress;
    // uniswap v2 router address
    address private _uniswapV2RouterAddress;
    // address of the tax wallet
    address private _taxWallet;

    // OWL balances of users
    mapping(address => uint256) private _owlBalances;


    constructor (
        address owlAddress,
        address uniswapV2RouterAddress
    ) {
        _owlAddress = owlAddress;
        _uniswapV2RouterAddress = uniswapV2RouterAddress;
        _taxWallet = owner();
    }


    // --- Tax management functions --- 

    /**
     * @dev Sets the address of the tax wallet.
     * @param taxWallet The address of the new tax wallet.
     * @notice This function can only be called by the owner or the current tax wallet.
     * @notice The tax wallet is the address that receives the tax fees for each transaction.
    */
    function setTaxWallet(address taxWallet) external {
        require(_msgSender() == owner() || _msgSender() == _taxWallet, "OwlRouter: caller is not the owner or tax wallet");
        _taxWallet = taxWallet;
    }

    /**
     * @dev Returns the address of the tax wallet.
     * @return The address of the tax wallet.
    */
    function getTaxWallet() external view returns (address) {
        return _taxWallet;
    }


    // --- Contract OWL balance management functions ---

    /**
     * @dev Deposits OWL tokens to the contract.
     * @param amount The amount of OWL tokens to deposit.
     * @notice The OWL tokens are used to pay the tax fees.
     */
    function deposit(uint256 amount) external nonReentrant {
        IERC20(_owlAddress).safeTransferFrom(_msgSender(), address(this), amount);
        _owlBalances[_msgSender()] = _owlBalances[_msgSender()].add(amount);
    }

    /**
     * @dev Withdraws OWL tokens from the contract.
     * @param amount The amount of OWL tokens to withdraw.
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(_owlBalances[_msgSender()] >= amount, "OwlRouter: sender does not have enough OWL balance");
        _owlBalances[_msgSender()] = _owlBalances[_msgSender()].sub(amount);
        IERC20(_owlAddress).safeTransfer(_msgSender(), amount);
    }

    /**
     * @dev Returns the OWL balance of a wallet which has been deposited to the contract.
     * @param wallet The wallet to get the OWL balance for.
     * @return The OWL balance of the specified wallet.
     */
    function balanceOf(address wallet) external view returns (uint256) {
        return _owlBalances[wallet];
    }


    // --- External transfer functions ---

    /**
     * @dev Transfers ETH to a recipient.
     * @param recipient The recipient to transfer ETH to.
     * @param payWithOWL Whether to pay the tax fee with OWL or input ETH.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet.
     * @notice If payWithOWL is true, the sender must have enough OWL balance in the contract.
     * @notice If payWithOWL is false, the fee is deducted from the amount of ETH being transfered.
     */
    function transferETH(address payable recipient, bool payWithOWL, uint256 taxFee) external payable {
        uint256 taxAmount = _sendTax(address(0), msg.value, payWithOWL, taxFee);
        recipient.transfer(msg.value.sub(taxAmount));
    }

    /**
     * @dev Transfers ETH to a recipient.
     * @param recipient The recipient to transfer ETH to.
     * @param tokenAddress The address of the token to transfer.
     * @param amount The amount of tokens to transfer.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet.
     * @notice If payWithOWL is true, the sender must have enough OWL balance in the contract.
     * @notice If payWithOWL is false, the fee is deducted from the amount of tokens being transfered.
     */
    function transfer(address recipient, address tokenAddress, uint256 amount, bool payWithOWL, uint256 taxFee) external {
        uint256 taxAmount = _sendTax(tokenAddress, amount, payWithOWL, taxFee);
        IERC20(tokenAddress).safeTransferFrom(_msgSender(), recipient, amount.sub(taxAmount));
    }

    /**
     * @dev Transfers ETH to a recipient with a custom fee.
     * @param recipient The recipient to transfer ETH to.
     * @param payWithOWL Whether to pay the tax fee with OWL or input ETH.
     * @param taxFee The tax fee pay to the tax wallet.
     * @param appWallet The wallet to receive the custom tax fee.
     * @param customFee The custom tax fee to pay to the app wallet. 
     * @notice Same as transferETH, but the custom tax fee is sent to the app wallet instead of the tax wallet.
     * @notice The app wallet will pay the regular tax fee to the tax wallet using OWL deposited in the contract.
     */
    function transferETHWithCustomFee(address payable recipient, bool payWithOWL, uint256 taxFee, address appWallet, uint256 customFee) external payable {
        uint256 taxAmount = _sendTaxWithCustomFee(address(0), msg.value, payWithOWL, taxFee, appWallet, customFee);
        recipient.transfer(msg.value.sub(taxAmount));
    }

    /**
     * @dev Transfers tokens to a recipient with a custom fee.
     * @param recipient The recipient to transfer tokens to.
     * @param tokenAddress The address of the token to transfer.
     * @param amount The amount of tokens to transfer.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @param appWallet The wallet to receive the custom tax fee.
     * @param customFee The custom tax fee to pay to the app wallet.
     * @notice Same as transfer, but the custom tax fee is sent to the app wallet instead of the tax wallet.
     * @notice The app wallet will pay the regular tax fee to the tax wallet using OWL deposited in the contract.
     */
    function transferWithCustomFee(address recipient, address tokenAddress, uint256 amount, bool payWithOWL, uint256 taxFee, address appWallet, uint256 customFee) external {
        uint256 taxAmount = _sendTaxWithCustomFee(tokenAddress, amount, payWithOWL, taxFee, appWallet, customFee);
        IERC20(tokenAddress).safeTransferFrom(_msgSender(), recipient, amount.sub(taxAmount));
    }

    function transferETHWithReferral(address payable recipient, uint256 taxFee, address referrerWallet, uint256 referrerBonus, uint256 refereeBonus) external payable {
        uint256 taxAmount = _sendTaxWithReferral(address(0), msg.value, taxFee, referrerWallet, referrerBonus, refereeBonus);
        recipient.transfer(msg.value.sub(taxAmount));
    }

    function transferWithReferral(address recipient, address tokenAddress, uint256 amount, uint256 taxFee, address referrerWallet, uint256 referrerBonus, uint256 refereeBonus) external {
        uint256 taxAmount = _sendTaxWithReferral(tokenAddress, amount, taxFee, referrerWallet, referrerBonus, refereeBonus);
        IERC20(tokenAddress).safeTransferFrom(_msgSender(), recipient, amount.sub(taxAmount));
    }


    // --- External swap functions ---

    /**
     * @dev Swaps ETH for tokens.
     * @param tokenAddress The address of the token to swap for.
     * @param amountOutMin The minimum amount of tokens to receive.
     * @param payWithOWL Whether to pay the tax fee with OWL or input ETH.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet.
     * @notice If payWithOWL is true, the sender must have enough OWL balance in the contract.
     * @notice If payWithOWL is false, the fee is deducted from the amount of ETH being transfered.
     */
    function swapETHForTokens(address tokenAddress, uint256 amountOutMin, bool payWithOWL, uint256 taxFee) external payable {
        uint256 taxAmount = _sendTax(address(0), msg.value, payWithOWL, taxFee);
        _swapETHForTokens(tokenAddress, amountOutMin, taxAmount);
    }

    /**
     * @dev Swaps tokens for ETH.
     * @param tokenAddress The address of the token to swap.
     * @param amountIn The amount of tokens to swap.
     * @param amountOutMin The minimum amount of ETH to receive.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet.
     * @notice If payWithOWL is true, the sender must have enough OWL balance in the contract.
     * @notice If payWithOWL is false, the fee is deducted from the amount of tokens being transfered.
     */
    function swapTokensForETH(address tokenAddress, uint256 amountIn, uint256 amountOutMin, bool payWithOWL, uint256 taxFee) external {
        uint256 taxAmount = _sendTax(tokenAddress, amountIn, payWithOWL, taxFee);
        _swapTokensForETH(tokenAddress, amountIn, amountOutMin, taxAmount);
    }

    /**
     * @dev Swaps tokens for tokens.
     * @param tokenAddressIn The address of the token to swap.
     * @param tokenAddressOut The address of the token to swap for.
     * @param amountIn The amount of tokens to swap.
     * @param amountOutMin The minimum amount of tokens to receive.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet.
     * @notice If payWithOWL is true, the sender must have enough OWL balance in the contract.
     * @notice If payWithOWL is false, the fee is deducted from the amount of tokens being transfered.
     */
    function swapTokensForTokens(address tokenAddressIn, address tokenAddressOut, uint256 amountIn, uint256 amountOutMin, bool payWithOWL, uint256 taxFee) external {
        uint256 taxAmount = _sendTax(tokenAddressIn, amountIn, payWithOWL, taxFee);
        _swapTokensForTokens(tokenAddressIn, tokenAddressOut, amountIn, amountOutMin, taxAmount);
    }

    /**
     * @dev Swaps ETH for tokens with a custom fee.
     * @param tokenAddress The address of the token to swap for.
     * @param amountOutMin The minimum amount of tokens to receive.
     * @param payWithOWL Whether to pay the tax fee with OWL or input ETH.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @param appWallet The wallet to receive the custom tax fee.
     * @param customFee The custom tax fee to pay to the app wallet.
     * @notice Same as swapETHForTokens, but the custom tax fee is sent to the app wallet instead of the tax wallet.
     * @notice The app wallet will pay the regular tax fee to the tax wallet using OWL deposited in the contract.
     */
    function swapETHForTokensWithCustomFee(address tokenAddress, uint256 amountOutMin, bool payWithOWL, uint256 taxFee, address appWallet, uint256 customFee) external payable {
        uint256 taxAmount = _sendTaxWithCustomFee(address(0), msg.value, payWithOWL, taxFee, appWallet, customFee);
        _swapETHForTokens(tokenAddress, amountOutMin, taxAmount);
    }

    /**
     * @dev Swaps tokens for ETH with a custom fee.
     * @param tokenAddress The address of the token to swap.
     * @param amountIn The amount of tokens to swap.
     * @param amountOutMin The minimum amount of ETH to receive.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @param appWallet The wallet to receive the custom tax fee.
     * @param customFee The custom tax fee to pay to the app wallet.
     * @notice Same as swapTokensForETH, but the custom tax fee is sent to the app wallet instead of the tax wallet.
     * @notice The app wallet will pay the regular tax fee to the tax wallet using OWL deposited in the contract.
     */
    function swapTokensForETHWithCustomFee(address tokenAddress, uint256 amountIn, uint256 amountOutMin, bool payWithOWL, uint256 taxFee, address appWallet, uint256 customFee) external {
        uint256 taxAmount = _sendTaxWithCustomFee(tokenAddress, amountIn, payWithOWL, taxFee, appWallet, customFee);
        _swapTokensForETH(tokenAddress, amountIn, amountOutMin, taxAmount);
    }

    /**
     * @dev Swaps tokens for tokens with a custom fee.
     * @param tokenAddressIn The address of the token to swap.
     * @param tokenAddressOut The address of the token to swap for.
     * @param amountIn The amount of tokens to swap.
     * @param amountOutMin The minimum amount of tokens to receive.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @param appWallet The wallet to receive the custom tax fee.
     * @param customFee The custom tax fee to pay to the app wallet.
     * @notice Same as swapTokensForTokens, but the custom tax fee is sent to the app wallet instead of the tax wallet.
     * @notice The app wallet will pay the regular tax fee to the tax wallet using OWL deposited in the contract.
     */
    function swapTokensForTokensWithCustomFee(address tokenAddressIn, address tokenAddressOut, uint256 amountIn, uint256 amountOutMin, bool payWithOWL, uint256 taxFee, address appWallet, uint256 customFee) external {
        uint256 taxAmount = _sendTaxWithCustomFee(tokenAddressIn, amountIn, payWithOWL, taxFee, appWallet, customFee);
        _swapTokensForTokens(tokenAddressIn, tokenAddressOut, amountIn, amountOutMin, taxAmount);
    }

    function swapETHForTokensWithReferral(address tokenAddress, uint256 amountOutMin, uint256 taxFee, address referrerWallet, uint256 referrerBonus, uint256 refereeBonus) external payable {
        uint256 taxAmount = _sendTaxWithReferral(address(0), msg.value, taxFee, referrerWallet, referrerBonus, refereeBonus);
        _swapETHForTokens(tokenAddress, amountOutMin, taxAmount);
    }

    function swapTokensForETHWithReferral(address tokenAddress, uint256 amountIn, uint256 amountOutMin, uint256 taxFee, address referrerWallet, uint256 referrerBonus, uint256 refereeBonus) external {
        uint256 taxAmount = _sendTaxWithReferral(tokenAddress, amountIn, taxFee, referrerWallet, referrerBonus, refereeBonus);
        _swapTokensForETH(tokenAddress, amountIn, amountOutMin, taxAmount);
    }

    function swapTokensForTokensWithReferral(address tokenAddressIn, address tokenAddressOut, uint256 amountIn, uint256 amountOutMin, uint256 taxFee, address referrerWallet, uint256 referrerBonus, uint256 refereeBonus) external {
        uint256 taxAmount = _sendTaxWithReferral(tokenAddressIn, amountIn, taxFee, referrerWallet, referrerBonus, refereeBonus);
        _swapTokensForTokens(tokenAddressIn, tokenAddressOut, amountIn, amountOutMin, taxAmount);
    }


    // --- private swap functions ---
    
    /**
     * @dev Swaps ETH for tokens.
     * @param tokenAddress The address of the token to swap for.
     * @param amountOutMin The minimum amount of tokens to receive.
     * @param taxAmount The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet, so it is subtracted from the amount of ETH being swapped.
     */
    function _swapETHForTokens(address tokenAddress, uint256 amountOutMin, uint256 taxAmount) private {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(_uniswapV2RouterAddress).WETH();
        path[1] = tokenAddress;

        IUniswapV2Router02(_uniswapV2RouterAddress).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value.sub(taxAmount)}(amountOutMin, path, _msgSender(), block.timestamp);
    }

    /**
     * @dev Swaps tokens for ETH.
     * @param tokenAddress The address of the token to swap.
     * @param amountIn The amount of tokens to swap.
     * @param amountOutMin The minimum amount of ETH to receive.
     * @param taxAmount The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet, so it is subtracted from the amount of tokens being swapped.
     */
    function _swapTokensForETH(address tokenAddress, uint256 amountIn, uint256 amountOutMin, uint256 taxAmount) private {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = IUniswapV2Router02(_uniswapV2RouterAddress).WETH();

        IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amountIn.sub(taxAmount));
        IERC20(tokenAddress).safeApprove(_uniswapV2RouterAddress, amountIn.sub(taxAmount));
        IUniswapV2Router02(_uniswapV2RouterAddress).swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn.sub(taxAmount), amountOutMin, path, _msgSender(), block.timestamp); 
    }

    /**
     * @dev Swaps tokens for tokens.
     * @param tokenAddressIn The address of the token to swap.
     * @param tokenAddressOut The address of the token to swap for.
     * @param amountIn The amount of tokens to swap.
     * @param amountOutMin The minimum amount of tokens to receive.
     * @param taxAmount The tax fee to pay to the tax wallet.
     * @notice The tax fee is sent to the tax wallet, so it is subtracted from the amount of tokens being swapped.
     */
    function _swapTokensForTokens(address tokenAddressIn, address tokenAddressOut, uint256 amountIn, uint256 amountOutMin, uint256 taxAmount) private {
        address[] memory path = new address[](3);
        path[0] = tokenAddressIn;
        path[1] = IUniswapV2Router02(_uniswapV2RouterAddress).WETH();
        path[2] = tokenAddressOut;

        IERC20(tokenAddressIn).safeTransferFrom(_msgSender(), address(this), amountIn.sub(taxAmount));
        IERC20(tokenAddressIn).safeApprove(_uniswapV2RouterAddress, amountIn.sub(taxAmount));
        IUniswapV2Router02(_uniswapV2RouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn.sub(taxAmount), amountOutMin, path, _msgSender(), block.timestamp);
    }

    // --- Tax fee transfer functions ---

    /**
     * @dev Sends tokens as a tax fee to the tax wallet.
     * @param tokenAddress The address of the token used in the transaction.
     * @param amount The amount of tokens used in the transaction.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     */
    function _sendTax(address tokenAddress, uint256 amount, bool payWithOWL, uint256 taxFee) private returns (uint256) {
        return _sendTaxToTaxWallet(tokenAddress, amount, _taxWallet, payWithOWL, taxFee, taxFee);
    }

    /**
     * @dev Sends tokens as a tax fee to the app wallet and OWL as a tax fee to the tax wallet.
     * @param tokenAddress The address of the token used in the transaction.
     * @param amount The amount of tokens used in the transaction.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @param appWallet The wallet to receive the custom tax fee.
     * @param customFee The custom tax fee to pay to the app wallet.
     * @notice The app wallet will pay the regular tax fee to the tax wallet using OWL deposited in the contract.
     */
    function _sendTaxWithCustomFee(address tokenAddress, uint256 amount, bool payWithOWL, uint256 taxFee, address appWallet, uint256 customFee) private returns (uint256) {
        require(_owlBalances[appWallet] >= taxFee, "OwlRouter: app wallet does not have enough OWL balance");
        
        // send tax from app wallet to tax wallet
        _owlBalances[appWallet] = _owlBalances[appWallet].sub(taxFee);
        _owlBalances[_taxWallet] = _owlBalances[_taxWallet].add(taxFee);

        // send tax from sender to app wallet
        return _sendTaxToTaxWallet(tokenAddress, amount, appWallet, payWithOWL, customFee, customFee);
    }

    /**
     * @dev Sends tax fee to the tax wallet and referral bonuses to the referrer and referee.
     * @param tokenAddress The address of the token used in the transaction.
     * @param amount The amount of tokens used in the transaction.
     * @param taxFee The tax fee to pay to the tax wallet.
     * @param referrerWallet The wallet to receive the referral bonus.
     * @param referrerBonus The referral bonus to pay to the referrer.
     * @param refereeBonus The referral bonus to pay to the referee.
     * @notice The referrer and referee bonuses must not exceed the tax fee.
     * @notice The referral bonuses are deducted from the tax fee.
     */
    function _sendTaxWithReferral(address tokenAddress, uint256 amount, uint256 taxFee, address referrerWallet, uint256 referrerBonus, uint256 refereeBonus) private returns (uint256) {
        require(referrerBonus.add(refereeBonus) <= taxFee, "OwlRouter: referral bonuses exceed tax fee");

        // send tax from sender to tax wallet
        
        uint256 taxAmount = _sendTaxToTaxWallet(tokenAddress, amount, _taxWallet, true, taxFee, taxFee.sub(referrerBonus).sub(refereeBonus));

        // pay referrer and referee bonuses
        _owlBalances[referrerWallet] = _owlBalances[referrerWallet].add(referrerBonus);
        _owlBalances[_msgSender()] = _owlBalances[_msgSender()].add(refereeBonus);

        return taxAmount;
    }

    /**
     * @dev Sends tokens as a tax fee to the tax wallet.
     * @param tokenAddress The address of the token used in the transaction.
     * @param amount The amount of tokens used in the transaction.
     * @param taxWallet The wallet to receive the tax fee.
     * @param payWithOWL Whether to pay the tax fee with OWL or input tokens.
     * @param taxSubtracted The tax fee to subtract from the the sender.
     * @param taxPayed The tax fee to send to the tax wallet.
     * @notice This function is called by _sendTax and _sendTaxWithCustomFee to send the tax fee to the tax wallet.
     */
    function _sendTaxToTaxWallet(address tokenAddress, uint256 amount, address taxWallet, bool payWithOWL, uint256 taxSubtracted, uint256 taxPayed) private returns (uint256) {
        if (taxSubtracted == 0) {
            return 0;
        }

        // pay tax fee with OWL
        if (payWithOWL) {
            require(_owlBalances[_msgSender()] >= taxSubtracted, "OwlRouter: sender does not have enough OWL balance");
            _owlBalances[_msgSender()] = _owlBalances[_msgSender()].sub(taxSubtracted);
            _owlBalances[taxWallet] = _owlBalances[taxWallet].add(taxPayed);
            return 0;
        }

        require(taxSubtracted <= amount, "OwlRouter: taxFee exceeds amount");
        
        // pay tax fee with ETH
        if (tokenAddress == address(0)) {
            payable(taxWallet).transfer(taxSubtracted);
        }
        // pay tax fee with tokens
        else {
            IERC20(tokenAddress).safeTransferFrom(_msgSender(), taxWallet, taxSubtracted);
        }
        return taxSubtracted;
    }


    // --- default contract functions ---

    receive() external payable {}

}