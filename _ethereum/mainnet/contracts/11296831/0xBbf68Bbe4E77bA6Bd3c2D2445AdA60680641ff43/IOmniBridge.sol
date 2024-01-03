// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

interface IOmniBridge {
  /**
    @dev Initiate the bridge operation for some amount of tokens from msg.sender.
    The user should first call Approve method of the ERC677 token.
    @param token bridged token contract address.
    @param _receiver address that will receive the native tokens on the other network.
    @param _value amount of tokens to be transferred to the other network.
   */
  function relayTokens(
    address token,
    address _receiver,
    uint256 _value
  ) external;

  /**
    @dev Tells the expected token balance of the contract.
    @param _token address of token contract.
    @return the current tracked token balance of the contract.
   */
  function mediatorBalance(address _token) external view returns (uint256);
}
