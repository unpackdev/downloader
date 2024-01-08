// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Equalizer Bridge smart contract.
 * Equalizer V1 bridge properties
 *   - Bridge for EQZ EIP-20 and BEP-20 tokens only
 *   - Swap between Ethereum (ETH) and Binance Smart Chain (BSC) blockchains
 *   - Min swap value: 100 EQZ
 *   - Max swap value: Amount available
 *   - Swap fee: 0.1%
 *   - Finality:
 *     - ETH: 7 blocks
 *     - BSC: 15 blocks (~75 sec.); https://docs.binance.org/smart-chain/guides/concepts/consensus.html#security-and-finality
 *   - Reference implementation: https://github.com/anyswap/mBTC/blob/master/contracts/ProxySwapAsset.sol
 * Important references:
 *   - https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
 *   - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
 */

/**
 * @title IBridgeV1 - Bridge V1 interface
 * @notice Interface for the Equalizer Bridge V1
 * @author Equalizer
 * @dev Equalizer bridge interface
 **/

interface IBridgeV1 {
    /**
     * @dev Initiates a token transfer from the given ledger to another Ethereum-compliant ledger.
     * @param amount The amount of tokens getting locked and swapped from the ledger
     * @param swapInAddress The address (on another ledger) to which the tokens are swapped
     */
    function SwapOut(uint256 amount, address swapInAddress)
    external
    returns (bool);

    /**
     * @dev Initiates a token transfer from the given ledger to another Ethereum-compliant ledger.
     * @param txHash Transaction hash on the ledger where the swap has beed initiated.
     * @param to The address to which the tokens are swapped
     * @param amount The amount of tokens released
     */
    function SwapIn(
        bytes32 txHash,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emits an event upon the swap out call.
     * @param swapOutAddress The address of the swap out initiator
     * @param swapInAddress The address (on another ledger) to which the tokens are swapped
     * @param amount The amount of tokens getting locked and swapped from the ledger
     */
    event LogSwapOut(
        address indexed swapOutAddress,
        address indexed swapInAddress,
        uint256 amount
    );

    /**
     * @dev Emits an event upon the swap in call.
     * @dev Initiates a token transfer from the given ledger to another Ethereum-compliant ledger.
     * @param txHash Transaction hash on the ledger where the swap has beed initiated.
     * @param swapInAddress The address to which the tokens are swapped
     * @param amountSent The amount of tokens released
     * @param fee The amount of tokens released
     */
    event LogSwapIn(
        bytes32 indexed txHash,
        address indexed swapInAddress,
        uint256 amountSent,
        uint256 fee
    );

    /**
     * @dev Emits an event upon changing fee in the contract
     * @dev Initiates a token transfer from the given ledger to another Ethereum-compliant ledger.
     * @param oldFee The fee before tx
     * @param newFee The new fee updated to
     */
    event LogFeeUpdate(
        uint256 oldFee,
        uint256 newFee
    );

    /**
     * @dev Emits an event upon changing fee in the contract
     * @dev Add liquidity to the bridge.
     * @param from who deposited
     * @param amount amount deposited
     */
    event LogLiquidityAdded(
        address from,
        uint256 amount
    );
}
