// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./OwnableUpgradeable.sol";

import "./VaultCalculator.sol";

/// @title Collateral Manager V1 Contract
/// @dev This contract is used to manage and calculate the total collateral provided by the owner
contract CollateralManagerV1 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    event CreateReserve(
        bytes32 indexed reserveId,
        address indexed from,
        string name,
        string description
    );

    event DeleteReserve(
        bytes32 indexed reserveId,
        address indexed from,
        string name,
        string description
    );

    event AddReserveVault(
        bytes32 indexed reserveId,
        address indexed from,
        address vault,
        address calculator,
        uint256 index
    );

    event RemoveReserveVault(
        bytes32 indexed reserveId,
        address indexed from,
        address vault,
        address calculator,
        uint256 index
    );

    struct Vault {
        address vault;
        address calculator;
        uint256 numerator;
        uint256 denominator;
    }

    struct Reserve {
        string name;
        string description;
        uint256 index;
        uint256 chainId;
        Vault[] vaults;
    }

    bytes32[] public reserves;

    mapping(address => bytes32) public vaultsMap;
    mapping(bytes32 => Reserve) public reserveMap;

    /// @notice This method can only be called once for a unique contract address
    /// @dev Initialization for the contract, sets the owner
    function initialize(address owner) external initializer {
        require(owner != address(0), "owner can not be the zero address");

        __Ownable_init();
        OwnableUpgradeable.transferOwnership(owner);
    }

    /// @dev Public function to create a new reserve that will be used to report a total collateralized amount in the
    /// denomination token
    /// @param name Shortened string name identifying the reserve
    /// @param chainId Id for the target chain used by this reserve
    /// @param description Text providing basic information on the reserve
    function createReserve(
        string memory name,
        string memory description,
        uint256 chainId
    ) external onlyOwner {
        bytes memory nameBytes = bytes(name);

        require(
            nameBytes.length > 0 && chainId != 0,
            "can not create empty reserve"
        );

        bytes32 reserveId = keccak256(
            abi.encode(name, description, chainId, block.number)
        );

        Reserve storage reserve = reserveMap[reserveId];

        bytes storage reserveNameBytes = bytes(reserve.name);
        bytes storage reserveDescriptionBytes = bytes(reserve.description);

        Vault[] storage reserveVaults = reserve.vaults;

        require(
            reserveVaults.length == 0 &&
                reserveNameBytes.length == 0 &&
                reserveDescriptionBytes.length == 0,
            "can not override existing reserve"
        );

        reserves.push(reserveId);

        reserve.name = name;
        reserve.description = description;

        reserve.chainId = chainId;
        reserve.index = reserves.length - 1;

        emit CreateReserve(reserveId, msg.sender, name, description);
    }

    /// @dev Public function to remove a reserve, taking care to empty all vault data before it is fully removed
    /// @param reserveId ID to the set of vaults used in calculating the total reserve value
    function deleteReserve(bytes32 reserveId) external onlyOwner {
        Reserve storage reserve = reserveMap[reserveId];
        Vault[] storage reserveVaults = reserve.vaults;

        string memory name = reserve.name;
        string memory description = reserve.description;

        uint256 chainId = reserve.chainId;
        bytes memory nameBytes = bytes(name);

        require(nameBytes.length > 0 && chainId != 0, "no reserve available");

        for (uint256 i = 0; i < reserveVaults.length; i++) {
            delete vaultsMap[reserve.vaults[i].vault];
        }

        delete reserve.vaults;
        require(reserveVaults.length == 0, "error removing vaults for reserve");

        uint256 lastIndex = reserves.length - 1;

        reserves[reserve.index] = reserves[lastIndex];
        reserveMap[reserves[lastIndex]].index = reserve.index;

        reserves.pop();
        delete reserveMap[reserveId];

        emit DeleteReserve(reserveId, msg.sender, name, description);
    }

    /// @dev Public function to add a vault to a reserve, the reserve needs to already have been created to modify it,
    /// @param reserveId ID to the set of vaults that will be used in calculating the total reserve value
    /// @param vault Address of the vault holding the asset
    /// @param calculator Contract used to calculate quantity of the denomination asset
    /// @param numerator Quantity used in calculating the collateral ratio for the vaults reserve
    /// @param denominator Quantity used in calculating the collateral ratio for the vaults reserve
    function addReserveVault(
        bytes32 reserveId,
        address vault,
        address calculator,
        uint256 numerator,
        uint256 denominator
    ) external onlyOwner {
        require(
            vaultsMap[vault] == bytes32(0),
            "vault is already a member of a reserve"
        );

        // prevents numbers from getting to large when doing arithmetic

        require(
            numerator < 100 && denominator < 100,
            "invalid vault collateral factors"
        );

        require(
            denominator > 0 && denominator >= numerator,
            "invalid vault collateral ratio"
        );

        Reserve storage reserve = reserveMap[reserveId];

        bytes storage reserveNameBytes = bytes(reserve.name);
        bytes storage reserveDescriptionBytes = bytes(reserve.description);

        require(
            reserveNameBytes.length > 0 && reserveDescriptionBytes.length > 0,
            "no reserve at provided Id"
        );

        // checks the calculator is deployed an readable
        IVaultCalculator(calculator).calculate(vault);
        Vault[] storage reserveVaults = reserve.vaults;

        reserveVaults.push(
            Vault({
                vault: vault,
                calculator: calculator,
                numerator: numerator,
                denominator: denominator
            })
        );

        vaultsMap[vault] = reserveId;

        emit AddReserveVault(
            reserveId,
            msg.sender,
            vault,
            calculator,
            reserveVaults.length
        );
    }

    /// @notice Retricted to the owner.
    /// @dev Public function to remove a vault of a reserve, the reserve and vault need to already exist for the call to
    // succeed
    /// @param reserveId ID to the set of vaults that will be used in calculating the total reserve value
    /// @param index Position of the vault in the reserve
    function removeReserveVault(bytes32 reserveId, uint256 index)
        external
        onlyOwner
    {
        Reserve storage reserve = reserveMap[reserveId];
        Vault[] storage reserveVaults = reserve.vaults;

        bytes storage nameBytes = bytes(reserve.name);
        require(nameBytes.length > 0, "the reserve is empty");

        uint256 reserveVaultsLength = reserveVaults.length;
        require(reserveVaultsLength > index, "vault index out of range");

        address vault = reserveVaults[index].vault;
        address calculator = reserveVaults[index].calculator;

        uint256 lastIndex = reserveVaultsLength - 1;
        reserveVaults[index] = reserveVaults[lastIndex];

        reserveVaults.pop();
        delete vaultsMap[vault];

        emit RemoveReserveVault(
            reserveId,
            msg.sender,
            vault,
            calculator,
            index
        );
    }

    /// @dev Public function that returns all vaults for a reserve
    /// @param reserveId ID to the set of vaults that will be used in calculating the total reserve value
    function getReserveVaults(bytes32 reserveId)
        external
        view
        returns (Vault[] memory)
    {
        return reserveMap[reserveId].vaults;
    }

    /// @dev Public function that returns an individual vault for a reserve
    /// @param reserveId ID to the set of vaults that will be used in calculating the total reserve value
    /// @param index Position of the vault in the reserve
    function getReserveVault(bytes32 reserveId, uint256 index)
        external
        view
        returns (Vault memory)
    {
        return reserveMap[reserveId].vaults[index];
    }

    /// @dev Public function that returns the number of vaults under a reserve
    /// @param reserveId ID to the set of vaults that will be used in calculating the total reserve value
    function getReserveVaultsLength(bytes32 reserveId)
        external
        view
        returns (uint256)
    {
        return reserveMap[reserveId].vaults.length;
    }

    /// @dev Public function that returns the number of vaults under a reserve
    function getReserveLength() external view returns (uint256) {
        return reserves.length;
    }

    /// @notice This function assumes the value calculated has 18 decimals
    /// @dev Public function to calculate the total tokan quantity of a reserve's vaults
    /// @param reserveId ID to the set of vaults that will be used in calculating the total reserve value
    /// @return value The accumulated value of all the vaults in the reserve
    function getReserveValue(bytes32 reserveId)
        external
        returns (uint256 value)
    {
        Reserve storage reserve = reserveMap[reserveId];
        Vault[] storage vaults = reserve.vaults;

        uint256 vaultsLength = vaults.length;
        for (uint256 i = 0; i < vaultsLength; i++) {
            Vault storage v = vaults[i];

            uint256 answer = IVaultCalculator(v.calculator).calculate(v.vault);

            value += (answer * v.numerator) / v.denominator;
        }
    }

    /// @dev Overrides the parent hook which is called ahead of upgrading the implementation address for this contract
    /// @param newImplementation new implementation contract address
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    uint256[47] private __gap;
}
