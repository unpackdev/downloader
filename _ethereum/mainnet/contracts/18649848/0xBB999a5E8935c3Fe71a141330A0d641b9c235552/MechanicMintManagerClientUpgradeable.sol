// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./OwnableUpgradeable.sol";
import "./IMechanic.sol";
import "./IMechanicMintManagerView.sol";

/**
 * @notice MintManager client, to be used by mechanic contracts
 * @author highlight.xyz
 */
abstract contract MechanicMintManagerClientUpgradeable is OwnableUpgradeable, IMechanic {
    /**
     * @notice Throw when caller is not MintManager
     */
    error NotMintManager();

    /**
     * @notice Throw when input mint manager is invalid
     */
    error InvalidMintManager();

    /**
     * @notice Mint manager
     */
    address public mintManager;

    /**
     * @notice Enforce caller to be mint manager
     */
    modifier onlyMintManager() {
        if (msg.sender != mintManager) {
            _revert(NotMintManager.selector);
        }
        _;
    }

    /**
     * @notice Update the mint manager
     * @param _mintManager New mint manager
     */
    function updateMintManager(address _mintManager) external onlyOwner {
        if (_mintManager == address(0)) {
            _revert(InvalidMintManager.selector);
        }

        mintManager = _mintManager;
    }

    /**
     * @notice Initialize mechanic mint manager client
     * @param _mintManager Mint manager address
     * @param platform Platform owning the contract
     */
    function __MechanicMintManagerClientUpgradeable_initialize(
        address _mintManager,
        address platform
    ) internal onlyInitializing {
        __Ownable_init();
        mintManager = _mintManager;
        _transferOwnership(platform);
    }

    /**
     * @notice Get a mechanic mint vector's metadata
     * @param mechanicVectorId Mechanic vector ID
     */
    function _getMechanicVectorMetadata(
        bytes32 mechanicVectorId
    ) internal view returns (MechanicVectorMetadata memory) {
        return IMechanicMintManagerView(mintManager).mechanicVectorMetadata(mechanicVectorId);
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
