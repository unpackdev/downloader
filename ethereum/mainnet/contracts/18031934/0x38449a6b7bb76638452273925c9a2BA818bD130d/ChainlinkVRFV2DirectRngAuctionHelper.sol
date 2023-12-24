// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRngAuction.sol";
import "./ChainlinkVRFV2Direct.sol";
import "./IERC20.sol";
import "./VRFV2Wrapper.sol";

/// @notice Thrown if the ChainlinkVRFV2Direct contract is set to the zero address.
error ChainlinkVRFV2DirectZeroAddress();

/// @notice Thrown if the RngAuction contract is set to the zero address.
error RngAuctionZeroAddress();

/**
 * @notice Thrown if the active RNG service of the RngAuction doesn't match the address of
 * the ChainlinkVRFV2Direct contract.
 * @param chainlinkVrfV2Direct The ChainlinkVRFV2Direct contract address
 * @param activeRngService The active RNG service of the RngAuction
 */
error RngServiceNotActive(address chainlinkVrfV2Direct, address activeRngService);

/**
 * @title PoolTogether V5 ChainlinkVRFV2DirectRngAuctionHelper
 * @author Generation Software Team
 * @notice This is a helper contract to provide clients a simplified interface to interact
 * with the RNGAuction if a fee needs to be transferred before starting the RNG request.
 */
contract ChainlinkVRFV2DirectRngAuctionHelper {

    /// @notice The ChainlinkVRFV2Direct contract that the fee will be transferred to.
    ChainlinkVRFV2Direct public immutable chainlinkVrfV2Direct;

    /// @notice The RngAuction that will be completed after the fee is transferred.
    IRngAuction public immutable rngAuction;

    /**
     * @notice Initializes the contract with the target ChainlinkVRFV2Direct and RngAuction
     * contracts.
     * @param _chainlinkVrfV2Direct The ChainlinkVRFV2Direct contract that the fee will be transferred to.
     * @param _rngAuction The RngAuction contract that will be completed after the fee is transferred.
     */
    constructor (ChainlinkVRFV2Direct _chainlinkVrfV2Direct, IRngAuction _rngAuction) {
        if (address(_chainlinkVrfV2Direct) == address(0)) revert ChainlinkVRFV2DirectZeroAddress();
        if (address(_rngAuction) == address(0)) revert RngAuctionZeroAddress();
        chainlinkVrfV2Direct = _chainlinkVrfV2Direct;
        rngAuction = _rngAuction;
    }

    /**
     * @notice Transfers the RNG fee from the caller to the ChainlinkVRFV2Direct contract before
     * completing the RNG auction by starting the RNG request.
     * @dev Will revert if the active RNG service of the RngAuction does not match the ChainlinkVRFV2Direct
     * contract address.
     * @dev To estimate the request fee, use the `estimateRequestFee(...)` function on this contract.
     * @dev DO NOT USE THE `getRequestFee()` FUNCTION ON THE RNG SERVICE TO PREDICT THE FEE AS IT REQUIRES A
     * TX GAS PRICE TO CALCULATE THE CORRECT VALUE!
     * @param _rewardRecipient Address that will receive the auction reward for starting the RNG request
     */
    function transferFeeAndStartRngRequest(address _rewardRecipient) external {
        if (address(rngAuction.getNextRngService()) != address(chainlinkVrfV2Direct)) {
            revert RngServiceNotActive(address(chainlinkVrfV2Direct), address(rngAuction.getNextRngService()));
        }
        (address _feeToken, uint256 _requestFee) = chainlinkVrfV2Direct.getRequestFee();
        IERC20(_feeToken).transferFrom(msg.sender, address(chainlinkVrfV2Direct), _requestFee);
        rngAuction.startRngRequest(_rewardRecipient);
    }

    /**
     * @notice Estimates the RNG request fee in LINK based on the expected gas price.
     * @dev Use this function instead of `RNGInterface.getRequestFee()` when estimating request fees offchain.
     * @param _gasPrice The gas price to calculate the request fee for
     * @return _feeToken The LINK address
     * @return _requestFee The estimated request fee based on the given gas price
     */
    function estimateRequestFee(uint256 _gasPrice) external view returns (address _feeToken, uint256 _requestFee) {
        VRFV2Wrapper wrapper = chainlinkVrfV2Direct.vrfV2Wrapper();
        _feeToken = address(wrapper.LINK());
        _requestFee = wrapper.estimateRequestPrice(chainlinkVrfV2Direct.getCallbackGasLimit(), _gasPrice);
    }

}