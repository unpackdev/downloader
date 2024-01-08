// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Address.sol";
import "./Initializable.sol";

import "./Governable.sol";
import "./ArrayLib.sol";

contract ContractRegistry is Governable, Initializable {
    using Address for address;
    using ArrayLib for address[];

    uint public constant POOLS_FOLDER = 1;
    uint public constant VAULTS_FOLDER = 2;

    mapping (uint => address[]) public addresses;

    event AddressesAdded(address[] addresses);
    event AddressesRemoved(address[] addresses);
    event PoolsAdded(address[] addresses);
    event PoolsRemoved(address[] addresses);
    event VaultsAdded(address[] addresses);
    event VaultsRemoved(address[] addresses);

    address[] private singleAddress;

    constructor(address[] memory _pools, address[] memory _vaults)
    public Governable(msg.sender) {
        singleAddress.push(address(0));
    }

    function initialize(address[] memory _pools, address[] memory _vaults)
    public onlyGovernance initializer {
        Governable.setGovernance(msg.sender);
        singleAddress.push(address(0));

        addPoolsArray(_pools);
        addVaultsArray(_vaults);
    }

    function list(uint folder) public view returns (address[] memory) {
        return addresses[folder];
    }

    function add(uint folder, address _address) public onlyGovernance {
        addresses[folder].addUnique(_address);

        singleAddress[0] = _address;
        emit AddressesAdded(singleAddress);
    }

    function remove(uint folder, address _address) public onlyGovernance {
        addresses[folder].removeFirst(_address);

        singleAddress[0] = _address;
        emit AddressesRemoved(singleAddress);
    }

    function addArray(uint folder, address[] memory _addresses) public onlyGovernance {
        addresses[folder].addArrayUnique(_addresses);
        emit AddressesAdded(_addresses);
    }

    function removeArray(uint folder, address[] memory _addresses) public onlyGovernance {
        addresses[folder].removeArrayFirst(_addresses);
        emit AddressesRemoved(_addresses);
    }

    // Pools

    function listPools() public view returns (address[] memory) {
        return addresses[POOLS_FOLDER];
    }

    function addPool(address _address) public onlyGovernance {
        addresses[POOLS_FOLDER].addUnique(_address);

        singleAddress[0] = _address;
        emit PoolsAdded(singleAddress);
    }

    function removePool(address _address) public onlyGovernance {
        addresses[POOLS_FOLDER].removeFirst(_address);

        singleAddress[0] = _address;
        emit PoolsRemoved(singleAddress);
    }

    function addPoolsArray(address[] memory _addresses) public onlyGovernance {
        addresses[POOLS_FOLDER].addArrayUnique(_addresses);
        emit PoolsAdded(_addresses);
    }

    function removePoolsArray(address[] memory _addresses) public onlyGovernance {
        addresses[POOLS_FOLDER].removeArrayFirst(_addresses);
        emit PoolsRemoved(_addresses);
    }


    // Vaults

    function listVaults() public view returns (address[] memory) {
        return addresses[VAULTS_FOLDER];
    }

    function addVault(address _address) public onlyGovernance {
        addresses[VAULTS_FOLDER].addUnique(_address);

        singleAddress[0] = _address;
        emit VaultsAdded(singleAddress);
    }

    function removeVault(address _address) public onlyGovernance {
        addresses[VAULTS_FOLDER].removeFirst(_address);

        singleAddress[0] = _address;
        emit VaultsRemoved(singleAddress);
    }

    function addVaultsArray(address[] memory _addresses) public onlyGovernance {
        addresses[VAULTS_FOLDER].addArrayUnique(_addresses);
        emit VaultsAdded(_addresses);
    }

    function removeVaultsArray(address[] memory _addresses) public onlyGovernance {
        addresses[VAULTS_FOLDER].removeArrayFirst(_addresses);
        emit VaultsRemoved(_addresses);
    }
}
