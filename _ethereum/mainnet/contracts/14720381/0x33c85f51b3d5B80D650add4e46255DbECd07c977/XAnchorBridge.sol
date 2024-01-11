//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./BytesLib.sol";
import "./console.sol";

interface WormholeCoreBridge {
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }

    function parseAndVerifyVM(bytes calldata encodedVM)
        external
        view
        returns (
            VM memory vm,
            bool valid,
            string memory reason
        );
}

interface WormholeTokenBridge {
    struct Transfer {
        // PayloadID uint8 = 1
        uint8 payloadID;
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 to;
        // Chain ID of the recipient
        uint16 toChain;
        // Amount of tokens (big-endian uint256) that the user is willing to pay as relayer fee. Must be <= Amount.
        uint256 fee;
    }

    function transferTokens(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint256 arbiterFee,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function parseTransfer(bytes memory encoded)
        external
        pure
        returns (Transfer memory transfer);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function completeTransfer(bytes memory encodedVm) external;

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress)
        external
        view
        returns (address);

    function chainId() external view returns (uint16);
}

contract XAnchorBridge is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    uint16 private constant TERRA_CHAIN_ID = 3;

    uint8 private constant FLAG_INCOMING_TRANSFER = 0x80; // 1000 0000
    uint8 private constant FLAG_OUTGOING_TRANSFER = 0x40; // 0100 0000
    uint8 private constant FLAG_BOTH_TRANSFERS = 0xC0; // 1100 0000
    uint8 private constant FLAG_NO_ASSC_TRANSFER = 0x00; // 0000 0000

    uint8 private constant OP_CODE_DEPOSIT_STABLE = 0 | FLAG_BOTH_TRANSFERS;
    uint8 private constant OP_CODE_REDEEM_STABLE = 1 | FLAG_BOTH_TRANSFERS;
    uint8 private constant OP_CODE_LOCK_AND_BORROW = 2 | FLAG_BOTH_TRANSFERS;

    uint8 private constant OP_CODE_REPAY_STABLE = 0 | FLAG_INCOMING_TRANSFER;
    uint8 private constant OP_CODE_LOCK_COLLATERAL = 1 | FLAG_INCOMING_TRANSFER;

    uint8 private constant OP_CODE_UNLOCK_COLLATERAL = 0 | FLAG_OUTGOING_TRANSFER;
    uint8 private constant OP_CODE_BORROW_STABLE = 1 | FLAG_OUTGOING_TRANSFER;
    uint8 private constant OP_CODE_CLAIM_REWARDS = 2 | FLAG_OUTGOING_TRANSFER;
    uint8 private constant OP_CODE_WITHDRAW_ASSET = 3 | FLAG_OUTGOING_TRANSFER;
    uint8 private constant CONSISTENCY_EVM = 15;

    uint32 private constant INSTRUCTION_NONCE = 1324532;
    uint32 private constant TOKEN_TRANSFER_NONCE = 15971121;

    uint8 private CONSISTENCY_LEVEL;
    address private WORMHOLE_CORE_BRIDGE;
    address private WORMHOLE_TOKEN_BRIDGE;
    bytes32 private TERRA_ANCHOR_BRIDGE_ADDRESS;

    // Wormhole-wrapped Terra stablecoin tokens that are whitelisted in Terra Anchor Market. Example: UST.
    mapping(address => bool) public whitelistedStableTokens;
    // Wormhole-wrapped Terra Anchor yield-generating tokens that can be redeemed for Terra stablecoins. Example: aUST.
    mapping(address => bool) public whitelistedAnchorStableTokens;
    // Wormhole-wrapped Terra cw20 tokens that can be used as collateral in Anchor. Examples: bLUNA, bETH.
    mapping(address => bool) public whitelistedCollateralTokens;

    // Stores hashes of completed incoming token transfer.
    mapping(bytes32 => bool) public completedTokenTransfers;

    uint256 private aUSTExchangeRate;
    uint32 private exchangeRateTimestamp;

    function initialize(
        address _wormholeCoreBridge,
        address _wormholeTokenBridge,
        bytes32 _terraAnchorBridgeAddress
    ) public initializer {
        console.log("Starting eth xanchor initialization...");
        __Ownable_init();
        __UUPSUpgradeable_init();
        WORMHOLE_CORE_BRIDGE = _wormholeCoreBridge;
        WORMHOLE_TOKEN_BRIDGE = _wormholeTokenBridge;
        TERRA_ANCHOR_BRIDGE_ADDRESS = _terraAnchorBridgeAddress;
        console.log("Complete eth xanchor initialization...");
    }

    function isTransferCompleted(bytes32 hash) public view returns (bool) {
        return completedTokenTransfers[hash];
    }

    function getExchangeRate() public view returns (uint256) {
        return aUSTExchangeRate;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function encodeAddress(address addr)
        internal
        pure
        returns (bytes32 encodedAddress)
    {
        return bytes32(uint256(uint160(addr)));
    }


    function handleToken(
        address token,
        uint256 amount,
        uint8 opCode
    ) internal {
        _handleToken(token, amount, "", opCode);
    }

    function _handleToken(
        address token,
        uint256 amount,
        bytes memory additionalData,
        uint8 opCode
    ) internal {
        // Transfer ERC-20 token from message sender to this contract.
        SafeERC20.safeTransferFrom(
            IERC20(token),
            msg.sender,
            address(this),
            amount
        );
        // Allow wormhole to spend USTw from this contract.
        SafeERC20.safeIncreaseAllowance(IERC20(token), WORMHOLE_TOKEN_BRIDGE, amount);
        // Initiate token transfer.
        uint64 tokenTransferSequence = WormholeTokenBridge(
            WORMHOLE_TOKEN_BRIDGE
        ).transferTokens(
                token,
                amount,
                TERRA_CHAIN_ID,
                TERRA_ANCHOR_BRIDGE_ADDRESS,
                0,
                TOKEN_TRANSFER_NONCE
            );
        // Send instruction message to Terra manager.

        WormholeCoreBridge(WORMHOLE_CORE_BRIDGE).publishMessage(
            INSTRUCTION_NONCE,
            abi.encodePacked(
                opCode,
                encodeAddress(msg.sender),
                additionalData,
                tokenTransferSequence
            ),
            CONSISTENCY_EVM
        );
    }

    function depositStable(address token, uint256 amount) external {
        handleToken(token, amount, OP_CODE_DEPOSIT_STABLE);
    }

    function repayStable(address token, uint256 amount) external {
        handleToken(token, amount, OP_CODE_REPAY_STABLE);
    }

    function unlockCollateral(
        bytes32 collateralTokenTerraAddress,
        uint128 amount
    ) external {
        WormholeCoreBridge(WORMHOLE_CORE_BRIDGE).publishMessage(
            INSTRUCTION_NONCE,
            abi.encodePacked(
                OP_CODE_UNLOCK_COLLATERAL,
                encodeAddress(msg.sender),
                collateralTokenTerraAddress,
                amount
            ),
            CONSISTENCY_EVM
        );
    }

    function claimRewards() external {
        WormholeCoreBridge(WORMHOLE_CORE_BRIDGE).publishMessage(
            INSTRUCTION_NONCE,
            abi.encodePacked(
                OP_CODE_CLAIM_REWARDS,
                encodeAddress(msg.sender)
            ),
            CONSISTENCY_EVM
        );
    }

    function borrowStable(uint256 amount) external {
        WormholeCoreBridge(WORMHOLE_CORE_BRIDGE).publishMessage(
            INSTRUCTION_NONCE,
            abi.encodePacked(
                OP_CODE_BORROW_STABLE,
                encodeAddress(msg.sender),
                amount
            ),
            CONSISTENCY_EVM
        );
    }

    function redeemStable(address token, uint256 amount) external {
        handleToken(token, amount, OP_CODE_REDEEM_STABLE);
    }

    function lockCollateral(address token, uint256 amount) external {
        handleToken(token, amount, OP_CODE_LOCK_COLLATERAL);
    }

    function lockAndBorrow(address token, uint256 lockAmount, uint256 borrowAmount) external {
        _handleToken(token, lockAmount, abi.encodePacked(borrowAmount), OP_CODE_LOCK_AND_BORROW);
    }

    function withdrawAsset(string calldata token) external {
        WormholeCoreBridge(WORMHOLE_CORE_BRIDGE).publishMessage(
            INSTRUCTION_NONCE,
            abi.encodePacked(
                OP_CODE_WITHDRAW_ASSET,
                encodeAddress(msg.sender),
                token
            ),
            CONSISTENCY_EVM
        );
    }

    struct IncomingTokenTransferInfo {
        uint16 chainId;
        bytes32 tokenRecipientAddress;
        uint64 tokenTransferSequence;
        uint64 instructionSequence;
    }

    using BytesLib for bytes;

    function parseIncomingTokenTransferInfo(bytes memory encoded)
        public
        pure
        returns (IncomingTokenTransferInfo memory incomingTokenTransferInfo)
    {
        uint256 index = 0;

        incomingTokenTransferInfo.chainId = encoded.toUint16(index);
        index += 2;

        incomingTokenTransferInfo.tokenRecipientAddress = encoded.toBytes32(
            index
        );
        index += 32;

        incomingTokenTransferInfo.tokenTransferSequence = encoded.toUint64(
            index
        );
        index += 8;

        incomingTokenTransferInfo.instructionSequence = encoded.toUint64(index);
        index += 8;

        require(
            encoded.length == index,
            "invalid IncomingTokenTransferInfo encoded length"
        );
    }

    // operations are bundled into two messages:
    // - a token transfer message from the token bridge
    // - a generic message providing context to the token transfer
    function processTokenTransferInstruction(
        bytes memory encodedIncomingTokenTransferInfo,
        bytes memory encodedTokenTransfer
    ) external {
        WormholeTokenBridge wormholeTokenBridge = WormholeTokenBridge(
            WORMHOLE_TOKEN_BRIDGE
        );
        WormholeCoreBridge wormholeCoreBridge = WormholeCoreBridge(
            WORMHOLE_CORE_BRIDGE
        );

        (
            WormholeCoreBridge.VM memory incomingTokenTransferInfoVM,
            bool validIncomingTokenTransferInfo,
            string memory reasonIncomingTokenTransferInfo
        ) = wormholeCoreBridge.parseAndVerifyVM(
                encodedIncomingTokenTransferInfo
            );
        require(
            validIncomingTokenTransferInfo,
            reasonIncomingTokenTransferInfo
        );
        require(
            incomingTokenTransferInfoVM.emitterChainId == TERRA_CHAIN_ID,
            "message does not come from terra"
        );
        require(
            incomingTokenTransferInfoVM.emitterAddress ==
                TERRA_ANCHOR_BRIDGE_ADDRESS,
            "message does not come from terra anchor bridge"
        );
        require(
            !completedTokenTransfers[incomingTokenTransferInfoVM.hash],
            "transfer info already processed"
        );

        // block replay attacks
        completedTokenTransfers[incomingTokenTransferInfoVM.hash] = true;
        IncomingTokenTransferInfo
            memory incomingTokenTransferInfo = parseIncomingTokenTransferInfo(
                incomingTokenTransferInfoVM.payload
            );

        (
            WormholeCoreBridge.VM memory tokenTransferVM,
            bool valid,
            string memory reason
        ) = wormholeCoreBridge.parseAndVerifyVM(encodedTokenTransfer);
        require(valid, reason);
        require(
            tokenTransferVM.emitterChainId == TERRA_CHAIN_ID,
            "chain id mismatch"
        );
        // No need to check emitter address; this is checked by completeTransfer.
        // ensure that the provided transfer vaa is the one referenced by the transfer info
        require(
            tokenTransferVM.sequence ==
                incomingTokenTransferInfo.tokenTransferSequence,
            "sequence mismatch"
        );

        WormholeTokenBridge.Transfer memory transfer = wormholeTokenBridge
            .parseTransfer(tokenTransferVM.payload);
        // No need to check that recipient chain matches this chain; this is checked by completeTransfer.
        require(
            transfer.to == encodeAddress(address(this)),
            "transfer is not to this address"
        );
        require(
            transfer.toChain == incomingTokenTransferInfo.chainId,
            "transfer is to the wrong chain"
        );

        if (!wormholeTokenBridge.isTransferCompleted(tokenTransferVM.hash)) {
            wormholeTokenBridge.completeTransfer(encodedTokenTransfer);
        }

        address tokenAddress;
        uint256 tokenAmount;

        if (transfer.tokenChain == wormholeTokenBridge.chainId()) {
            tokenAddress = address(uint160(uint256(transfer.tokenAddress)));
            // query and normalize decimals
            (,bytes memory queriedDecimals) = address(tokenAddress).staticcall(abi.encodeWithSignature("decimals()"));
            uint8 decimals = abi.decode(queriedDecimals, (uint8));
            tokenAmount = transfer.amount;
            if (decimals > 8) {
                tokenAmount *= 10 ** (decimals - 8);
            }
        } else {
            tokenAddress = wormholeTokenBridge.wrappedAsset(
                transfer.tokenChain,
                transfer.tokenAddress
            );
            tokenAmount = transfer.amount;
        }
        // forward the tokens to the appropriate recipient
        SafeERC20.safeTransfer(
            IERC20(tokenAddress),
            address(
                uint160(
                    uint256(incomingTokenTransferInfo.tokenRecipientAddress)
                )
            ),
            tokenAmount
        );
    }

    function feedOraclePrice(
        bytes memory oraclePriceVAA
    ) external {

        WormholeCoreBridge wormholeCoreBridge = WormholeCoreBridge(
            WORMHOLE_CORE_BRIDGE
        );

        (
            WormholeCoreBridge.VM memory oraclePriceVM,
            bool validOraclePriceVAA,
            string memory reasonValidOraclePriceVAA
        ) = wormholeCoreBridge.parseAndVerifyVM(
            oraclePriceVAA
        );
        require(
            validOraclePriceVAA,
                reasonValidOraclePriceVAA
        );

        require(
            oraclePriceVM.emitterAddress ==
            TERRA_ANCHOR_BRIDGE_ADDRESS,
            "message does not come from terra anchor bridge"
        );

        require(
            oraclePriceVM.payload.length == 32,
            "invalid oraclePriceVAA encoded length"
        );

        require(
            oraclePriceVM.timestamp > exchangeRateTimestamp,
            "oracle price is stale"
        );

        exchangeRateTimestamp = oraclePriceVM.timestamp;
        // in gwei
        aUSTExchangeRate = abi.decode(oraclePriceVM.payload, (uint256));
    }
}
