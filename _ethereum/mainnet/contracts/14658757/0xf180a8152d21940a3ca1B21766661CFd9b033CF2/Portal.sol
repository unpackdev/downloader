// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeERC20.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./IERC20Metadata.sol";

import "./IConfig.sol";
import "./IPortal.sol";
import "./IDex.sol";
import "./ISocketRegistry.sol";

contract Portal is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPortal
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using SafeERC20 for IERC20Metadata;

    IConfig public override config;
    IDex public override dex;

    function _initialize(IConfig c, IDex d) external initializer {
        require(address(c) != address(0), "PT1");
        config = c;
        dex = d;
        OwnableUpgradeable.__Ownable_init();
    }

    function setDex(IDex d) external onlyOwner() {
        dex = d;
    }

    // non payable as we only handle stablecoins
    // if swapRequest input token is present, swap from dex first, then the
    // bridge request amount will be overwritten by the amount received after the swap

    function outboundERC20TransferTo(
        ISocketRegistry.UserRequest memory request,
        IDex.SwapRequest calldata swapRequest,
        ISmartAccount.ExecuteParams calldata execParams,
        uint256 toAmount
    ) external override nonReentrant {
        require(request.receiverAddress != address(0), "PT2");
        require(request.toChainId != 0, "PT3");
        require(request.amount > 0, "PT4");
        if (address(swapRequest.inputToken) == address(0)) {
            IERC20MetadataUpgradeable(request.bridgeRequest.inputToken)
                .safeTransferFrom(msg.sender, address(this), request.amount);
        } else {
            swapRequest.inputToken.safeTransferFrom(msg.sender, address(this), swapRequest.inputAmount);
            (bool success, bytes memory result) = address(dex).delegatecall(abi.encodeWithSelector(dex.swap.selector, swapRequest));
            require(success, string(result));
            request.amount = abi.decode(result, (uint256));
        }

        ISocketRegistry socketReg = config.socketRegistry();

        ISocketRegistry.RouteData memory rdata = socketReg.routes(request.bridgeRequest.id);
        address approveAddr = rdata.route;
        IERC20MetadataUpgradeable(request.bridgeRequest.inputToken)
            .safeIncreaseAllowance(approveAddr, request.amount);

        // TODO check to make sure outboundTransferTo always reverts if outbound is not successful
        socketReg.outboundTransferTo(request);
        emit Outbound(
            request.toChainId,
            request.receiverAddress,
            request,
            swapRequest,
            execParams,
            toAmount
        );
    }
}
