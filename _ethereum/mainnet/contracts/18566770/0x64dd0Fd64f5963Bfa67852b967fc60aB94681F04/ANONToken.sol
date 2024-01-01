// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./AntiWhaleToken.sol";
import "./ERC20Base.sol";
import "./ERC20Burnable.sol";
import "./TaxableToken.sol";

/**
 * @dev ERC20Token implementation with AccessControl, Burn, AntiWhale, Tax capabilities
 */
contract ANONToken is ERC20Base, AntiWhaleToken, ERC20Burnable, AccessControl, TaxableToken {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant EXCLUDED_FROM_ANTIWHALE_ROLE = keccak256("EXCLUDED_FROM_ANTIWHALE_ROLE");
    bytes32 public constant TAX_ADMIN_ROLE = keccak256("TAX_ADMIN_ROLE");

    constructor(
        uint256 initialSupply_,
        address feeReceiver_,
        address swapRouter_,
        FeeConfiguration memory feeConfiguration_,
        address[] memory collectors_,
        uint256[] memory shares_
    )
        payable
        ERC20Base("Anonymous VC", "ANON", 18, 0x312f313639393932342f412f422f572f54)
        AntiWhaleToken(initialSupply_ / 100) // 1% of supply
        TaxableToken(true, initialSupply_ / 10000, swapRouter_, feeConfiguration_)
        TaxDistributor(collectors_, shares_)
    {
        require(initialSupply_ > 0, "Initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(EXCLUDED_FROM_ANTIWHALE_ROLE, BURN_ADDRESS);
        _setupRole(EXCLUDED_FROM_ANTIWHALE_ROLE, _msgSender());
        _setupRole(EXCLUDED_FROM_ANTIWHALE_ROLE, swapPair);
        _setupRole(TAX_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Update the max token allowed per wallet.
     * only callable by members of the `DEFAULT_ADMIN_ROLE`
     */
    function setMaxTokenPerWallet(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMaxTokenPerWallet(amount);
    }

    /**
     * @dev returns true if address is excluded from anti whale
     */
    function isExcludedFromAntiWhale(address account) public view override returns (bool) {
        return hasRole(EXCLUDED_FROM_ANTIWHALE_ROLE, account);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * only callable by members of the `BURNER_ROLE`
     */
    function burn(uint256 amount) external override onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     * only callable by members of the `BURNER_ROLE`
     */
    function burnFrom(address account, uint256 amount) external override onlyRole(BURNER_ROLE) {
        _burnFrom(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, AntiWhaleToken) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Enable/Disable autoProcessFees on transfer
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function setAutoprocessFees(bool autoProcess) external override onlyRole(TAX_ADMIN_ROLE) {
        require(autoProcessFees != autoProcess, "Already set");
        autoProcessFees = autoProcess;
    }

    /**
     * @dev add a fee collector
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function addFeeCollector(address account, uint256 share) external override onlyRole(TAX_ADMIN_ROLE) {
        _addFeeCollector(account, share);
    }

    /**
     * @dev add/remove a LP
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function setIsLpPool(address pairAddress, bool isLp) external override onlyRole(TAX_ADMIN_ROLE) {
        _setIsLpPool(pairAddress, isLp);
    }

    /**
     * @dev add/remove an address to the tax exclusion list
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function setIsExcludedFromFees(address account, bool excluded) external override onlyRole(TAX_ADMIN_ROLE) {
        _setIsExcludedFromFees(account, excluded);
    }

    /**
     * @dev manually distribute fees to collectors
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function distributeFees(uint256 amount, bool inToken) external override onlyRole(TAX_ADMIN_ROLE) {
        if (inToken) {
            require(balanceOf(address(this)) >= amount, "Not enough balance");
        } else {
            require(address(this).balance >= amount, "Not enough balance");
        }
        _distributeFees(amount, inToken);
    }

    /**
     * @dev process fees
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function processFees(uint256 amount, uint256 minAmountOut) external override onlyRole(TAX_ADMIN_ROLE) {
        require(amount <= balanceOf(address(this)), "Amount too high");
        _processFees(amount, minAmountOut);
    }

    /**
     * @dev remove a fee collector
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function removeFeeCollector(address account) external override onlyRole(TAX_ADMIN_ROLE) {
        _removeFeeCollector(account);
    }

    /**
     * @dev set the liquidity owner
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function setLiquidityOwner(address newOwner) external override onlyRole(TAX_ADMIN_ROLE) {
        liquidityOwner = newOwner;
    }

    /**
     * @dev set the number of tokens to swap
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function setNumTokensToSwap(uint256 amount) external override onlyRole(TAX_ADMIN_ROLE) {
        numTokensToSwap = amount;
    }

    /**
     * @dev update a fee collector share
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function updateFeeCollectorShare(address account, uint256 share) external override onlyRole(TAX_ADMIN_ROLE) {
        _updateFeeCollectorShare(account, share);
    }

    /**
     * @dev update the fee configurations
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function setFeeConfiguration(FeeConfiguration calldata configuration) external override onlyRole(TAX_ADMIN_ROLE) {
        _setFeeConfiguration(configuration);
    }

    /**
     * @dev update the swap router
     * only callable by members of the `TAX_ADMIN_ROLE`
     */
    function setSwapRouter(address newRouter) external override onlyRole(TAX_ADMIN_ROLE) {
        _setSwapRouter(newRouter);
    }

    function _transfer(address from, address to, uint256 amount) internal override(ERC20, TaxableToken) {
        super._transfer(from, to, amount);
    }
}
