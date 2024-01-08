// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Initializable.sol";
import "./IAddressRegistry.sol";

/**
 * @title APY.Finance's address registry
 * @author APY.Finance
 * @notice The address registry has two important purposes, one which
 *         is fairly concrete and another abstract.
 *
 *         1. The registry enables components of the APY.Finance system
 *         and external systems to retrieve core addresses reliably
 *         even when the functionality may move to a different
 *         address.
 *
 *         2. The registry also makes explicit which contracts serve
 *         as primary entrypoints for interacting with different
 *         components.  Not every contract is registered here, only
 *         the ones properly deserving of an identifier.  This helps
 *         define explicit boundaries between groups of contracts,
 *         each of which is logically cohesive.
 */
contract AddressRegistry is
    Initializable,
    OwnableUpgradeSafe,
    IAddressRegistry
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /** @notice the same address as the proxy admin; used
     *  to protect init functions for upgrades */
    address public proxyAdmin;
    bytes32[] internal _idList;
    mapping(bytes32 => address) internal _idToAddress;

    /* ------------------------------- */

    event AdminChanged(address);
    event AddressRegistered(bytes32 id, address _address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     */
    function initialize(address adminAddress) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead,
     * we set the proxy admin address as a variable and protect this
     * function with `onlyAdmin`, which only allows the proxy admin
     * to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /// @notice Returns the list of all registered identifiers.
    function getIds() public view override returns (bytes32[] memory) {
        return _idList;
    }

    /// @dev block ETHER transfers as the registry will never need it
    receive() external payable {
        revert("DONT_SEND_ETHER");
    }

    /**
     * @notice Register address with identifier.
     * @dev Using an existing ID will replace the old address with new.
     *      Currently there is no way to remove an ID, as attempting to
     *      register the zero address will revert.
     */
    function registerAddress(bytes32 id, address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        if (_idToAddress[id] == address(0)) {
            // id wasn't registered before, so add it to the list
            _idList.push(id);
        }
        _idToAddress[id] = _address;
        emit AddressRegistered(id, _address);
    }

    /// @dev Convenient method to register multiple addresses at once.
    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external onlyOwner {
        require(ids.length == addresses.length, "Inputs have differing length");
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 id = ids[i];
            address _address = addresses[i];
            registerAddress(id, _address);
        }
    }

    /// @notice Retrieve the address corresponding to the identifier.
    function getAddress(bytes32 id) public view override returns (address) {
        address _address = _idToAddress[id];
        require(_address != address(0), "Missing address");
        return _address;
    }

    /**
     * @notice Get the address for the APY Manager.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function managerAddress() public view returns (address) {
        return getAddress("manager");
    }

    /**
     * @notice Get the address for the TVLManager,
     *         aka the "Chainlink Registry", as it is used by
     *         Chainlink nodes to compute the deployed value of the
     *         APY.Finance system.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function chainlinkRegistryAddress() public view returns (address) {
        return getAddress("chainlinkRegistry");
    }

    /**
     * @notice Get the address for APY.Finance's DAI stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function daiPoolAddress() public view returns (address) {
        return getAddress("daiPool");
    }

    /**
     * @notice Get the address for APY.Finance's USDC stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function usdcPoolAddress() public view returns (address) {
        return getAddress("usdcPool");
    }

    /**
     * @notice Get the address for APY.Finance's USDT stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function usdtPoolAddress() public view returns (address) {
        return getAddress("usdtPool");
    }
}
