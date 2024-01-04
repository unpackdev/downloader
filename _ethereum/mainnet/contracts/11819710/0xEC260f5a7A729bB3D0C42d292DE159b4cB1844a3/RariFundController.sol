/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./LibOrder.sol";
import "./IEtherToken.sol";

import "./DydxPoolController.sol";
import "./CompoundPoolController.sol";
import "./KeeperDaoPoolController.sol";
import "./AavePoolController.sol";
import "./AlphaPoolController.sol";
import "./EnzymePoolController.sol";
import "./ZeroExExchangeController.sol";

/**
 * @title RariFundController
 * @author David Lucid <david@rari.capital> (https://github.com/davidlucid)
 * @author Richter Brzeski <richter@rari.capital> (https://github.com/richtermb)
 * @dev This contract handles deposits to and withdrawals from the liquidity pools that power the Rari Ethereum Pool as well as currency exchanges via 0x.
 */
contract RariFundController is Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;

    /**
     * @dev Boolean to be checked on `upgradeFundController`.
     */
    bool public constant IS_RARI_FUND_CONTROLLER = true;

    /**
     * @dev Boolean that, if true, disables the primary functionality of this RariFundController.
     */
    bool private _fundDisabled;

    /**
     * @dev Address of the RariFundManager.
     */
    address payable private _rariFundManagerContract;

    /**
     * @dev Address of the rebalancer.
     */
    address private _rariFundRebalancerAddress;

    /**
     * @dev Enum for liqudity pools supported by Rari.
     */
    enum LiquidityPool { dYdX, Compound, KeeperDAO, Aave, Alpha, Enzyme }

    /**
     * @dev Maps arrays of supported pools to currency codes.
     */
    uint8[] private _supportedPools;

    /**
     * @dev COMP token address.
     */
    address constant private COMP_TOKEN = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    /**
     * @dev ROOK token address.
     */
    address constant private ROOK_TOKEN = 0xfA5047c9c78B8877af97BDcb85Db743fD7313d4a;

    /**
     * @dev WETH token contract.
     */
    IEtherToken constant private _weth = IEtherToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /**
     * @dev Caches the balances for each pool, with the sum cached at the end
     */
    uint256[] private _cachedBalances;

    /**
     * @dev Constructor that sets supported ERC20 token contract addresses and supported pools for each supported token.
     */
    constructor () public {
        Ownable.initialize(msg.sender);
        // Add supported pools
        addPool(0); // dYdX
        addPool(1); // Compound
        addPool(2); // KeeperDAO
        addPool(3); // Aave
        addPool(4); // Alpha
        addPool(5); // Enzyme
    }

    /**
     * @dev Adds a supported pool for a token.
     * @param pool Pool ID to be supported.
     */
    function addPool(uint8 pool) internal {
        _supportedPools.push(pool);
    }

    /**
     * @dev Payable fallback function called by 0x exchange to refund unspent protocol fee.
     */
    function () external payable { }

    /**
     * @dev Emitted when the RariFundManager of the RariFundController is set.
     */
    event FundManagerSet(address newAddress);

    /**
     * @dev Sets or upgrades the RariFundManager of the RariFundController.
     * @param newContract The address of the new RariFundManager contract.
     */
    function setFundManager(address payable newContract) external onlyOwner {
        _rariFundManagerContract = newContract;
        emit FundManagerSet(newContract);
    }

    /**
     * @dev Throws if called by any account other than the RariFundManager.
     */
    modifier onlyManager() {
        require(_rariFundManagerContract == msg.sender, "Caller is not the fund manager.");
        _;
    }

    /**
     * @dev Emitted when the rebalancer of the RariFundController is set.
     */
    event FundRebalancerSet(address newAddress);

    /**
     * @dev Sets or upgrades the rebalancer of the RariFundController.
     * @param newAddress The Ethereum address of the new rebalancer server.
     */
    function setFundRebalancer(address newAddress) external onlyOwner {
        _rariFundRebalancerAddress = newAddress;
        emit FundRebalancerSet(newAddress);
    }

    /**
     * @dev Throws if called by any account other than the rebalancer.
     */
    modifier onlyRebalancer() {
        require(_rariFundRebalancerAddress == msg.sender, "Caller is not the rebalancer.");
        _;
    }

    /**
     * @dev Emitted when the primary functionality of this RariFundController contract has been disabled.
     */
    event FundDisabled();

    /**
     * @dev Emitted when the primary functionality of this RariFundController contract has been enabled.
     */
    event FundEnabled();

    /**
     * @dev Disables primary functionality of this RariFundController so contract(s) can be upgraded.
     */
    function disableFund() external onlyOwner {
        require(!_fundDisabled, "Fund already disabled.");
        _fundDisabled = true;
        emit FundDisabled();
    }

    /**
     * @dev Enables primary functionality of this RariFundController once contract(s) are upgraded.
     */
    function enableFund() external onlyOwner {
        require(_fundDisabled, "Fund already enabled.");
        _fundDisabled = false;
        emit FundEnabled();
    }

    /**
     * @dev Throws if fund is disabled.
     */
    modifier fundEnabled() {
        require(!_fundDisabled, "This fund controller contract is disabled. This may be due to an upgrade.");
        _;
    }

    /**
     * @dev Sets or upgrades RariFundController by forwarding immediate balance of ETH from the old to the new.
     * @param newContract The address of the new RariFundController contract.
     */
    function _upgradeFundController(address payable newContract) public onlyOwner {
        // Verify fund is disabled + verify new fund controller contract
        require(_fundDisabled, "This fund controller contract must be disabled before it can be upgraded.");
        require(RariFundController(newContract).IS_RARI_FUND_CONTROLLER(), "New contract does not have IS_RARI_FUND_CONTROLLER set to true.");

        // Transfer all ETH to new fund controller
        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = newContract.call.value(balance)("");
            require(success, "Failed to transfer ETH.");
        }
    }


    /**
     * @dev Sets or upgrades RariFundController by withdrawing all ETH from all pools and forwarding them from the old to the new.
     * @param newContract The address of the new RariFundController contract.
     */
    function upgradeFundController(address payable newContract) external onlyOwner {
        // Withdraw all from Enzyme first because they output other LP tokens
        if (hasETHInPool(5))
            _withdrawAllFromPool(5);

        // Then withdraw all from all other pools
        for (uint256 i = 0; i < _supportedPools.length; i++)
            if (hasETHInPool(_supportedPools[i]))
                _withdrawAllFromPool(_supportedPools[i]);

        // Transfer all ETH to new fund controller
        _upgradeFundController(newContract);
    }


    /**
     * @dev Returns the fund controller's balance of the specified currency in the specified pool.
     * @dev Ideally, we can add the view modifier, but Compound's `getUnderlyingBalance` function (called by `CompoundPoolController.getBalance`) potentially modifies the state.
     * @param pool The index of the pool.
     */
    function _getPoolBalance(uint8 pool) public returns (uint256) {
        if (pool == 0) return DydxPoolController.getBalance();
        else if (pool == 1) return CompoundPoolController.getBalance();
        else if (pool == 2) return KeeperDaoPoolController.getBalance();
        else if (pool == 3) return AavePoolController.getBalance();
        else if (pool == 4) return AlphaPoolController.getBalance();
        else if (pool == 5) return EnzymePoolController.getBalance(_enzymeComptroller);
        else revert("Invalid pool index.");
    }

    /**
     * @dev Returns the fund controller's balance of the specified currency in the specified pool.
     * @dev Ideally, we can add the view modifier, but Compound's `getUnderlyingBalance` function (called by `CompoundPoolController.getBalance`) potentially modifies the state.
     * @param pool The index of the pool.
     */
    function getPoolBalance(uint8 pool) public returns (uint256) {
        if (!_poolsWithFunds[pool]) return 0;
        return _getPoolBalance(pool);
    }

    /**
     * @notice Returns the fund controller's balance of each pool of the specified currency.
     * @dev Ideally, we can add the view modifier, but Compound's `getUnderlyingBalance` function (called by `getPoolBalance`) potentially modifies the state.
     * @return An array of pool indexes and an array of corresponding balances.
     */
    function getEntireBalance() public returns (uint256) {
        uint256 sum = address(this).balance; // start with immediate eth balance
        for (uint256 i = 0; i < _supportedPools.length; i++) {
            sum = getPoolBalance(_supportedPools[i]).add(sum);
        }
        return sum;
    }

    /**
     * @dev Approves WETH to pool without spending gas on every deposit.
     * @param pool The index of the pool.
     * @param amount The amount of WETH to be approved.
     */
    function approveWethToPool(uint8 pool, uint256 amount) external fundEnabled onlyRebalancer {
        if (pool == 0) return DydxPoolController.approve(amount);
        else if (pool == 5) return EnzymePoolController.approve(_enzymeComptroller, amount);
        else revert("Invalid pool index.");
    }

    /**
     * @dev Approves kEther to the specified pool without spending gas on every deposit.
     * @param amount The amount of kEther to be approved.
     */
    function approvekEtherToKeeperDaoPool(uint256 amount) external fundEnabled onlyRebalancer {
        KeeperDaoPoolController.approve(amount);
    }

    /**
     * @dev Mapping of bools indicating the presence of funds to pools.
     */
    mapping(uint8 => bool) _poolsWithFunds;

    /**
     * @dev Return a boolean indicating if the fund controller has funds in `currencyCode` in `pool`.
     * @param pool The index of the pool to check.
     */
    function hasETHInPool(uint8 pool) public view returns (bool) {
        return _poolsWithFunds[pool];
    }

    /**
     * @dev Referral code for Aave deposits.
     */
    uint16 _aaveReferralCode;

    /**
     * @dev Sets the referral code for Aave deposits.
     * @param referralCode The referral code.
     */
    function setAaveReferralCode(uint16 referralCode) external onlyOwner {
        _aaveReferralCode = referralCode;
    }

    /**
     * @dev The Enzyme pool Comptroller contract address.
     */
    address _enzymeComptroller;

    /**
     * @dev Sets the Enzyme pool Comptroller contract address.
     * @param comptroller The Enzyme pool Comptroller contract address.
     */
    function setEnzymeComptroller(address comptroller) external onlyOwner {
        _enzymeComptroller = comptroller;
    }

    /**
     * @dev Enum for pool allocation action types supported by Rari.
     */
    enum PoolAllocationAction { Deposit, Withdraw, WithdrawAll }

    /**
     * @dev Emitted when a deposit or withdrawal is made.
     * Note that `amount` is not set for `WithdrawAll` actions.
     */
    event PoolAllocation(PoolAllocationAction indexed action, LiquidityPool indexed pool, uint256 amount);

    /**
     * @dev Deposits funds to the specified pool.
     * @param pool The index of the pool.
     */
    function depositToPool(uint8 pool, uint256 amount) external fundEnabled onlyRebalancer {
        require(amount > 0, "Amount must be greater than 0.");
        if (pool == 0) DydxPoolController.deposit(amount);
        else if (pool == 1) CompoundPoolController.deposit(amount);
        else if (pool == 2) KeeperDaoPoolController.deposit(amount);
        else if (pool == 3) AavePoolController.deposit(amount, _aaveReferralCode);
        else if (pool == 4) AlphaPoolController.deposit(amount);
        else if (pool == 5) EnzymePoolController.deposit(_enzymeComptroller, amount);
        else revert("Invalid pool index.");
        _poolsWithFunds[pool] = true; 
        emit PoolAllocation(PoolAllocationAction.Deposit, LiquidityPool(pool), amount);
    }

    /**
     * @dev Internal function to withdraw funds from the specified pool.
     * @param pool The index of the pool.
     * @param amount The amount of tokens to be withdrawn.
     */
    function _withdrawFromPool(uint8 pool, uint256 amount) internal {
        if (pool == 0) DydxPoolController.withdraw(amount);
        else if (pool == 1) CompoundPoolController.withdraw(amount);
        else if (pool == 2) KeeperDaoPoolController.withdraw(amount);
        else if (pool == 3) AavePoolController.withdraw(amount);
        else if (pool == 4) AlphaPoolController.withdraw(amount);
        else if (pool == 5) EnzymePoolController.withdraw(_enzymeComptroller, amount);
        else revert("Invalid pool index.");
        emit PoolAllocation(PoolAllocationAction.Withdraw, LiquidityPool(pool), amount);
    }

    /**
     * @dev Withdraws funds from the specified pool.
     * @param pool The index of the pool.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdrawFromPool(uint8 pool, uint256 amount) external fundEnabled onlyRebalancer {
        require(amount > 0, "Amount must be greater than 0.");
        _withdrawFromPool(pool, amount);
        _poolsWithFunds[pool] = _getPoolBalance(pool) > 0;
    }

    /**
     * @dev Withdraws funds from the specified pool (caching the `initialBalance` parameter).
     * @param pool The index of the pool.
     * @param amount The amount of tokens to be withdrawn.
     * @param initialBalance The fund's balance of the specified currency in the specified pool before the withdrawal.
     */
    function withdrawFromPoolKnowingBalance(uint8 pool, uint256 amount, uint256 initialBalance) public fundEnabled onlyManager {
        _withdrawFromPool(pool, amount);
        if (amount == initialBalance) _poolsWithFunds[pool] = false;
    }

    /**
     * @dev Internal function that withdraws all funds from the specified pool.
     * @param pool The index of the pool.
     */
    function _withdrawAllFromPool(uint8 pool) internal {
        if (pool == 0) DydxPoolController.withdrawAll();
        else if (pool == 1) require(CompoundPoolController.withdrawAll(), "No Compound balance to withdraw from.");
        else if (pool == 2) require(KeeperDaoPoolController.withdrawAll(), "No KeeperDAO balance to withdraw from.");
        else if (pool == 3) AavePoolController.withdrawAll();
        else if (pool == 4) require(AlphaPoolController.withdrawAll(), "No Alpha Homora balance to withdraw from.");
        else if (pool == 5) EnzymePoolController.withdrawAll(_enzymeComptroller);
        else revert("Invalid pool index.");
        _poolsWithFunds[pool] = false;
        emit PoolAllocation(PoolAllocationAction.WithdrawAll, LiquidityPool(pool), 0);
    }

    /**
     * @dev Withdraws all funds from the specified pool.
     * @param pool The index of the pool.
     * @return Boolean indicating success.
     */
    function withdrawAllFromPool(uint8 pool) external fundEnabled onlyRebalancer {
        _withdrawAllFromPool(pool);
    }

    /**
     * @dev Withdraws all funds from the specified pool (without requiring the fund to be enabled).
     * @param pool The index of the pool.
     * @return Boolean indicating success.
     */
    function withdrawAllFromPoolOnUpgrade(uint8 pool) external onlyOwner {
        _withdrawAllFromPool(pool);
    }

    /**
     * @dev Withdraws ETH and sends amount to the manager.
     * @param amount Amount of ETH to withdraw.
     */
    function withdrawToManager(uint256 amount) external onlyManager {
        // Input validation
        require(amount > 0, "Withdrawal amount must be greater than 0.");

        // Check contract balance and withdraw from pools if necessary
        uint256 contractBalance = address(this).balance; // get ETH balance

        if (contractBalance < amount) {
            uint256 poolBalance = getPoolBalance(5);

            if (poolBalance > 0) {
                uint256 amountLeft = amount.sub(contractBalance);
                uint256 poolAmount = amountLeft < poolBalance ? amountLeft : poolBalance;
                withdrawFromPoolKnowingBalance(5, poolAmount, poolBalance);
                contractBalance = address(this).balance;
            }
        }

        for (uint256 i = 0; i < _supportedPools.length; i++) {
            if (contractBalance >= amount) break;
            uint8 pool = _supportedPools[i];
            if (pool == 5) continue;
            uint256 poolBalance = getPoolBalance(pool);
            if (poolBalance <= 0) continue;
            uint256 amountLeft = amount.sub(contractBalance);
            uint256 poolAmount = amountLeft < poolBalance ? amountLeft : poolBalance;
            withdrawFromPoolKnowingBalance(pool, poolAmount, poolBalance);
            contractBalance = contractBalance.add(poolAmount);
        }

        require(address(this).balance >= amount, "Too little ETH to transfer.");

        (bool success, ) = _rariFundManagerContract.call.value(amount)("");
        require(success, "Failed to transfer ETH to RariFundManager.");
    }

    /**
     * @dev Emitted when COMP is exchanged to ETH via 0x.
     */
    event CurrencyTrade(address inputErc20Contract, uint256 inputAmount, uint256 outputAmount);

    /**
     * @dev Approves tokens (COMP or ROOK) to 0x without spending gas on every deposit.
     * @param erc20Contract The ERC20 contract address of the token to be approved (must be COMP or ROOK).
     * @param amount The amount of tokens to be approved.
     */
    function approveTo0x(address erc20Contract, uint256 amount) external fundEnabled onlyRebalancer {
        require(erc20Contract == COMP_TOKEN || erc20Contract == ROOK_TOKEN, "Supplied token address is not COMP or ROOK.");
        ZeroExExchangeController.approve(erc20Contract, amount);
    }

    /**
     * @dev Market sell (COMP or ROOK) to 0x exchange orders (reverting if `takerAssetFillAmount` is not filled).
     * We should be able to make this function external and use calldata for all parameters, but Solidity does not support calldata structs (https://github.com/ethereum/solidity/issues/5479).
     * @param inputErc20Contract The input ERC20 token contract address (must be COMP or ROOK).
     * @param orders The limit orders to be filled in ascending order of price.
     * @param signatures The signatures for the orders.
     * @param takerAssetFillAmount The amount of the taker asset to sell (excluding taker fees).
     */
    function marketSell0xOrdersFillOrKill(address inputErc20Contract, LibOrder.Order[] memory orders, bytes[] memory signatures, uint256 takerAssetFillAmount) public payable fundEnabled onlyRebalancer {
        // Exchange COMP/ROOK to ETH
        uint256 ethBalanceBefore = address(this).balance;
        uint256[2] memory filledAmounts = ZeroExExchangeController.marketSellOrdersFillOrKill(orders, signatures, takerAssetFillAmount, msg.value);
        uint256 ethBalanceAfter = address(this).balance;
        emit CurrencyTrade(inputErc20Contract, filledAmounts[0], filledAmounts[1]);

        // Unwrap outputted WETH
        uint256 wethBalance = _weth.balanceOf(address(this));
        require(wethBalance > 0, "No WETH outputted.");
        _weth.withdraw(wethBalance);
        
        // Refund unspent ETH protocol fee
        uint256 refund = ethBalanceAfter.sub(ethBalanceBefore.sub(msg.value));

        if (refund > 0) {
            (bool success, ) = msg.sender.call.value(refund)("");
            require(success, "Failed to refund unspent ETH protocol fee.");
        }
    }

    /**
     * Unwraps all WETH currently owned by the fund controller.
     */
    function unwrapAllWeth() external fundEnabled onlyRebalancer {
        uint256 wethBalance = _weth.balanceOf(address(this));
        require(wethBalance > 0, "No WETH to withdraw.");
        _weth.withdraw(wethBalance);
    }

    /**
     * @notice Returns the fund controller's contract ETH balance and balance of each pool (checking `_poolsWithFunds` first to save gas).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getPoolBalance`) potentially modifies the state.
     * @return The fund controller ETH contract balance, an array of pool indexes, and an array of corresponding balances for each pool.
     */
    function getRawFundBalances() external returns (uint256, uint8[] memory, uint256[] memory) {
        uint8[] memory pools = new uint8[](_supportedPools.length);
        uint256[] memory poolBalances = new uint256[](_supportedPools.length);

        for (uint256 i = 0; i < _supportedPools.length; i++) {
            pools[i] = _supportedPools[i];
            poolBalances[i] = getPoolBalance(_supportedPools[i]);
        }

        return (address(this).balance, pools, poolBalances);
    }
}
