// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


interface IRandomNumberConsumerV2 {

    /// @notice Acknowledge contract is `FragmentVRF`
    /// @return always true if the contract is in fact `FragmentVRF`
    function isVRFContract() external pure returns (bool);

    /// @notice Get random number based on VRF
    /// @return uint256 random number
    function getRandomWords(string memory _requestKey) external view returns (uint256[] memory);

    /// @notice Check VRF method has been run using '_requestkey'
    /// @return bool
    function hasRequestKey(string memory _requestKey) external view returns (bool);

    function getRequestId(string memory _requestKey) external view returns (uint256);

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}
