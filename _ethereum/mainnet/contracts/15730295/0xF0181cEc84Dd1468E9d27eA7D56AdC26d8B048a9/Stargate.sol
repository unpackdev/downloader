// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

import "./IToken.sol";
import "./IRouter.sol";

contract StarGate {
    IStargateRouter public immutable router;
    uint8 constant TYPE_SWAP_REMOTE = 1;
    uint16 public immutable chainId;

    event ReceivedOnDestination(address token, address to, uint256 amount, uint16 srcChainId, uint16 dstChainId);

    constructor(IStargateRouter _router, uint16 _chainId) {
        router = _router;
        chainId = _chainId;
    }

    function getSwapFee(
        uint16 dstChainId,
        bytes calldata toAddress,
        IStargateRouter.lzTxObj memory lzTxParams
    ) external view returns (uint256, uint256) {
        return
            router.quoteLayerZeroFee(
                dstChainId,
                TYPE_SWAP_REMOTE, /* for Swap */
                toAddress,
                "",
                lzTxParams
            );
    }

    function processSwap(
        uint256 qty,
        address bridgeToken,
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address to,
        address dstStargateComposed
    ) external payable {
        bytes memory data = abi.encode(to, chainId, dstChainId, srcPoolId, dstPoolId);

        IERC20(bridgeToken).transferFrom(msg.sender, address(this), qty);
        IERC20(bridgeToken).approve(address(router), qty);

        router.swap{ value: msg.value }(
            dstChainId,
            srcPoolId,
            dstPoolId,
            payable(msg.sender),
            qty,
            0,
            IStargateRouter.lzTxObj(200000, 0, "0x"),
            abi.encodePacked(dstStargateComposed),
            data
        );
    }

    function processReceive(
        address _token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory _payload
    ) external {
        require(msg.sender == address(router), "only stargate router can call sgReceive!");
        (address _toAddr, uint16 srcChainId, uint16 dstChainId, , ) = abi.decode(
            _payload,
            (address, uint16, uint16, uint256, uint256)
        );

        IERC20(_token).approve(_toAddr, amountLD);
        IERC20(_token).transfer(_toAddr, amountLD);

        emit ReceivedOnDestination(_token, _toAddr, amountLD, srcChainId, dstChainId);
    }
}
