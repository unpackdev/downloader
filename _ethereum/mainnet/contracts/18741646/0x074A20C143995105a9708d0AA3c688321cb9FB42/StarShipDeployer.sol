// SPDX-License-Identifier: UNLICENSED
// Powered by Agora

pragma solidity 0.8.21;

import "./StarBaseERC20.sol";
import "./Context.sol";
import "./IStarShipDeployer.sol";
import "./Authoritative.sol";

contract StarShipDeployer is Context, IStarShipDeployer, Authoritative {
    address public immutable FactoryAddress;
    uint256 public immutable bytesStartPosition;

    constructor(address factory) {
        FactoryAddress = factory;
        SuperAdmin = _msgSender();
        GrantPlatformAdmin(factory);
        (bool validStartPosition, uint256 startPosition) = GetStartPosition();

        if (!validStartPosition) {
            revert("Not a valid position found");
            // Revert(DeploymentError.selector);
        } else {
            bytesStartPosition = startPosition;
        }
    }

    /**
     * @dev function {_startsWithEmptyByte} Does the passed hash start with
     * an empty byte?
     *
     * @param hash_ The bytes32 hash
     * @return bool The hash does / doesn't start with an empty tybe
     */
    function IsHashValid(bytes32 hash_) internal pure returns (bool) {
        return bytes1(hash_) == 0x00;
    }

    function DeployNewToken(
        bytes32 salt,
        bytes32 hash,
        bytes memory arguments
    ) external payable onlyPlatformAdmin returns (address erc20Address) {
        if (IsHashValid(hash)) {
            Revert(InvalidID.selector);
        }

        bytes memory deploymentBytecode = type(StarBaseERC20).creationCode;

        uint256 startPositionInMemoryForAssembly = bytesStartPosition;

        // 2) Modify the bytecode, replacing the default metaIdHash with the received value.
        // This allows us to verify the contract code (with comments) for every token,
        // rather than matching the deployed code (and comments) of previous tokens.
        assembly {
            // Define the start position
            let start := add(
                deploymentBytecode,
                startPositionInMemoryForAssembly
            )

            // Copy the bytes32 value to the specified position
            mstore(add(start, 0x20), hash)
        }

        bytes memory deploymentData = abi.encodePacked(
            deploymentBytecode,
            arguments
        );
        assembly {
            erc20Address := create2(
                callvalue(),
                add(deploymentData, 0x20),
                mload(deploymentData),
                salt
            )
            if iszero(extcodesize(erc20Address)) {
                revert(0, 0)
            }
        }

        return (erc20Address);
    }

    function GetStartPosition() public pure returns (bool, uint256) {
        bytes
            memory bytesTarget = hex"4D45544144524F504D45544144524F504D45544144524F504D45544144524F50";
        bytes memory deploymentCode = type(StarBaseERC20).creationCode;

        // Iterate through the bytecode to find the search bytes.
        // Start at a reasonable position: byte 5000
        for (
            uint256 i = 5000;
            i < deploymentCode.length - bytesTarget.length + 1;
            i += 1
        ) {
            bool found = true;

            // Check if the current chunk matches the search string
            for (uint256 j = 0; j < bytesTarget.length; j++) {
                if (deploymentCode[i + j] != bytesTarget[j]) {
                    found = false;
                    break;
                }
            }

            if (found) {
                return (true, i);
            }
        }

        return (false, 0);
    }
}
