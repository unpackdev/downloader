// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "./IBridge.sol";
import "./IEverscale.sol";
import "./IDAO.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./Cache.sol";
import "./ChainId.sol";


/// @title DAO contract for Everscale-EVM bridge
/// @dev Executes proposals confirmed in Everscale Bridge DAO.
/// Proposals are submitted in form of payloads and signatures
contract DAO is IDAO, IEverscale, ReentrancyGuardUpgradeable, OwnableUpgradeable, Cache, ChainId {
    address public bridge;
    EverscaleAddress public configuration;

    constructor() {
        _disableInitializers();
    }

    modifier notZeroAddress(address addr) {
        require(addr != address(0));

        _;
    }

    /**
        @notice Initializer
        @param _owner DAO owner. Should be used only for initial set up,
            than ownership should be transferred to DAO itself.
        @param _bridge Bridge address
    */
    function initialize(
        address _owner,
        address _bridge
    ) public initializer notZeroAddress(_owner) notZeroAddress(_bridge) {
        bridge = _bridge;

        __Ownable_init();
        transferOwnership(_owner);
    }

    /**
        @notice Update address of the Everscale configuration, that emits actions for this DAO
        @param _configuration New configuration Everscale address
    */
    function setConfiguration(
        EverscaleAddress calldata _configuration
    ) public onlyOwner {
        configuration = _configuration;
    }

    /// @dev Update bridge address
    /// @param _bridge New bridge address
    function setBridge(
        address _bridge
    ) override external onlyOwner notZeroAddress(_bridge) {
        bridge = _bridge;
    }

    function decodeEthActionsEventData(
        bytes memory payload
    ) public pure returns (
        int8 _wid,
        uint256 _addr,
        uint32 chainId,
        EthAction[] memory actions
    ) {
        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        return abi.decode(
            _event.eventData,
            (int8, uint256, uint32, EthAction[])
        );
    }

    /**
        @notice Execute set of actions.
        @param payload Encoded Everscale event with payload details
        @param signatures Payload signatures
        @return responses Bytes-encoded payload action responses
    */
    function execute(
        bytes calldata payload,
        bytes[] calldata signatures
    )
        override
        external
        nonReentrant
        notCached(payload)
    returns (
        bytes[] memory responses
    ) {
        require(
            IBridge(bridge).verifySignedEverscaleEvent(
                payload,
                signatures
            ) == 0,
            "DAO: signatures verification failed"
        );

        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        require(
            _event.configurationWid == configuration.wid &&
            _event.configurationAddress == configuration.addr,
            "DAO: wrong event configuration"
        );

        (
            ,,
            uint32 chainId,
            EthAction[] memory actions
        ) = decodeEthActionsEventData(payload);

        require(
            chainId == getChainID(),
            "DAO: wrong chain id"
        );

        responses = new bytes[](actions.length);

        for (uint i=0; i<actions.length; i++) {
            EthAction memory action = actions[i];

            bytes memory callData;

            if (bytes(action.signature).length == 0) {
                callData = action.data;
            } else {
                callData = abi.encodePacked(
                    bytes4(keccak256(bytes(action.signature))),
                    action.data
                );
            }

            (bool success, bytes memory response) = address(action.target)
                .call{value: action.value}(callData);

            require(success, "DAO: execution fail");

            responses[i] = response;
        }
    }
}
