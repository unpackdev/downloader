// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ICorePool.sol";
import "./ICorePoolV1.sol";
import "./IERC20Upgradeable.sol";
import "./ErrorHandler.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";

/**
 * @title Illuvium Vault.
 *
 * @dev The Vault is responsible to gather revenue from the protocol, swap to ILV
 *      periodically and distribute to core pool users from time to time.
 * @dev The contract connects with Sushi's router in order to buy ILV from the
 *      ILV/ETH liquidity pool.
 * @dev Since we can change the vault address in the staking pools (see VaultRecipient),
 *      the Vault contract doesn't need to implement upgradeability.
 * @dev It receives ETH from the receive() function and allows conversion to ILV by
 *      the address with the role ROLE_VAULT_MANAGER (0x0001_0000). This conversion
 *      can be done in multiple steps, which means it doesn’t require converting
 *      all ETH balance in 1 function call. The vault is also responsible to be
 *      calling receiveVaultRewards() function in the core pools, which takes care
 *      of calculations of how much ILV should be sent to each pool as revenue distribution.
 * @notice The contract uses Ownable implementation, so only the eDAO is able to handle
 *         the ETH => ILV swaps and distribution schedules.
 *
 */
contract Vault is Ownable {
    using ErrorHandler for bytes4;

    /**
     * @dev Auxiliary data structure to store ILV, LP and Locked pools,
     *      linked to this smart contract and receiving vault rewards
     */
    struct Pools {
        ICorePool ilvPool;
        ICorePool pairPool;
        ICorePool lockedPoolV1;
    }

    /**
     * @dev struct with each core pool address
     */
    Pools public pools;

    /**
     * @dev Link to Sushiswap's router deployed instance
     */
    IUniswapV2Router02 private _sushiRouter;

    /**
     * @dev Link to IlluviumERC20 token deployed instance
     */
    IERC20Upgradeable private _ilv;

    /**
     * @dev Internal multiplier used to calculate amount to send
     *      to each staking pool
     */
    uint256 internal constant AMOUNT_TO_SEND_MULTIPLIER = 1e12;

    /**
     * @dev Fired in _swapEthForIlv() and sendIlvRewards() (via swapEthForIlv)
     *
     * @param by an address which executed the function
     * @param ethSpent ETH amount sent to Sushiswap
     * @param ilvReceived ILV amount received from Sushiswap
     */
    event LogSwapEthForILV(address indexed by, uint256 ethSpent, uint256 ilvReceived);

    /**
     * @dev Fired in sendIlvRewards()
     *
     * @param by an address which executed the function
     * @param value ILV amount sent to the pool
     */
    event LogSendILVRewards(address indexed by, uint256 value);

    /**
     * @dev Fired in default payable receive()
     *
     * @param by an address which sent ETH into the vault (this contract)
     * @param value ETH amount received
     */
    event LogEthReceived(address indexed by, uint256 value);

    /**
     * @dev Fired in setCorePools()
     *
     * @param by address who executed the setup
     * @param ilvPool deployed ILV core pool address
     * @param pairPool deployed ILV/ETH pair (LP) pool address
     * @param lockedPoolV1 deployed locked pool V1 address
     */
    event LogSetCorePools(address indexed by, address ilvPool, address pairPool, address lockedPoolV1);

    /**
     * @notice Creates (deploys) Vault linked to Sushi AMM Router and IlluviumERC20 token
     *
     * @param sushiRouter_ an address of the IUniswapV2Router02 to use for ETH -> ILV exchange
     * @param ilv_ an address of the IlluviumERC20 token to use
     */
    constructor(address sushiRouter_, address ilv_) {
        // we're using  a fake selector in the constructor to simplify
        // input and state validation
        bytes4 fnSelector = bytes4(0);

        // verify the inputs are set
        fnSelector.verifyNonZeroInput(uint160(sushiRouter_), 0);
        fnSelector.verifyNonZeroInput(uint160(ilv_), 1);

        // assign the values
        _sushiRouter = IUniswapV2Router02(sushiRouter_);
        _ilv = IERC20Upgradeable(ilv_);
    }

    /**
     * @dev Auxiliary function used as part of the contract setup process to setup core pools,
     *      executed by `owner()` after deployment
     *
     * @param _ilvPool deployed ILV core pool address
     * @param _pairPool deployed ILV/ETH pair (LP) pool address
     * @param _lockedPoolV1 deployed locked pool V1 address
     */
    function setCorePools(
        ICorePool _ilvPool,
        ICorePool _pairPool,
        ICorePool _lockedPoolV1
    ) external onlyOwner {
        bytes4 fnSelector = this.setCorePools.selector;

        // verify all the pools are set/supplied
        fnSelector.verifyNonZeroInput(uint160(address(_ilvPool)), 2);
        fnSelector.verifyNonZeroInput(uint160(address(_pairPool)), 3);
        fnSelector.verifyNonZeroInput(uint160(address(_lockedPoolV1)), 4);

        // set up
        pools.ilvPool = _ilvPool;
        pools.pairPool = _pairPool;
        pools.lockedPoolV1 = _lockedPoolV1;

        // emit an event
        emit LogSetCorePools(msg.sender, address(_ilvPool), address(_pairPool), address(_lockedPoolV1));
    }

    /**
     * @notice Exchanges ETH balance present on the contract into ILV via Sushiswap
     *
     * @dev Logs operation via `EthIlvSwapped` event
     *
     * @param _ilvOut expected ILV amount to be received from Sushiswap swap
     * @param _deadline maximum timestamp to wait for Sushiswap swap (inclusive)
     */
    function swapETHForILV(
        uint256 _ethIn,
        uint256 _ilvOut,
        uint256 _deadline
    ) external onlyOwner {
        _swapETHForILV(_ethIn, _ilvOut, _deadline);
    }

    /**
     * @notice Converts an entire contract's ETH balance into ILV via Sushiswap and
     *      sends the entire contract's ILV balance to the Illuvium Yield Pool
     *
     * @dev Uses `swapEthForIlv` internally to exchange ETH -> ILV
     *
     * @dev Logs operation via `RewardsDistributed` event
     *
     * @dev Set `ilvOut` or `deadline` to zero to skip `swapEthForIlv` call
     *
     * @param _ilvOut expected ILV amount to be received from Sushiswap swap
     * @param _deadline maximum timeout to wait for Sushiswap swap
     */
    function sendILVRewards(
        uint256 _ethIn,
        uint256 _ilvOut,
        uint256 _deadline
    ) external onlyOwner {
        // we treat set `ilvOut` and `deadline` as a flag to execute `swapEthForIlv`
        // in the same time we won't execute the swap if contract balance is zero
        if (_ilvOut > 0 && _deadline > 0 && address(this).balance > 0) {
            // exchange ETH on the contract's balance into ILV via Sushi - delegate to `swapEthForIlv`
            _swapETHForILV(_ethIn, _ilvOut, _deadline);
        }

        // reads core pools
        (ICorePool ilvPool, ICorePool pairPool, ICorePool lockedPoolV1) = (
            pools.ilvPool,
            pools.pairPool,
            pools.lockedPoolV1
        );

        // read contract's ILV balance
        uint256 ilvBalance = _ilv.balanceOf(address(this));
        // approve the entire ILV balance to be sent into the pool
        if (_ilv.allowance(address(this), address(ilvPool)) < ilvBalance) {
            _ilv.approve(address(ilvPool), ilvBalance);
        }
        if (_ilv.allowance(address(this), address(pairPool)) < ilvBalance) {
            _ilv.approve(address(pairPool), ilvBalance);
        }
        if (_ilv.allowance(address(this), address(lockedPoolV1)) < ilvBalance) {
            _ilv.approve(address(lockedPoolV1), ilvBalance);
        }

        // gets poolToken reserves in each pool
        uint256 reserve0 = ilvPool.getTotalReserves();
        uint256 reserve1 = estimatePairPoolReserve(address(pairPool));
        uint256 reserve2 = lockedPoolV1.poolTokenReserve();

        // ILV in ILV core pool + ILV in ILV/ETH core pool representation + ILV in locked pool
        uint256 totalReserve = reserve0 + reserve1 + reserve2;

        // amount of ILV to send to ILV core pool
        uint256 amountToSend0 = _getAmountToSend(ilvBalance, reserve0, totalReserve);
        // amount of ILV to send to ILV/ETH core pool
        uint256 amountToSend1 = _getAmountToSend(ilvBalance, reserve1, totalReserve);
        // amount of ILV to send to locked ILV pool V1
        uint256 amountToSend2 = _getAmountToSend(ilvBalance, reserve2, totalReserve);

        // makes sure we are sending a valid amount
        assert(amountToSend0 + amountToSend1 + amountToSend2 <= ilvBalance);

        // sends ILV to both core pools
        ilvPool.receiveVaultRewards(amountToSend0);
        pairPool.receiveVaultRewards(amountToSend1);
        lockedPoolV1.receiveVaultRewards(amountToSend2);

        // emit an event
        emit LogSendILVRewards(msg.sender, ilvBalance);
    }

    /**
     * @dev Auxiliary function used to estimate LP core pool share among the other core pools.
     *
     * @dev Expected to estimate how much ILV is represented by the number of LP tokens staked
     *      in the pair pool in order to determine how much revenue distribution should be allocated
     *      to the Sushi LP pool.
     *
     * @param _pairPool LP core pool extracted from pools structure (gas saving optimization)
     * @return ilvAmount ILV estimate of the LP pool share among the other pools
     */
    function estimatePairPoolReserve(address _pairPool) public view returns (uint256 ilvAmount) {
        // 1. Store the amount of LP tokens staked in the ILV/ETH pool
        //    and the LP token total supply (total amount of LP tokens in circulation).
        //    With these two values we will be able to estimate how much ILV each LP token
        //    is worth.
        uint256 lpAmount = ICorePool(_pairPool).getTotalReserves();
        uint256 lpTotal = IERC20Upgradeable(ICorePool(_pairPool).poolToken()).totalSupply();

        // 2. We check how much ILV the LP token contract holds, that way
        //    based on the total value of ILV tokens represented by the total
        //    supply of LP tokens, we are able to calculate through a simple rule
        //    of 3 how much ILV the amount of staked LP tokens represent.
        uint256 ilvTotal = _ilv.balanceOf(ICorePool(_pairPool).poolToken());
        // we store the result
        ilvAmount = (ilvTotal * lpAmount) / lpTotal;
    }

    /**
     * @dev Auxiliary function to calculate amount of rewards to send to the pool
     *      based on ILV rewards available to be split between the pools,
     *      particular pool reserve and total reserve of all the pools
     *
     * @dev A particular pool receives an amount proportional to its reserves
     *
     * @param _ilvBalance available amount of rewards to split between the pools
     * @param _poolReserve particular pool reserves
     * @param _totalReserve total cumulative reserves of all the pools to split rewards between
     */
    function _getAmountToSend(
        uint256 _ilvBalance,
        uint256 _poolReserve,
        uint256 _totalReserve
    ) private pure returns (uint256) {
        return (_ilvBalance * ((_poolReserve * AMOUNT_TO_SEND_MULTIPLIER) / _totalReserve)) / AMOUNT_TO_SEND_MULTIPLIER;
    }

    function _swapETHForILV(
        uint256 _ethIn,
        uint256 _ilvOut,
        uint256 _deadline
    ) private {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_swapETHForILV(uint256,uint256,uint256)"))`
        bytes4 fnSelector = 0x45b603e4;

        // verify the inputs
        fnSelector.verifyNonZeroInput(_ethIn, 0);
        fnSelector.verifyNonZeroInput(_ilvOut, 1);
        fnSelector.verifyInput(_deadline >= block.timestamp, 2);

        // checks if there's enough balance
        fnSelector.verifyState(address(this).balance > _ethIn, 3);

        // create and initialize path array to be used in Sushiswap
        // first element of the path determines an input token (what we send to Sushiswap),
        // last element determines output token (what we receive from uniwsap)
        address[] memory path = new address[](2);
        // we send ETH wrapped as WETH into Sushiswap
        path[0] = _sushiRouter.WETH();
        // we receive ILV from Sushiswap
        path[1] = address(_ilv);

        // exchange ETH -> ILV via Sushiswap
        uint256[] memory amounts = _sushiRouter.swapExactETHForTokens{ value: _ethIn }(
            _ilvOut,
            path,
            address(this),
            _deadline
        );
        // asserts that ILV amount bought wasn't invalid
        assert(amounts[1] > 0);

        // emit an event logging the operation
        emit LogSwapEthForILV(msg.sender, amounts[0], amounts[1]);
    }

    /**
     * @dev Overrides `Ownable.renounceOwnership()`, to avoid accidentally
     *      renouncing ownership of the Vault contract.
     */
    function renounceOwnership() public virtual override {}

    /**
     * @notice Default payable function, allows to top up contract's ETH balance
     *      to be exchanged into ILV via Sushiswap
     *
     * @dev Logs operation via `LogEthReceived` event
     */
    receive() external payable {
        // emit an event
        emit LogEthReceived(msg.sender, msg.value);
    }
}
