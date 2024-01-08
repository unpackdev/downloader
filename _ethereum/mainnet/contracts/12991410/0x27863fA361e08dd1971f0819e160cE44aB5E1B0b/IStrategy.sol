// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IStrategy {

    /// @notice Returns the name of the strategy
    /// @dev The name is set when the strategy is deployed
    /// @return Returns the name of the strategy
    function getNameStrategy() external view returns (string memory);

    /// @notice Returns the want address of the strategy
    /// @dev The want is set when the strategy is deployed
    /// @return Returns the name of the strategy
    function want() external view returns (address);

    /// @notice Shows the balance of the strategy.
    function balanceOf() external view returns (uint256);

    /// @notice Transfers tokens for earnings
    function deposit() external;

    // NOTE: must exclude any tokens used in the yield
    /// @notice Controller role - withdraw should return to Controller
    function withdraw(address) external;

    /// @notice Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    /// @notice Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external;

    /// @notice Calls to the method to convert the required token to the want token
    function convert(address _token) external returns(uint256);

    function skim() external;
}
