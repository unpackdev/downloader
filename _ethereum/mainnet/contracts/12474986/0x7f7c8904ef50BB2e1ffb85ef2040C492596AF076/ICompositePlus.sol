// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IPlus.sol";

/**
 * @title Interface for composite plus token.
 * Composite plus is backed by a basket of plus with the same peg.
 */
interface ICompositePlus is IPlus {
    /**
     * @dev Returns the address of the underlying token.
     */
    function tokens(uint256 _index) external view returns (address);

    /**
     * @dev Returns the list of plus tokens.
     */
    function tokenList() external view returns (address[] memory);

    /**
     * @dev Checks whether a token is supported by the basket.
     */
    function tokenSupported(address _token) external view returns (bool);

    /**
     * @dev Returns the amount of composite plus tokens minted with the tokens provided.
     * @dev _tokens The tokens used to mint the composite plus token.
     * @dev _amounts Amount of tokens used to mint the composite plus token.
     */
    function getMintAmount(address[] calldata _tokens, uint256[] calldata _amounts) external view returns(uint256);

     /**
     * @dev Mints composite plus tokens with underlying tokens provided.
     * @dev _tokens The tokens used to mint the composite plus token. The composite plus token must have sufficient allownance on the token.
     * @dev _amounts Amount of tokens used to mint the composite plus token.
     */
    function mint(address[] calldata _tokens, uint256[] calldata _amounts) external;

    /**
     * @dev Returns the amount of tokens received in redeeming the composite plus token proportionally.
     * @param _amount Amounf of composite plus to redeem.
     * @return Addresses and amounts of tokens returned as well as fee collected.
     */
    function getRedeemAmount(uint256 _amount) external view returns (address[] memory, uint256[] memory, uint256);

    /**
     * @dev Redeems the composite plus token proportionally.
     * @param _amount Amount of composite plus token to redeem. -1 means redeeming all shares.
     */
    function redeem(uint256 _amount) external;

    /**
     * @dev Returns the amount of tokens received in redeeming the composite plus token to a single token.
     * @param _token Address of the token to redeem to.
     * @param _amount Amounf of composite plus to redeem.
     * @return Amount of token received and fee collected.
     */
    function getRedeemSingleAmount(address _token, uint256 _amount) external view returns (uint256, uint256);

    /**
     * @dev Redeems the composite plus token to a single token.
     * @param _token Address of the token to redeem to.
     * @param _amount Amount of composite plus token to redeem. -1 means redeeming all shares.
     */
    function redeemSingle(address _token, uint256 _amount) external;

    /**
     * @dev Rebalances the basket, e.g. for a better yield. Only strategist can perform rebalance.
     * @param _tokens Address of the tokens to withdraw from the basket.
     * @param _amounts Amounts of the tokens to withdraw from the basket.
     * @param _rebalancer Address of the rebalancer contract to invoke.
     * @param _data Data to invoke on rebalancer contract.
     */
    function rebalance(address[] calldata _tokens, uint256[] calldata _amounts, address _rebalancer, bytes calldata _data) external;
}