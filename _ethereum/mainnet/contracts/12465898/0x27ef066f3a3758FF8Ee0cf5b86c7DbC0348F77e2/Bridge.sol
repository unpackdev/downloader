// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBridgeV1.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract Bridge is IBridgeV1, Ownable {

    using SafeMath for uint256;

    // token for the bridge
    address public token;

    // List of TXs from the other chain that were processed
    mapping (bytes32 => bool) txHashes;

    // Current Fee Rate

    uint public fee = 5 * 1e18;


    constructor(address _tokenAddress)  {
        token = _tokenAddress;
    }

    /**
     * @dev Initiates a token transfer from the given ledger to another Ethereum-compliant ledger.
     * @param amount The amount of tokens getting locked and swapped from the ledger
     * @param swapInAddress The address (on another ledger) to which the tokens are swapped
     */
    function SwapOut(uint256 amount, address swapInAddress)
    external
    override
    returns (bool) {
        require(swapInAddress != address(0), "Bridge: swapInAddress");
        require(amount > 0, "Bridge: amount");

        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Bridge: transfer"
        );
        emit LogSwapOut(msg.sender, swapInAddress, amount);
        return true;
    }

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
    )
    external
    override
    onlyOwner
    returns (bool) {
        require (txHash != bytes32(0), "Bridge: invalid tx");
        require (to != address(0), "Bridge: invalid addr");
        require (txHashes[txHash] == false, "Bridge: dup tx");
        txHashes[txHash] = true;
        require(
            IERC20(token).transfer(to, amount.sub(fee, "Bridge: invalid amount")), // automatically checks for amount > fee otherwise throw safemath
            "Bridge: transfer"
        );

        emit LogSwapIn(txHash, to, amount.sub(fee), fee);
        return true;
    }

    /**
     * @dev Initiates a withdrawal transfer from the bridge contract to an address. Only call-able by the owner
     * @param to The address to which the tokens are swapped
     * @param amount The amount of tokens released
     */
    function withdraw(address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /**
     * @dev Update the fee on the current chain. Only call-able by the owner
     * @param newFee uint - the new fee that applies to the current side bridge
     */
    function updateFee(uint newFee) external onlyOwner {
        uint oldFee = fee;
        fee = newFee;
        emit LogFeeUpdate(oldFee, newFee);
    }


    /**
     * @dev Add Liquidity to the Bridge contract
     * @param amount uint256 - the amount added to the liquidity in the bridge
     */
    function addLiquidity(uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit LogLiquidityAdded(msg.sender, amount);
    }


}
