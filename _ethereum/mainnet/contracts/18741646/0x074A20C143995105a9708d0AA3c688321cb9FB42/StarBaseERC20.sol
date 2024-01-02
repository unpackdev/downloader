// SPDX-License-Identifier: UNLICENSED
// Powered by Agora

pragma solidity ^0.8.21;

import "./Address.sol";

import "./EnumerableSet.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Locker.sol";
import "./IERC20.sol";
import "./IAgoraERC20.sol";
import "./Ownable.sol";

import "./console.sol";

contract StarBaseERC20 is IAgoraERC20, Ownable {
    bytes32 public constant ID_HASH =
        0x4D45544144524F504D45544144524F504D45544144524F504D45544144524F50;

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /** @dev {_balances} Addresses balances */
    mapping(address => uint256) private _balances;

    /** @dev {_allowances} Addresses allocance details */
    mapping(address => mapping(address => uint256)) private _allowances;

    /** @dev {_unlimited} Enumerable set for addresses where limits do not apply */
    EnumerableSet.AddressSet private _excludedFromLimits;

    // Config
    IUniswapV2Router02 internal immutable _uniswapRouter;
    IUniswapV2Locker internal immutable _tokenVault;
    uint256 internal constant MAX_SWAP_THRESHOLD_MULTIPLE = 20;
    uint256 internal constant CALL_GAS_LIMIT = 50000;
    address public immutable factory;
    address public immutable startShipVault;
    address public taxRecepient;
    string private _name;
    string private _symbol;

    uint128 private _totalSupply;

    // Tax
    bool private _hasTax;
    uint16 public buyTax;
    uint16 public sellTax;
    uint128 public accumulatedTax;
    uint128 public starShipAccumulatedTax;
    bool public swapEnabled;
    uint16 public starShipTaxPoints = 5;
    bool public shouldPayInTax;

    // Liquidty info
    uint32 public lpCreatedDate;
    address public pairAddress;
    bool public burnLiquidity;
    bool private _swapping;
    uint16 public pctForSwap; // Per thousands
    uint128 public lockFee;
    uint256 public liquidityLockedInDays;
    uint128 public initialLiquidityFunds;
    uint256 public lockedUntil;

    // Caps
    uint128 public buyMaxTx;
    uint128 public sellMaxTx;
    uint128 public maxWallet;

    modifier onlyFactoryOrOwner() {
        if (msg.sender != factory && msg.sender != owner()) {
            Revert(OperationNotAllowed.selector);
        }
        _;
    }

    constructor(
        address[5] memory addresses,
        bytes memory tokenInfo,
        bytes memory taxesInfo,
        bytes memory lpInfo
    ) {
        pctForSwap = 5;
        transferOwnership(addresses[0]);
        _uniswapRouter = IUniswapV2Router02(addresses[1]);
        _tokenVault = IUniswapV2Locker(addresses[2]);
        factory = addresses[3];
        startShipVault = addresses[4];
        TokenInfoParameters memory tokenParameters = abi.decode(
            tokenInfo,
            (TokenInfoParameters)
        );

        _name = tokenParameters.name;
        _symbol = tokenParameters.symbol;
        shouldPayInTax = tokenParameters.payInTax;

        if (type(uint128).max < tokenParameters.maxTokensWallet) {
            Revert(HardCapIsTooHigh.selector);
        }

        maxWallet = uint128(tokenParameters.maxTokensWallet);
        TaxParameters memory taxParams = abi.decode(taxesInfo, (TaxParameters));
        _processLimits(taxParams);

        taxRecepient = taxParams.taxSwapRecepient;
        TokenLpInfo memory tokenLpInfo = abi.decode(lpInfo, (TokenLpInfo));
        _processSupply(tokenParameters, tokenLpInfo);
        burnLiquidity = tokenLpInfo.burnLP;
        lockFee = uint128(tokenLpInfo.lockFee);
        liquidityLockedInDays = tokenLpInfo.lpLockUpInDays;
        initialLiquidityFunds = uint128(tokenLpInfo.ethForSupply);
        pairAddress = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );
        _excludedFromLimits.add(address(_uniswapRouter));
        _excludedFromLimits.add(pairAddress);

        _excludedFromLimits.add(address(this));
        _excludedFromLimits.add(address(0));
        _excludedFromLimits.add(owner());
    }

    /**
     * This will mint the balances for the liquidity pool, which will be minted to the
     * contract and the rest will be minted to the caller. Also, transaction will revert
     * if less than 25% of the tokens are not designated to the liquidity pool.
     *
     * @param tokenParameters Token info parameters where the total supply is
     * @param tokenLpInfo The information about the liquidity pool
     */
    function _processSupply(
        TokenInfoParameters memory tokenParameters,
        TokenLpInfo memory tokenLpInfo
    ) internal {
        if (tokenLpInfo.lpTokensupply > tokenParameters.maxSupply) {
            Revert(LpTokensExceedsTotalSupply.selector);
        }

        if (
            tokenLpInfo.lpTokensupply < ((tokenParameters.maxSupply * 25) / 100)
        ) {
            Revert(TooFewLPTokens.selector);
        }

        if (tokenLpInfo.lpTokensupply > 0) {
            _mint(address(this), tokenLpInfo.lpTokensupply);
        }
        address tokensOwner = (tokenParameters.tokensRecepient != address(0))
            ? tokenParameters.tokensRecepient
            : msg.sender;

        _mint(
            tokensOwner,
            tokenParameters.maxSupply - tokenLpInfo.lpTokensupply
        );
    }

    /**
     * Adds to the liquidity pool the total balance of the contract and the value of the
     * transaction to the liquidity pool
     */
    function addLiquidity()
        external
        payable
        onlyFactoryOrOwner
        returns (address)
    {
        if (lpCreatedDate != 0) {
            Revert(LPAlreadyCreated.selector);
        }

        lpCreatedDate = uint32(block.timestamp);

        // Can only do this if this contract holds tokens:
        if (this.balanceOf(address(this)) == 0) {
            Revert(NotEnoughFundsForLP.selector);
        }

        // Adding approval
        _approve(address(this), address(_uniswapRouter), type(uint256).max);

        (uint256 amountA, uint256 amountB, uint256 lpTokens) = _uniswapRouter
            .addLiquidityETH{value: initialLiquidityFunds}(
            address(this),
            _balances[address(this)],
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        _swapping = false;
        emit LiquidityAdded(amountA, amountB, lpTokens);

        if (burnLiquidity) {
            emit LiquidityBurned(lpTokens);
            IERC20(pairAddress).transfer(address(0), lpTokens);
        } else {
            _lockLiquidity(lpTokens);
        }
        return pairAddress;
    }

    function _lockLiquidity(uint256 tokens) internal {
        IERC20(pairAddress).approve(address(_tokenVault), tokens);
        lockedUntil = block.timestamp + (liquidityLockedInDays * 1 days);
        console.log(lockFee);
        console.log("Jesus cristo", pairAddress);
        console.log(lockedUntil);
        console.log(owner());
        console.log(tokens);
        try
            _tokenVault.lockLPToken{value: lockFee}(
                pairAddress,
                IERC20(pairAddress).balanceOf(address(this)),
                lockedUntil,
                payable(address(0)),
                true,
                payable(owner())
            )
        {} catch Error(string memory error) {
            console.log(error);
        } catch (bytes memory reason) {
            console.log("the wat");
            console.logBytes(reason);
        }

        emit LiquidityLocked(tokens, liquidityLockedInDays);
    }

    function toggleSwap() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    /**
     * Reads and stores the relevant information about the taxes.
     * @param taxParams Tax configuration
     */
    function _processLimits(TaxParameters memory taxParams) internal {
        if (taxParams.buyTax == 0 && taxParams.sellTax == 0) {
            _hasTax = false;
        } else {
            _hasTax = true;
            buyTax = uint16(taxParams.buyTax);
            sellTax = uint16(taxParams.sellTax);

            if (
                type(uint128).max < taxParams.maxTxSell ||
                type(uint128).max < taxParams.maxTxBuy
            ) {
                Revert(HardCapIsTooHigh.selector);
            }
            buyMaxTx = uint128(taxParams.maxTxBuy);
            sellMaxTx = uint128(taxParams.maxTxSell);
        }
    }

    function isExcludedFromLimits(address who) external view returns (bool) {
        return _excludedFromLimits.contains(who);
    }

    function excludedFromLimits(address who) external onlyOwner {
        _excludedFromLimits.add(who);
    }

    /**
     * @dev This funciton will execute the code to change the taxes, but if an attempt is made to raise
     * any of the taxes, it will revert the transaction, as taxes can only be lowered.
     * @param newBuyTax The new buying tax to be applied
     * @param newSellTax The new sell tax to be applied
     */
    function changeTaxes(
        uint256 newBuyTax,
        uint256 newSellTax
    ) external onlyOwner {
        if (newBuyTax > buyTax) {
            Revert(TaxesCanNotBeRaised.selector);
        }

        if (newSellTax > sellTax) {
            Revert(TaxesCanNotBeRaised.selector);
        }
        uint16 oldBuyTax = buyTax;
        uint16 oldSellTax = sellTax;
        buyTax = uint16(newBuyTax);
        sellTax = uint16(newSellTax);

        _hasTax = buyTax > 0 && sellTax > 0;

        emit TaxesLowered(oldBuyTax, oldSellTax, buyTax, sellTax);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            Revert(MintToZeroAddress.selector);
        }

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += uint128(amount);
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            Revert(BurnFromTheZeroAddress.selector);
        }

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) {
            Revert(BurnExceedsBalance.selector);
        }

        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= uint128(amount);
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        // Approvals
        _safeGuardAllowance(from, _msgSender(), amount);
        return _transfer(from, to, amount);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function _swapTaxes(address from, address to) internal {
        if (_shouldApplyTax() && swapEnabled) {
            uint256 swapBalance = accumulatedTax + starShipAccumulatedTax;

            uint256 swapThresholdInTokens = (_totalSupply * pctForSwap) / 1000;
            if (
                swapBalance >= swapThresholdInTokens &&
                !_swapping &&
                from != pairAddress &&
                from != address(_uniswapRouter) &&
                to != address(_uniswapRouter)
            ) {
                _swapping = true;
                if (
                    swapBalance >
                    swapThresholdInTokens * MAX_SWAP_THRESHOLD_MULTIPLE
                ) {
                    swapBalance =
                        swapThresholdInTokens *
                        MAX_SWAP_THRESHOLD_MULTIPLE;
                }

                // Perform the auto swap to native token:
                _doSwap(swapBalance, this.balanceOf(address(this)));

                // Flag that the autoswap is complete:
                _swapping = false;
            }
        }
    }

    function _doSwap(uint256 swapBalance_, uint256 contractBalance_) internal {
        uint256 preSwapNativeBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        // Wrap external calls in try / catch to handle errors
        try
            _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapBalance_,
                0,
                path,
                address(this),
                block.timestamp + 600
            )
        {
            uint256 postSwapBalance = address(this).balance;

            uint256 totalPendingSwap = accumulatedTax + starShipAccumulatedTax;
            uint256 balanceToDistribute = postSwapBalance -
                preSwapNativeBalance;
            uint256 projectBalanceToDistribute = (balanceToDistribute *
                accumulatedTax) / totalPendingSwap;
            uint256 starShipBalance = (balanceToDistribute *
                starShipAccumulatedTax) / totalPendingSwap;

            if (swapBalance_ < contractBalance_) {
                accumulatedTax -= uint128(
                    (accumulatedTax * swapBalance_) / contractBalance_
                );
                starShipAccumulatedTax -= uint128(
                    (starShipAccumulatedTax * swapBalance_) / contractBalance_
                );
            } else {
                (accumulatedTax, starShipAccumulatedTax) = (0, 0);
            }

            // Distribute to treasuries:
            bool success;
            uint256 gas;
            if (projectBalanceToDistribute > 0) {
                // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
                gas = (CALL_GAS_LIMIT == 0 || CALL_GAS_LIMIT > gasleft())
                    ? gasleft()
                    : CALL_GAS_LIMIT;
                // We limit the gas passed so that a called address cannot cause a block out of gas error:
                (success, ) = taxRecepient.call{
                    value: projectBalanceToDistribute,
                    gas: gas
                }("");
            }

            if (starShipBalance > 0) {
                // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
                gas = (CALL_GAS_LIMIT == 0 || CALL_GAS_LIMIT > gasleft())
                    ? gasleft()
                    : CALL_GAS_LIMIT;

                // We limit the gas passed so that a called address cannot cause a block out of gas error:
                (success, ) = startShipVault.call{
                    value: starShipBalance,
                    gas: gas
                }("");
            }
        } catch {
            // Dont allow a failed external call (in this case to uniswap) to stop a transfer.
            // Emit that this has occured and continue.
            emit ExternalCallError(5);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _safeGuardTransfer(from, to, amount);
        uint128 realAmount = _applyTaxes(from, to, amount);

        _swapTaxes(from, to);

        unchecked {
            _balances[from] -= amount;
            _balances[to] += realAmount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function _shouldApplyTax() internal view returns (bool) {
        return _hasTax || shouldPayInTax;
    }

    function _buyTax() internal view returns (uint16) {
        return shouldPayInTax ? buyTax + starShipTaxPoints : buyTax;
    }

    function _sellTax() internal view returns (uint16) {
        return shouldPayInTax ? sellTax + starShipTaxPoints : sellTax;
    }

    function _applyTaxes(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint128) {
        uint128 taxedAmount = uint128(amount);
        uint128 taxAmount = 0;
        uint128 starshipTax = 0;
        if (_shouldApplyTax() && !_swapping) {
            if (
                from == pairAddress &&
                _buyTax() > 0 &&
                !_excludedFromLimits.contains(to)
            ) {
                taxAmount = (taxedAmount * buyTax) / 1000;
                if (shouldPayInTax) {
                    starshipTax = (taxedAmount * starShipTaxPoints) / 1000;
                    starShipAccumulatedTax += starshipTax;
                }
            } else if (
                to == pairAddress &&
                _sellTax() > 0 &&
                !_excludedFromLimits.contains(from)
            ) {
                taxAmount = (taxedAmount * sellTax) / 1000;
                if (shouldPayInTax) {
                    starshipTax = (taxedAmount * starShipTaxPoints) / 1000;
                    starShipAccumulatedTax += starshipTax;
                }
            }

            if (taxAmount > 0 || starshipTax > 0) {
                unchecked {
                    accumulatedTax += taxAmount;
                    _balances[address(this)] += taxAmount + starshipTax;
                }

                emit Transfer(from, address(this), taxAmount + starshipTax);
            }
        }

        return taxedAmount - taxAmount;
    }

    function _safeGuardTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view {
        if (to == pairAddress && from != address(this) && lpCreatedDate == 0) {
            Revert(LPNotInit.selector);
        }

        uint256 fromBalance = _balances[from];

        if (fromBalance < amount) {
            Revert(NotEnoughBalance.selector);
        }
        if (
            buyMaxTx > 0 &&
            from == pairAddress &&
            !_excludedFromLimits.contains(to) &&
            amount > buyMaxTx
        ) {
            Revert(TransactionIsTooBig.selector);
        }
        if (
            sellMaxTx > 0 &&
            to == pairAddress &&
            !_excludedFromLimits.contains(from) &&
            amount > sellMaxTx
        ) {
            Revert(TransactionIsTooBig.selector);
        }
        uint256 toBalance = _balances[to];
        if (
            maxWallet > 0 &&
            maxWallet < toBalance + amount &&
            !_excludedFromLimits.contains(to)
        ) {
            Revert(MaxWalletExceeded.selector);
        }
    }

    function changeTransactionHardCaps(
        uint256 newBuyMaxTx,
        uint256 newSellMaxTx,
        uint256 newMaxWallet
    ) external onlyOwner {
        if (
            newBuyMaxTx < buyMaxTx ||
            newSellMaxTx < sellMaxTx ||
            newMaxWallet < maxWallet
        ) {
            Revert(LimitsLoweringIsNotAllowed.selector);
        }
        uint128 oldMaxWallet = maxWallet;
        uint128 oldMaxSellTx = sellMaxTx;
        uint128 oldMaxBuyTx = buyMaxTx;
        buyMaxTx = uint128(newBuyMaxTx);
        sellMaxTx = uint128(newSellMaxTx);
        maxWallet = uint128(newMaxWallet);

        emit LimitsRaised(
            oldMaxBuyTx,
            oldMaxSellTx,
            oldMaxWallet,
            buyMaxTx,
            sellMaxTx,
            maxWallet
        );
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) {
            Revert(ApproveFromTheZeroAddress.selector);
        }

        if (spender == address(0)) {
            Revert(ApproveToTheZeroAddress.selector);
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _safeGuardAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = this.allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                Revert(InsufficientAllowance.selector);
            }

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    receive() external payable {}
}
