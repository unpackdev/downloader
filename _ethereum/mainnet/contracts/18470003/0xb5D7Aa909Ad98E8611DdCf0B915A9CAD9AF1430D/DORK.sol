// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC20Base.sol";
import "./ERC20Burnable.sol";
import "./TaxableToken.sol";


/** * @dev ERC20Token implementation with Burn, Tax capabilities */
contract DORK is ERC20Base, ERC20Burnable, Ownable, TaxableToken {

    uint256 public constant initialSupply_ = 100_000_000_000 * 1 ether;
    address private constant swapRouter_ = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
    
    address[] private collectors_ = [0x17b1F15F038bF0A1F872fa64345204210Cd1a5e5];
    uint256[] private shares_ = [1000];

    constructor()
        ERC20Base(
            "DORK",
            "DORK",
            18)
        TaxableToken(
            true,
            initialSupply_ / 10000,
            swapRouter_,
            FeeConfiguration({
            feesInToken: false,
            buyFees: 200, //2%
            sellFees: 200, //2%
            transferFees: 0,
            burnFeeRatio: 0,
            liquidityFeeRatio: 0,
            collectorsFeeRatio: 10000
        })
        )

        TaxDistributor(collectors_, shares_)
    {
        _mint(_msgSender(), initialSupply_);
    }

    /**     * @dev Destroys `amount` tokens from the caller.     * only callable by `owner()`     */
    function burn(uint256 amount) external override onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**     * @dev Destroys `amount` tokens from `account`, deducting from the caller's     * allowance.     * only callable by `owner()`     */
    function burnFrom(address account, uint256 amount)
        external
        override
        onlyOwner
    {
        _burnFrom(account, amount);
    }

    /**     * @dev Enable/Disable autoProcessFees on transfer     * only callable by `owner()`     */
    function setAutoprocessFees(bool autoProcess) external override onlyOwner {
        require(autoProcessFees != autoProcess, "Already set");
        autoProcessFees = autoProcess;
    }

    /**     * @dev add a fee collector     * only callable by `owner()`     */
    function addFeeCollector(address account, uint256 share)
        external
        override
        onlyOwner
    {
        _addFeeCollector(account, share);
    }

    /**     * @dev add/remove a LP     * only callable by `owner()`     */
    function setIsLpPool(address pairAddress, bool isLp)
        external
        override
        onlyOwner
    {
        _setIsLpPool(pairAddress, isLp);
    }

    /**     * @dev add/remove an address to the tax exclusion list     * only callable by `owner()`     */
    function setIsExcludedFromFees(address account, bool excluded)
        external
        override
        onlyOwner
    {
        _setIsExcludedFromFees(account, excluded);
    }

    /**     * @dev manually distribute fees to collectors     * only callable by `owner()`     */
    function distributeFees(uint256 amount, bool inToken)
        external
        override
        onlyOwner
    {
        if (inToken) {
            require(balanceOf(address(this)) >= amount, "Not enough balance");
        } else {
            require(address(this).balance >= amount, "Not enough balance");
        }
        _distributeFees(amount, inToken);
    }

    /**     * @dev process fees     * only callable by `owner()`     */
    function processFees(uint256 amount, uint256 minAmountOut)
        external
        override
        onlyOwner
    {
        require(amount <= balanceOf(address(this)), "Amount too high");
        _processFees(amount, minAmountOut);
    }

    /**     * @dev remove a fee collector     * only callable by `owner()`     */
    function removeFeeCollector(address account) external override onlyOwner {
        _removeFeeCollector(account);
    }

    /**     * @dev set the liquidity owner     * only callable by `owner()`     */
    function setLiquidityOwner(address newOwner) external override onlyOwner {
        liquidityOwner = newOwner;
    }

    /**     * @dev set the number of tokens to swap     * only callable by `owner()`     */
    function setNumTokensToSwap(uint256 amount) external override onlyOwner {
        numTokensToSwap = amount;
    }

    /**     * @dev update a fee collector share     * only callable by `owner()`     */
    function updateFeeCollectorShare(address account, uint256 share)
        external
        override
        onlyOwner
    {
        _updateFeeCollectorShare(account, share);
    }

    /**     * @dev update the fee configurations     * only callable by `owner()`     */
    function setFeeConfiguration(FeeConfiguration calldata configuration)
        external
        override
        onlyOwner
    {
        _setFeeConfiguration(configuration);
    }

    /**     * @dev update the swap router     * only callable by `owner()`     */
    function setSwapRouter(address newRouter) external override onlyOwner {
        _setSwapRouter(newRouter);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, TaxableToken) {
        super._transfer(from, to, amount);
    }
}

