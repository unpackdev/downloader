// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

// ====================== SturdyPairRegistry ========================

import "./IERC20Metadata.sol";
import "./Ownable2Step.sol";

contract SturdyPairRegistry is Ownable2Step {
    /// @notice addresses of deployers allowed to add to the registry
    mapping(address => bool) public deployers;

    /// @notice List of the addresses of all deployed Pairs
    address[] public deployedPairsArray;

    /// @notice name => deployed address
    mapping(string => address) public deployedPairsByName;

    constructor(address _ownerAddress, address[] memory _initialDeployers) Ownable2Step() {
        for (uint256 i = 0; i < _initialDeployers.length; i++) {
            deployers[_initialDeployers[i]] = true;
        }
        _transferOwnership(_ownerAddress);
    }

    // ============================================================================================
    // Functions: View Functions
    // ============================================================================================

    /// @notice The ```deployedPairsLength``` function returns the length of the deployedPairsArray
    /// @return length of array
    function deployedPairsLength() external view returns (uint256) {
        return deployedPairsArray.length;
    }

    /// @notice The ```getAllPairAddresses``` function returns an array of all deployed pairs
    /// @return _deployedPairsArray The array of pairs deployed
    function getAllPairAddresses() external view returns (address[] memory _deployedPairsArray) {
        _deployedPairsArray = deployedPairsArray;
    }

    // ============================================================================================
    // Functions: Setters
    // ============================================================================================

    /// @notice The ```SetDeployer``` event is called when a deployer is added or removed from the whitelist
    /// @param deployer The address to be set
    /// @param _bool The value to set (allow or disallow)
    event SetDeployer(address deployer, bool _bool);

    /// @notice The ```setDeployers``` function sets the deployers whitelist
    /// @param _deployers The deployers to set
    /// @param _bool The boolean to set
    function setDeployers(address[] memory _deployers, bool _bool) external onlyOwner {
        for (uint256 i = 0; i < _deployers.length; i++) {
            deployers[_deployers[i]] = _bool;
            emit SetDeployer(_deployers[i], _bool);
        }
    }

    // ============================================================================================
    // Functions: External Methods
    // ============================================================================================

    /// @notice The ```AddPair``` event is emitted when a new pair is added to the registry
    /// @param pairAddress The address of the pair
    event AddPair(address pairAddress);

    /// @notice The ```addPair``` function adds a pair to the registry and ensures a unique name
    /// @param _pairAddress The address of the pair
    function addPair(address _pairAddress) external {
        // Ensure caller is on the whitelist
        if (!deployers[msg.sender]) revert AddressIsNotDeployer();

        // Add pair to the global list
        deployedPairsArray.push(_pairAddress);

        // Pull name, ensure uniqueness and add to the name mapping
        string memory _name = IERC20Metadata(_pairAddress).name();
        if (deployedPairsByName[_name] != address(0)) revert NameMustBeUnique();
        deployedPairsByName[_name] = _pairAddress;

        emit AddPair(_pairAddress);
    }

    // ============================================================================================
    // Errors
    // ============================================================================================

    error AddressIsNotDeployer();
    error NameMustBeUnique();
}
