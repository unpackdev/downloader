// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./ISocketRegistry.sol";
import "./IConfig.sol";
import "./IDex.sol";
import "./ISmartAccount.sol";

interface IPortal {
    event Outbound(
        uint256 indexed toChainId,
        address indexed receiverAddress,
        ISocketRegistry.UserRequest request,
        IDex.SwapRequest swapRequest,
        ISmartAccount.ExecuteParams execParam,
        uint256 toAmount
    );

    function config() external view returns (IConfig);
    function dex() external view returns (IDex);

    function outboundERC20TransferTo(
        ISocketRegistry.UserRequest memory b,
        IDex.SwapRequest calldata swapRequest,
        ISmartAccount.ExecuteParams calldata execParams,
        uint256 toAmount
    ) external;
}
