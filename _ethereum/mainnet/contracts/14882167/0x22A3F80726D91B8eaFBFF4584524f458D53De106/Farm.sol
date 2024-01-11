// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Suspendable.sol";
import "./PoolFarmDepositable.sol";

/** @title Farm.
 * @dev PoolFarmDepositable contract implementation with tiers
 */
contract Farm is Initializable, Suspendable, PoolFarmDepositable {
    /**
     * @notice Initializer
     * @param _depositToken: the address of the token to use for deposit, withdraw and interest
     * @param _tier: the address of the tier contract
     * @param _interestWallet: the wallet to get the interest token from
     * @param _pauser: the address of the account granted with PAUSER_ROLE
     */
    function initialize(
        IERC20Upgradeable _depositToken,
        ITierable _tier,
        address _interestWallet,
        address _pauser
    ) external initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __Suspendable_init_unchained(_pauser);
        __PoolFarmable_init_unchained();
        __Depositable_init_unchained(_depositToken);
        __PoolFarmDepositable_init_unchained(_tier, _interestWallet);
        __Farm_init_unchained();
    }

    function __Farm_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Deposit into a farm pool
     */
    function deposit(uint256 amount, uint256 poolIndex) external whenNotPaused {
        PoolFarmDepositable._deposit(
            _msgSender(),
            _msgSender(),
            amount,
            poolIndex
        );
    }

    /**
     * @notice Withdraw from a farm pool
     */
    function withdraw(uint256 amount, uint256 poolIndex)
        external
        whenNotPaused
    {
        PoolFarmDepositable._withdraw(
            _msgSender(),
            _msgSender(),
            amount,
            poolIndex
        );
    }

    uint256[50] private __gap;
}
