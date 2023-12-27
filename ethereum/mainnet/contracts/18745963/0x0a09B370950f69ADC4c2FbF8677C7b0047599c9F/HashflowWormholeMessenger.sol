/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.18;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./IWormhole.sol";
import "./IHashflowWormholeMessenger.sol";
import "./IHashflowPool.sol";
import "./IHashflowRouter.sol";

import "./HashflowXChainMessengerBase.sol";

contract HashflowWormholeMessenger is
    HashflowXChainMessengerBase,
    IHashflowWormholeMessenger,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using Address for address;

    address public wormholeEndpoint;

    uint8 public wormholeConsistencyLevel;
    uint8 public wormholeConsistencyLevelFast;

    // These mappings manage H-Chain ID <-> Wormhole Chain ID links.
    mapping(uint16 => uint16) public hChainIdToWormholeChainId;
    mapping(uint16 => uint16) public wormholeChainIdToHChainId;

    mapping(uint16 => bytes32) public permissionedRelayers;

    receive() external payable {}

    constructor(uint16 _hChainId, address _router)
        HashflowXChainMessengerBase(_hChainId, _router)
    {}

    /// @inheritdoc IHashflowWormholeMessenger
    function updateWormhole(address wormhole) external override onlyOwner {
        require(
            wormhole.isContract(),
            'HashflowWormholeMessenger::updateWormhole Wormhole endpoint must be a contract.'
        );
        emit UpdateWormholeEndpoint(wormhole, wormholeEndpoint);
        wormholeEndpoint = wormhole;
    }

    /// @inheritdoc IHashflowWormholeMessenger
    function updateWormholeConsistencyLevel(uint8 consistencyLevel)
        external
        override
        onlyOwner
    {
        require(
            consistencyLevel != 0,
            'HashflowWormholeMessenger::updateWormholeConsistencyLevel Consistency level cannot be 0.'
        );
        wormholeConsistencyLevel = consistencyLevel;
        emit UpdateWormholeConsistencyLevel(wormholeConsistencyLevel);
    }

    /// @inheritdoc IHashflowWormholeMessenger
    function updateWormholeConsistencyLevelFast(uint8 consistencyLevel)
        external
        override
        onlyOwner
    {
        require(
            consistencyLevel != 0,
            'HashflowWormholeMessenger::updateWormholeConsistencyLevelFast Consistency level cannot be 0.'
        );
        wormholeConsistencyLevelFast = consistencyLevel;
        emit UpdateWormholeConsistencyLevelFast(wormholeConsistencyLevelFast);
    }

    /// @inheritdoc IHashflowWormholeMessenger
    function updatePermissionedRelayer(uint16 _hChainId, bytes32 relayer)
        external
        override
        onlyOwner
    {
        require(
            _hChainId != hChainId,
            'HashflowWormholeMessenger::updatePermissionedRelayer Cannot update relayer for same chain.'
        );
        require(
            relayer != bytes32(0),
            'HashflowWormholeMessenger::updatePermissionedRelayer Relayer address cannot be 0.'
        );

        permissionedRelayers[_hChainId] = relayer;
        emit UpdatePermissionedRelayer(_hChainId, relayer);
    }

    /// @inheritdoc IHashflowXChainMessenger
    function tradeXChain(
        XChainQuote memory quote,
        address caller,
        bytes32 dstContract,
        bytes memory dstCalldata
    ) external payable {
        require(
            _msgSender() == router,
            'HashflowWormholeMessenger::tradeXChain Sender must be router.'
        );
        require(
            quote.srcChainId == hChainId,
            'HashflowWormholeMessenger::tradeXChain Incorrect srcChainId.'
        );

        _wormholeSend(quote, caller, dstContract, dstCalldata);
    }

    /// @dev Send message via Wormhole.
    function _wormholeSend(
        XChainQuote memory quote,
        address caller,
        bytes32 dstContract,
        bytes memory dstCalldata
    ) private {
        uint256 wormholeMessageFee = IWormhole(wormholeEndpoint).messageFee();
        uint256 totalWormholeMessageFee = wormholeMessageFee;

        // We double the fee for fast relays.
        if (
            wormholeConsistencyLevelFast != 0 &&
            permissionedRelayers[quote.dstChainId] != bytes32(0)
        ) {
            totalWormholeMessageFee = totalWormholeMessageFee * 2;
        }

        require(
            msg.value >= totalWormholeMessageFee,
            'HashflowWormholeMessenger::_wormholeSend Insufficient Wormhole fees.'
        );
        uint16 wormholeDstChainId = hChainIdToWormholeChainId[quote.dstChainId];
        require(
            wormholeDstChainId != 0 &&
                xChainRemotes[quote.dstChainId].length > 0,
            'HashflowWormholeMessenger::_wormholeSend Wormhole destination chain ID not configured'
        );
        require(
            wormholeConsistencyLevel != 0,
            'HashflowWormholeMessenger::_wormholeSend Consistency level not set.'
        );

        {
            bytes memory payload = _generateTradePayload(
                quote,
                caller,
                bytes32(0),
                dstContract,
                dstCalldata
            );
            uint256 sequence = IWormhole(wormholeEndpoint).publishMessage{
                value: wormholeMessageFee
            }(
                0, // Nonce.
                payload,
                wormholeConsistencyLevel
            );
            emit WormholeSend(
                quote.txid,
                msg.value - totalWormholeMessageFee,
                sequence
            );
        }

        if (
            wormholeConsistencyLevelFast != 0 &&
            permissionedRelayers[quote.dstChainId] != bytes32(0)
        ) {
            bytes memory payload = _generateTradePayload(
                quote,
                caller,
                permissionedRelayers[quote.dstChainId],
                dstContract,
                dstCalldata
            );
            uint256 sequence = IWormhole(wormholeEndpoint).publishMessage{
                value: wormholeMessageFee
            }(
                0, // Nonce.
                payload,
                wormholeConsistencyLevelFast
            );
            emit WormholeSendFast(
                quote.txid,
                msg.value - totalWormholeMessageFee,
                sequence
            );
        }
    }

    /// @inheritdoc IHashflowWormholeMessenger
    function wormholeReceive(bytes memory encodedVM)
        external
        override
        nonReentrant
    {
        (
            WormholeStructs.VM memory vm,
            bool valid,
            string memory reason
        ) = IWormhole(wormholeEndpoint).parseAndVerifyVM(encodedVM);

        // We make sure the message is valid and has been signed by
        // Guardians.
        require(valid, reason);

        // We check that the emitter chain has been properly configured.
        // It is OK to revert if not -- the message can be retried later on.
        // Wormhole VAAs are non-blocking.
        uint16 srcHChainId = wormholeChainIdToHChainId[vm.emitterChainId];
        require(
            srcHChainId != 0,
            'HashflowWormholeMessenger::wormholeReceive Invalid source chain.'
        );

        // We ensure that the sender of the message is a valid Hashflow contract.
        bytes32 authorizedRemote = bytes32(
            uint256(bytes32(xChainRemotes[srcHChainId])) >>
                ((32 - xChainRemotes[srcHChainId].length) * 8)
        );
        require(
            authorizedRemote == vm.emitterAddress,
            'HashflowWormholeMessenger::wormholeReceive Unauthorized remote.'
        );

        XChainTradePayload memory tradePayload = abi.decode(
            vm.payload,
            (XChainTradePayload)
        );

        IHashflowRouter.XChainFillMessage memory fillMessage;
        // We need to check that this is the intended receiving chain.
        require(
            tradePayload.dstChainId == hChainId,
            'HashflowWormholeMessenger::wormholeReceive Incorrect destination chain.'
        );
        if (tradePayload.permissionedRelayer != bytes32(0)) {
            require(
                bytes32(
                    uint256(uint160(uint256(tradePayload.permissionedRelayer)))
                ) == tradePayload.permissionedRelayer,
                'HashflowWormholeMessenger::wormholeReceive permissionedRelayer is not EVM address.'
            );
            require(
                address(uint160(uint256(tradePayload.permissionedRelayer))) ==
                    _msgSender(),
                'HashflowWormholeMessenger::wormholeReceive Relayer not authorized.'
            );
        }

        require(
            bytes32(uint256(uint160(uint256(tradePayload.dstPool)))) ==
                tradePayload.dstPool,
            'HashflowWormholeMessenger::wormholeReceive dstPool is not EVM address.'
        );
        require(
            bytes32(
                uint256(uint160(uint256(tradePayload.dstExternalAccount)))
            ) == tradePayload.dstExternalAccount,
            'HashflowWormholeMessenger::wormholeReceive dstExternalAccount is not EVM address.'
        );
        require(
            bytes32(uint256(uint160(uint256(tradePayload.dstTrader)))) ==
                tradePayload.dstTrader,
            'HashflowWormholeMessenger::wormholeReceive dstTrader is not EVM address.'
        );
        require(
            bytes32(uint256(uint160(uint256(tradePayload.quoteToken)))) ==
                tradePayload.quoteToken,
            'HashflowWormholeMessenger::wormholeReceive quoteToken is not EVM address.'
        );

        fillMessage.srcHashflowChainId = srcHChainId;
        fillMessage.srcPool = tradePayload.srcPool;
        fillMessage.dstPool = address(uint160(uint256(tradePayload.dstPool)));
        fillMessage.dstExternalAccount = address(
            uint160(uint256(tradePayload.dstExternalAccount))
        );
        fillMessage.dstTrader = address(
            uint160(uint256(tradePayload.dstTrader))
        );
        fillMessage.quoteToken = address(
            uint160(uint256(tradePayload.quoteToken))
        );
        fillMessage.quoteTokenAmount = tradePayload.quoteTokenAmount;
        fillMessage.txid = tradePayload.txid;
        fillMessage.srcCaller = tradePayload.srcCaller;

        if (tradePayload.dstContract != bytes32(0)) {
            require(
                bytes32(uint256(uint160(uint256(tradePayload.dstContract)))) ==
                    tradePayload.dstContract,
                'HashflowWormholeMessenger::wormholeReceive dstContract is not EVM address.'
            );
            fillMessage.dstContract = address(
                uint160(uint256(tradePayload.dstContract))
            );
            fillMessage.dstContractCalldata = tradePayload.dstContractCalldata;
        }

        IHashflowRouter(router).fillXChain(fillMessage);

        emit WormholeReceive(fillMessage.txid);
    }

    /// @inheritdoc IHashflowWormholeMessenger
    function updateWormholeChainIdForHashflowChainId(
        uint16 hashflowChainId,
        uint16 wormholeChainId
    ) external override onlyOwner {
        require(
            hashflowChainId != 0 && wormholeChainId != 0,
            'HashflowWormholeMessenger::updateWormholeChainIdForHashflowChainId chainId cannot be 0.'
        );

        // If this wormhole Chain ID is already assigned, we need to unassign it first.
        require(
            wormholeChainIdToHChainId[wormholeChainId] == 0,
            'HashflowWormholeMessenger::updateWormholeChainIdForHashflowChainId Wormhole Chain ID already assigned.'
        );

        uint16 previouslyAssignedWormholeChainId = hChainIdToWormholeChainId[
            hashflowChainId
        ];

        // We free up the previously assigned ID.
        if (previouslyAssignedWormholeChainId != 0) {
            wormholeChainIdToHChainId[previouslyAssignedWormholeChainId] = 0;
        }

        hChainIdToWormholeChainId[hashflowChainId] = wormholeChainId;
        wormholeChainIdToHChainId[wormholeChainId] = hashflowChainId;

        emit UpdateWormholeChainId(hashflowChainId, wormholeChainId);
    }

    /// @dev We do not allow the owner to renounce ownership.
    function renounceOwnership() public view override onlyOwner {
        revert(
            'HashflowWormholeMessenger::renounceOwnership Renouncing ownership not allowed.'
        );
    }
}
