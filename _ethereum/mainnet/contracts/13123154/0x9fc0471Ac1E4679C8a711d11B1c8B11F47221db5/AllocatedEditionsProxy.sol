// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC2309.sol";
import "./AllocatedEditionsStorage.sol";
import "./IAllocatedEditionsFactory.sol";
import "./Governable.sol";
import "./Pausable.sol";
import "./IAllocatedEditionsLogic.sol";
import "./IERC721.sol";

/**
 * @title AllocatedEditionsProxy
 * @author MirrorXYZ
 */
contract AllocatedEditionsProxy is
    AllocatedEditionsStorage,
    Governable,
    Pausable,
    IAllocatedEditionsLogicEvents,
    IERC721Events,
    IERC2309
{
    event Upgraded(address indexed implementation);

    /// @notice IERC721Metadata
    string public name;
    string public symbol;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address owner_, address proxyRegistry_)
        Governable(owner_)
        Pausable(true)
    {
        address implementation = IAllocatedEditionsFactory(msg.sender).logic();
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }

        emit Upgraded(implementation);

        proxyRegistry = proxyRegistry_;

        bytes memory nftMetaData;
        bytes memory adminData;

        (
            // NFT Metadata
            nftMetaData,
            // Edition Data
            allocation,
            quantity,
            price,
            // Admin data
            adminData
        ) = IAllocatedEditionsFactory(msg.sender).parameters();

        (name, symbol, baseURI, contentHash) = abi.decode(
            nftMetaData,
            (string, string, string, bytes32)
        );

        (
            operator,
            tributary,
            fundingRecipient,
            feePercentage,
            treasuryConfig
        ) = abi.decode(
            adminData,
            (address, address, address, uint256, address)
        );

        if (allocation > 0) {
            nextTokenId = allocation;

            emit ConsecutiveTransfer(0, allocation - 1, address(0), operator);
        }
    }

    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}
