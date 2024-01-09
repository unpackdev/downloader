//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IBridgeInbound.sol";
import "./IBridgeOutbound.sol";
import "./IMintableBurnableERC20.sol";
import "./IRegistry.sol";
import "./IFederation.sol";
import "./Utils.sol";

contract Bridge is
    IBridgeInbound,
    IBridgeOutbound,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable {
    using Utils for *;
    using SafeERC20Upgradeable for IMintableBurnableERC20;
    using AddressUpgradeable for address;

    IRegistry public tokenRegistry;
    IFederation public override federation;

    mapping(bytes32 => uint256) public override processed;

    function initialize(address tokenRegistry_) public initializer {
        PausableUpgradeable.__Pausable_init();
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        tokenRegistry = IRegistry(tokenRegistry_);
    }

    function setFederation(address federation_) external onlyOwner {
        require(federation_.isContract(), "input not contract addr");
        federation = IFederation(federation_);
    }

    function isTransferProcessed(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external view override returns(bool) {
        return processed[Utils.getTransferId(
            srcChainID_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            receiver_,
            amount_,
            transactionHash_,
            logIndex_
        )] > 0;
    }
    // function isCallProcessed(
    //     uint256 srcChainID_,
    //     address srcChainTokenAddress_,
    //     address dstChainTokenAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external view override returns(bool) {
    //     return processed[Utils.getCallId(
    //         srcChainID_,
    //         srcChainTokenAddress_,
    //         dstChainTokenAddress_,
    //         transactionHash_,
    //         logIndex_,
    //         payload
    //     )] > 0;
    // }

    function acceptTransfer(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external override onlyFederation {
        require(dstChainTokenAddress_ != address(0), "Bridge: destination chain token address is null");
        require(srcChainTokenAddress_ != address(0), "Bridge: src chain token address is null");
        require(receiver_ != address(0), "Bridge: Receiver is null");
        require(amount_ > 0, "Bridge: Amount 0");
        require(transactionHash_ != bytes32(0), "Bridge: Transaction is null");
        require(srcChainTokenAddress_ != address(0), "src token address is null");
        require(tokenRegistry.tokenRegistry(dstChainTokenAddress_, srcChainID_) == srcChainTokenAddress_, "Token Not Registered");
        bytes32 processId = Utils.getTransferId(
            srcChainID_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            receiver_,
            amount_,
            transactionHash_,
            logIndex_
        );
        require(processed[processId] == 0, "Bridge: Already processed");
        processed[processId] = block.number;
        IMintableBurnableERC20(dstChainTokenAddress_).mint(receiver_, amount_);
        emit TransferAccepted(
            srcChainID_,
            transactionHash_,
            receiver_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            amount_,
            logIndex_
        );
    }

    // function acceptCall(
    //     uint256 srcChainID_,
    //     address srcChainTokenAddress_,
    //     address dstChainTokenAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external override onlyFederation nonReentrant {
    //     require(dstChainTokenAddress_ != address(0), "Bridge: destination chain token address is null");
    //     require(srcChainTokenAddress_ != address(0), "Bridge: src chain token address is null");
    //     require(transactionHash_ != bytes32(0), "Bridge: Transaction is null");
    //     require(srcChainTokenAddress_ != address(0), "src token address is null");
    //     bytes4 sig =
    //         payload[0] |
    //         (bytes4(payload[1]) >> 8) |
    //         (bytes4(payload[2]) >> 16) |
    //         (bytes4(payload[3]) >> 24);

    //     bytes32 callRegistryID = Utils.getCallRegistryId(
    //         srcChainID_,
    //         srcChainTokenAddress_,
    //         dstChainTokenAddress_,
    //         sig
    //     );
    //     require(tokenRegistry.callRegistry(callRegistryID), "Call Not Registered");
    //     bytes32 callId = Utils.getCallId(
    //         srcChainID_,
    //         srcChainTokenAddress_,
    //         dstChainTokenAddress_,
    //         transactionHash_,
    //         logIndex_,
    //         payload
    //     );

    //     require(processed[callId] == 0, "Bridge: Already processed");
    //     processed[callId] = block.number;

    //     // call the function
    //     (bool success, ) = dstChainTokenAddress_.call(payload);
    //     require(success, "call fail");
    // }

    function bridgeTokenAt(
        uint256 dstChainId_,
        address srcChainTokenAddr_,
        uint256 amount_,
        address dstChainReceiverAddr_
    ) external override whenNotPaused nonReentrant {
        _bridgeToken(
            srcChainTokenAddr_,
            dstChainId_,
            amount_,
            dstChainReceiverAddr_
        );
    }

    function bridgeToken(
        uint256 dstChainId_,
        address srcChainTokenAddr_,
        uint256 amount_
    ) external override whenNotPaused nonReentrant {

        _bridgeToken(
            srcChainTokenAddr_,
            dstChainId_,
            amount_,
            _msgSender()
        );
    }

    function _bridgeToken(
        address srcChainTokenAddr_,
        uint256 dstChainId_,
        uint256 amount_,
        address dstChainReceiverAddr_
    ) internal {
        address dstChainTokenAddr_ = tokenRegistry.tokenRegistry(srcChainTokenAddr_, dstChainId_);
        require(dstChainTokenAddr_ != address(0), "Token Not Registered");
        //Transfer the tokens on IERC20, they should be already Approved for the bridge Address to use them
        IMintableBurnableERC20(srcChainTokenAddr_).safeTransferFrom(
            _msgSender(),
            address(this),
            amount_
        );
        _crossTokens(
            srcChainTokenAddr_,
            dstChainId_,
            dstChainTokenAddr_,
            dstChainReceiverAddr_,
            amount_
        );
    }

    function _crossTokens(
        address srcChainTokenAddr_,
        uint256 dstChainId_,
        address dstChainTokenAddr_,
        address dstChainReceiverAddr_,
        uint256 amount_
    ) internal {
        IMintableBurnableERC20 localToken = IMintableBurnableERC20(srcChainTokenAddr_);
        uint256 fee = _calculateFee(srcChainTokenAddr_, amount_);
        if (fee > 0) {
            localToken.safeTransfer(owner(), fee);
        }
        uint256 amountToCross = amount_ - fee;
        localToken.burn(address(this), amountToCross);
        emit Cross(
            _msgSender(),
            srcChainTokenAddr_,
            dstChainId_,
            dstChainTokenAddr_,
            dstChainReceiverAddr_,
            amountToCross,
            fee
        );
    }

    function _calculateFee(address srcChainTokenAddr_, uint256 amount_) internal view returns(uint256) {
        uint256 feeIn18 = tokenRegistry.fee(srcChainTokenAddr_);
        return amount_ * feeIn18 / 1e18;
    }

    modifier onlyFederation() {
        require(msg.sender == address(federation), "Bridge: Sender not Federation");
        _;
    }
}

