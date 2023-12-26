// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title IToken
 * @author fx(hash)
 * @notice Interface for minters to interact with tokens
 */
interface IToken {
    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints arbitrary number of tokens
     * @dev Only callable by registered minter contracts
     * @param _to Address receiving tokens
     * @param _amount Number of tokens being minted
     * @param _payment Total payment amount of the transaction
     */
    function mint(address _to, uint256 _amount, uint256 _payment) external;

    /**
     * @notice Returns address of primary receiver for token sales
     */
    function primaryReceiver() external view returns (address);
}
