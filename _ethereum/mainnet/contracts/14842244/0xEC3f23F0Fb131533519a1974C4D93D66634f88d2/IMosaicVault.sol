// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of L1Vault.
 */
interface IMosaicVault {
    event TransferInitiated(
        address indexed owner,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 maxTransferDelay,
        address tokenOut,
        uint256 ammID,
        uint256 amountOutMin,
        bool _swapToNative
    );

    /**
     * @dev transfer ERC20 token to another Mosaic vault.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _remoteNetworkID  network ID of remote token
     * @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
     * @param _swapToNative true if a part will be swapped to native token in destination
     * @return transferId - transfer unique identifier
     */
    function transferERC20ToLayer(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId,
        uint256 _amountOutMin,
        bool _swapToNative
    ) external returns (bytes32 transferId);

    /**
     * @dev transfer ERC20 token to another Mosaic vault.
     * @param _remoteDestinationAddress address that will receive the transfer on destination
     * @param _remoteNetworkID destination network
     * @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
     * @param _tokenOut SC address of the ERC20 token that will be received in the destination network
     * @param _remoteAmmId id of the AMM that will be used in the destination network
     * @param _amountOutMin min amount of the token out the user expects to receive
     * @param _swapToNative true if a part will be swapped to native token in destination
     */

    function transferETHToLayer(
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId,
        uint256 _amountOutMin,
        bool _swapToNative
    ) external payable returns (bytes32 transferId);
}
