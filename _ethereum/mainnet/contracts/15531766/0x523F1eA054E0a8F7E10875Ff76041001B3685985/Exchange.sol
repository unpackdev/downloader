//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Exchange contracts
import "./ExchangeCore.sol";

/**
 * @title OasisX Exchange
 * @notice Exchange Contract
 * @author OasisX Protocol | cryptoware.eth
 */
contract Exchange is ExchangeCore {
    /** Constructor */
    constructor(
        string memory name,
        string memory version,
        address protocolFeeRecipient,
        ProtocolFee memory pFee_
    ) ExchangeCore(name, version, protocolFeeRecipient, pFee_) {}

    function hashOrder(
        address registry,
        address maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes calldata staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt
    ) external pure returns (bytes32 hash) {
        return
            super.hashOrder(
                Order(
                    registry,
                    maker,
                    staticTarget,
                    staticSelector,
                    staticExtradata,
                    maximumFill,
                    listingTime,
                    expirationTime,
                    salt
                )
            );
    }

    function validateOrderParameters(
        address registry,
        address maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes calldata staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt
    ) external view returns (bool) {
        Order memory order = Order(
            registry,
            maker,
            staticTarget,
            staticSelector,
            staticExtradata,
            maximumFill,
            listingTime,
            expirationTime,
            salt
        );
        return super.validateOrderParameters(order, hashOrder(order));
    }

    function approveOrder(
        address registry,
        address maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes calldata staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    ) external {
        super.approveOrder(
            Order(
                registry,
                maker,
                staticTarget,
                staticSelector,
                staticExtradata,
                maximumFill,
                listingTime,
                expirationTime,
                salt
            ),
            orderbookInclusionDesired
        );
    }

    function atomicMatch(
        uint256[16] memory uints,
        bytes4[2] memory staticSelectors,
        bytes memory firstExtradata,
        bytes memory firstCalldata,
        bytes memory secondExtradata,
        bytes memory secondCalldata,
        uint8[2] memory howToCalls,
        bytes32 metadata,
        bytes memory signatures
    ) external payable {
        return
            super.atomicMatch(
                Order(
                    address(uint160(uints[0])),
                    address(uint160(uints[1])),
                    address(uint160(uints[2])),
                    staticSelectors[0],
                    firstExtradata,
                    uints[3],
                    uints[4],
                    uints[5],
                    uints[6]
                ),
                Call(
                    address(uint160(uints[7])),
                    AuthenticatedProxy.HowToCall(howToCalls[0]),
                    firstCalldata
                ),
                Order(
                    address(uint160(uints[8])),
                    address(uint160(uints[9])),
                    address(uint160(uints[10])),
                    staticSelectors[1],
                    secondExtradata,
                    uints[11],
                    uints[12],
                    uints[13],
                    uints[14]
                ),
                Call(
                    address(uint160(uints[15])),
                    AuthenticatedProxy.HowToCall(howToCalls[1]),
                    secondCalldata
                ),
                signatures,
                metadata
            );
    }
}
