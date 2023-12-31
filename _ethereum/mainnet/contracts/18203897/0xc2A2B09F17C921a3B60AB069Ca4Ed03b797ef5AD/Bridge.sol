// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./NonblockingLzApp.sol";
import "./Router.sol";
import "./INonceContract.sol";

contract Bridge is Initializable, NonblockingLzApp, ReentrancyGuardUpgradeable {
    Router public router;

    mapping(uint16 => uint256) public fees;
    INonceContract public nonceContract;

    //-------------------------------------EVENTS--------------------------------------
    event TransferToken(
        uint64 indexed sequence,
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address sender,
        address recipient,
        uint256 amount
    );

    event ReceiveToken(
        uint64 indexed sequence,
        uint16 sourceChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address recipient,
        uint256 amount
    );

    event NewBridge(uint16 chainId, address bridge);

    event NewFees(uint16 chainId, uint256 fees);

    event ClaimedFees(address to, uint256 amount);

    //--------------------------------------MODIFIERS-------------------------------------
    modifier onlyRouter() {
        require(msg.sender == address(router), "Bridge: caller must be Router.");
        _;
    }

    /**
     * @dev Initialize pool contract function.
     */
    function initialize(address payable router_, address lzEndpoint_, address nonceContract_) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        require(router_ != address(0), "Bridge: Router cannot be zero address");
        require(lzEndpoint_ != address(0), "Bridge: LzEndpoint cannot be zero address");

        router = Router(router_);
        lzEndpoint = ILayerZeroEndpoint(lzEndpoint_);
        _setNonceContract(nonceContract_);
    }

    function send(
        uint16 dstChainId_,
        uint256 srcPoolId_,
        uint256 dstPoolId_,
        uint256 amount_,
        address sender_,
        address recipient_,
        bytes calldata adapterParams_
    ) external payable nonReentrant onlyRouter {
        require(
            msg.value >= _estimateFee(dstChainId_, srcPoolId_, dstPoolId_, amount_, recipient_, adapterParams_),
            "Bridge: Insufficient Fee"
        );
        bytes memory payload = abi.encode(srcPoolId_, dstPoolId_, amount_, recipient_);

        uint256 lzFee = msg.value - fees[dstChainId_];
        _lzSend(dstChainId_, payload, payable(sender_), address(0), adapterParams_, lzFee);

        uint64 sequence = nonceContract.outboundNonce(dstChainId_, trustedRemoteLookup[dstChainId_]);

        emit TransferToken(sequence, dstChainId_, srcPoolId_, dstPoolId_, sender_, recipient_, amount_);
    }

    function estimateFee(
        uint16 dstChainId_,
        uint256 srcPoolId_,
        uint256 dstPoolId_,
        uint256 amount_,
        address recipient_,
        bytes calldata adapterParams_
    ) external view returns (uint256) {
        return _estimateFee(dstChainId_, srcPoolId_, dstPoolId_, amount_, recipient_, adapterParams_);
    }

    function _nonblockingLzReceive(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 sequence_,
        bytes memory payload_
    ) internal override {
        (uint256 srcPoolId, uint256 dstPoolId, uint256 amount, address recipient) =
            abi.decode(payload_, (uint256, uint256, uint256, address));

        router.withdraw(srcChainId_, dstPoolId, srcPoolId, amount, recipient);

        emit ReceiveToken(sequence_, srcChainId_, srcPoolId, dstPoolId, recipient, amount);
    }

    function _estimateFee(
        uint16 dstChainId_,
        uint256 srcPoolId_,
        uint256 dstPoolId_,
        uint256 amount_,
        address recipient_,
        bytes calldata adapterParams_
    ) internal view returns (uint256) {
        bytes memory payload = abi.encode(srcPoolId_, dstPoolId_, amount_, recipient_);
        (uint256 fee,) = lzEndpoint.estimateFees(dstChainId_, address(this), payload, false, adapterParams_);
        return fees[dstChainId_] + fee;
    }

    function setFee(uint16 chainId_, uint256 fee_) external onlyOwner {
        require(chainId_ > 0, "Bridge: Invalid chainid");
        fees[chainId_] = fee_;

        emit NewFees(chainId_, fee_);
    }

    function claimFees(address to_) external onlyOwner {
        require(to_ != address(0), "Bridge: Cannot be zero address");
        require(address(this).balance > 0, "Bridge: Insufficient Balance");

        emit ClaimedFees(to_, address(this).balance);

        payable(to_).transfer(address(this).balance);
    }

    function setRouter(address payable router_) external onlyOwner {
        router = Router(router_);
    }

    function _setNonceContract(address nonceContract_) internal {
        require(address(nonceContract_) != address(0), "Bridge: NonceContract cannot be zero address");
        nonceContract = INonceContract(nonceContract_);
    }

    receive() external payable {}
}
