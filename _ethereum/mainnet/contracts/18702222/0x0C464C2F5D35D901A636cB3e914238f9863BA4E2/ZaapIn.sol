// SPDX-License-Identifier: UNLICENSED
// Zaap.exchange Contracts (ZaapIn.sol)
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./Pausable.sol";

import "./NativeWrapper.sol";
import "./Swapper.sol";

import "./IWETH9.sol";
import "./IStargateRouter.sol";
import "./IPermit2.sol";
import "./IAllowanceTransfer.sol";

import "./TransferHelper.sol";

abstract contract ZaapIn is Ownable, Pausable, NativeWrapper, Swapper {
    IStargateRouter public immutable stargateRouter;
    IPermit2 public immutable permit2;

    address public treasuryAddress;
    uint8 public feeBps;

    struct PartnerConfig {
        address partnerAddress;
        uint8 percentShare;
    }
    mapping(string => PartnerConfig) private partnerIdToPartnerConfig;

    event ZaapedIn(
        address srcSenderAddress,
        address indexed srcTokenAddress,
        uint srcTokenAmountIn,
        uint16 srcPoolId,
        address indexed bridgeTokenAddress,
        uint256 bridgeAmount,
        uint16 dstChainId,
        uint16 dstPoolId,
        address dstZaapAddress,
        address indexed dstTokenAddress,
        address dstRecipientAddress,
        string partnerId
    );

    constructor(IStargateRouter stargateRouter_, IPermit2 permit2_) {
        stargateRouter = stargateRouter_;
        permit2 = permit2_;
    }

    function swap(
        address srcTokenAddress,
        uint160 srcTokenAmountIn,
        SwapParams[] calldata srcSwapsParams,
        uint16 srcPoolId,
        address bridgeTokenAddress,
        uint256 bridgeAmountOutMin,
        uint16 dstChainId,
        uint16 dstPoolId,
        address dstZaapAddress,
        address dstTokenAddress,
        SwapParams[] calldata dstSwapsParams,
        address dstRecipientAddress,
        IAllowanceTransfer.PermitSingle calldata permitSingle,
        bytes calldata signature,
        IStargateRouter.lzTxObj calldata lzTxObj,
        uint256 deadline,
        string calldata partnerId
    ) external payable whenNotPaused {
        require(srcTokenAmountIn > 0, "ZaapIn: `srcTokenAmountIn` must be > 0");
        if (deadline > 0) {
            require(deadline >= block.timestamp, "ZaapIn: `deadline` must be >= block.timestamp");
        }

        bool srcTokenIsNative = srcTokenAddress == NATIVE_TOKEN_ADDRESS;

        if (!srcTokenIsNative && permitSingle.spender == address(this)) {
            permit2.permit(msg.sender, permitSingle, signature);
        }
        if (!srcTokenIsNative) {
            permit2.transferFrom(msg.sender, address(this), srcTokenAmountIn, srcTokenAddress);
        }

        uint256 bridgeAmount = 0;
        if (srcTokenAddress != bridgeTokenAddress) {
            require(srcSwapsParams.length > 0, "ZaapIn: `srcSwapsParams` must not be empty if `srcTokenAddress` != `bridgeTokenAddress`");

            // Wrapping if needed
            if (srcTokenIsNative) {
                require(msg.value >= srcTokenAmountIn, "ZaapIn: `msg.value` must be >= `srcTokenAmountIn`");
                wETH9.deposit{ value: srcTokenAmountIn }();
            }

            (uint256 totalAmountOut, bool errored) = _swapExact(
                srcTokenAmountIn,
                srcSwapsParams,
                srcTokenIsNative ? address(wETH9) : srcTokenAddress,
                bridgeTokenAddress,
                true
            );
            bridgeAmount = totalAmountOut;
        } else {
            bridgeAmount = srcTokenAmountIn;
        }

        if (feeBps > 0 && treasuryAddress != address(0)) {
            uint256 feeAmount = (bridgeAmount / 10000) * feeBps;
            bridgeAmount -= feeAmount;

            if (bytes(partnerId).length > 0) {
                PartnerConfig memory partnerConfig = partnerIdToPartnerConfig[partnerId];
                if (partnerConfig.partnerAddress != address(0) && partnerConfig.percentShare > 0 && partnerConfig.percentShare <= 100) {
                    uint256 partnerFeeAmount = (feeAmount / 100) * partnerConfig.percentShare;
                    feeAmount -= partnerFeeAmount;
                    TransferHelper.safeTransfer(bridgeTokenAddress, partnerConfig.partnerAddress, partnerFeeAmount);
                }
            }
            if (feeAmount > 0) {
                TransferHelper.safeTransfer(bridgeTokenAddress, treasuryAddress, feeAmount);
            }
        }

        TransferHelper.safeApprove(bridgeTokenAddress, address(stargateRouter), bridgeAmount);

        stargateRouter.swap{ value: srcTokenIsNative ? msg.value - srcTokenAmountIn : msg.value }(
            dstChainId,
            srcPoolId,
            dstPoolId,
            payable(msg.sender),
            bridgeAmount,
            bridgeAmountOutMin,
            lzTxObj,
            abi.encodePacked(dstZaapAddress),
            abi.encode(dstSwapsParams, dstTokenAddress, dstRecipientAddress)
        );

        emit ZaapedIn(
            msg.sender,
            srcTokenAddress,
            srcTokenAmountIn,
            srcPoolId,
            bridgeTokenAddress,
            bridgeAmount,
            dstChainId,
            dstPoolId,
            dstZaapAddress,
            dstTokenAddress,
            dstRecipientAddress,
            partnerId
        );
    }

    function setTreasuryAddress(address treasuryAddress_) external onlyOwner {
        treasuryAddress = treasuryAddress_;
    }

    function setFeeBps(uint8 feeBps_) external onlyOwner {
        require(feeBps_ <= 50, "ZaapIn: `feeBps_` must be <= 50");
        feeBps = feeBps_;
    }

    function setPartnerConfigBatch(string[] calldata partnerIds, address[] calldata partnerAddresses, uint8[] calldata percentShares) external onlyOwner {
        require(
            partnerIds.length == partnerAddresses.length && partnerAddresses.length == percentShares.length,
            "ZaapIn: `partnerIds`, `partnerAddresses` and `percentShares` must have the same length"
        );
        for (uint256 i = 0; i < partnerIds.length; i++) {
            setPartnerConfig(partnerIds[i], partnerAddresses[i], percentShares[i]);
        }
    }

    function setPartnerConfig(string calldata partnerId, address partnerAddress, uint8 percentShare) public onlyOwner {
        require(bytes(partnerId).length > 0, "ZaapIn: `partnerId` must not be empty");
        require(partnerAddress != address(0), "ZaapIn: `partnerAddress` must not be address(0)");
        require(percentShare <= 100, "ZaapIn: `percentShare` must be <= 100");
        partnerIdToPartnerConfig[partnerId] = PartnerConfig(partnerAddress, percentShare);
    }

    function deletePartnerConfig(string calldata partnerId) external onlyOwner {
        require(bytes(partnerId).length > 0, "ZaapIn: `partnerId` must not be empty");
        delete partnerIdToPartnerConfig[partnerId];
    }

    function pauseIn() external virtual onlyOwner {
        _pause();
    }

    function unpauseIn() external virtual onlyOwner {
        _unpause();
    }
}
