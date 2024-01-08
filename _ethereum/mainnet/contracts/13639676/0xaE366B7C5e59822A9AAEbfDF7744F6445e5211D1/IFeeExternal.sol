//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IFeeExternal {
    /// @notice An event emitted once the external fee is modified
    event ExternalFeeSet(address account, uint256 newExternalFee);
    /// @notice An event emitted once a the external fee account is modified
    event ExternalFeeAddressSet(address account, address newExternalFeeAddress);

    /**
     *  @notice Construct a new FeeExternal contract
     *  @param _externalFee The initial external fee in ALBT tokens (flat)
     */
    function initFeeExternal(uint256 _externalFee, address _externalFeeAddress) external;
    function externalFee() external view returns (uint256);
    function externalFeeAddress() external view returns (address);
    function setExternalFee(uint256 _externalFee, bytes[] calldata _signatures) external;
    function setExternalFeeAddress(address _externalFeeAddress, bytes[] calldata _signatures) external;

}
