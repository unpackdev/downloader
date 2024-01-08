// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

/**
 * @dev Interface of the Momentum Sale Smart Contract.
 *
 * Selling EDGEX tokens at a fixed price
 * with a 1-day lock period. Users can claim their purchase after
 * the end of 1 day or 24 hours.
 */

interface IMomentumSale {
    /**
     * @dev allocates the `_allocated` amount of tokens for the current 24 hour sale.
     *
     * `_source` should be the specified as the external oracle source or the
     * internal fallback price.
     *
     * Requirements:
     * `caller` should be governor.
     */
    function createSaleContract(uint256 _allocated, uint8 _source)
        external
        returns (bool);

    /**
     * @dev increases the number of tokens allocated for each saleId.
     *
     * Requirements:
     * `_saleId` should have an active ongoing sale.
     * Allocated cannot be increased for ended sales.
     *
     * Requirements:
     * `caller` should be governor.
     */
    function increaseAllocation(uint256 _amount, uint256 _saleId)
        external
        returns (bool);

    /**
     * @dev purchases edgex tokens by calling this function with ethers.
     *
     * Requirements:
     * `caller` should've to be whitelisted.
     * there should be an active sale ongoing.
     * allocated tokens should be available.
     */
    function purchaseWithEth() external payable returns (bool);

    /**
     * @dev allocated EDGEX tokens to users on behalf of them.
     * used for off-chain purchases.
     *
     * Requirements:
     * `_user` should be whitelisted for sale.
     * current sale should be live and not sold out.
     * `caller` should be governor.
     */
    function adminPurchase(
        address _user,
        uint256 _amountToken,
        uint256 _usdPurchase,
        uint256 _pricePurchase
    ) external returns (bool);

    /**
     * @dev returns the EDGEX token price.
     *
     * Based on the current business logic, EDGEX price can be an internal source
     * or from an external oracle.
     */
    function fetchTokenPrice() external returns (uint256);

    function claim(uint256 _saleId) external returns (bool);

    /**
     * @dev calculates the bonus tokens for each purchase by an user.
     */
    function resolveBonus(uint256 _saleId, address _user)
        external
        returns (uint256);

    /**
     * @dev maps the amount of sold tokens to the bonus percent.
     */
    function resolveBonusPercent(uint256 _saleId) external returns (uint256);

    /**
     * @dev can change the Chainlink EDGEX Source.
     *
     * Requirements:
     * `_newSource` cannot be a zero address.
     * `_index` should be less than 15
     */
    function updateNewEdgexSource(address _newSource, uint8 _index)
        external
        returns (bool);

    /**
     * @dev transfer the control of genesis sale to another account.
     *
     * Onwers can add governors.
     *
     * Requirements:
     * `_newOwner` cannot be a zero address.
     *
     * CAUTION: EXECUTE THIS FUNCTION WITH CARE.
     */
    function revokeOwnership(address _newOwner) external returns (bool);

    /**
     * @dev can change the Chainlink ETH Source.
     *
     * Requirements:
     * `_ethSource` cannot be a zero address.
     */
    function updateEthSource(address _newSource) external returns (bool);

    /**
     * @dev can change the contract address of EDGEX tokens.
     *
     * Requirements:
     * `_contract` cannot be a zero address.
     */
    function updateEdgexTokenContract(address _newSource)
        external
        returns (bool);
}
