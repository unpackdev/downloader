// contracts/Franklin.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IFranklinTokenWhitelist {
    function getApprovedTokens() external view returns (address[] memory);

    function isApprovedToken(address _token) external view returns (bool);

    /// ============ TOKEN MANAGEMENT FUNCTIONS ============

    /** @notice
      Adds the ERC20 token address to the registeredToken array and creates a
      mapping that returns a boolean showing the token is approved. */
    /// @dev This function is public because it is called by the initializer
    /// @param _token The ERC20 token to be approved
    function addApprovedToken(address _token) external;

    /** @notice
      Removes the ERC20 token from the registeredToken array and
      deletes the mapping used to confirm a token is approved */
    /// @param _token The ERC20 token to be removed
    function removeApprovedToken(address _token) external;
}
