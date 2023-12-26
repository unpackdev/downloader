// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20Receiver {
    /**
     * @notice Handle the receipt of a ERC20 token(s)
     * @dev The ERC20 smart contract calls this function on the recipient
     *      after a successful transfer (`safeTransferFrom`).
     *      This function MAY throw to revert and reject the transfer.
     *      Return of other than the magic value MUST result in the transaction being reverted.
     * @notice The contract address is always the message sender.
     *      A wallet/broker/auction application MUST implement the wallet interface
     *      if it will accept safe transfers.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _value amount of tokens which is being transferred
     * @param _data additional data with no specified format
     * @return `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` unless throwing
     */
    function onERC20Received(
        address _operator,
        address _from,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);
}
