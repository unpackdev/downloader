// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "./console.sol";

import "./Initializable.sol";
import "./EnumerableSetUpgradeable.sol";

contract StorageV1Upgradeable is Initializable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    address public proxyAdmin;
    address public governance;
    address public _treasury;
    EnumerableSetUpgradeable.AddressSet admin;
    EnumerableSetUpgradeable.AddressSet operator;

    address public swapCenter;
    address public registry;
    bool public registryLocked;

    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => address[]) public addressArrayStorage;
    mapping(bytes32 => uint256) public uint256Storage;
    mapping(bytes32 => uint256[]) public uint256ArrayStorage;
    mapping(bytes32 => bool) public boolStorage;
    mapping(bytes32 => bool[]) public boolArrayStorage;

    event GovernanceChanged(address oldGov, address newGov);
    event TreasuryChanged(address oldTreasury, address newTreasury);
    event AdminAdded(address newAdmin);
    event AdminRetired(address retiredAdmin);
    event OperatorAdded(address newOperator);
    event OperatorRetired(address oldOperator);
    event RegistryChanged(address oldRegistry, address newRegistry);
    event SwapCenterChanged(address oldSwapCenter, address newSwapCenter);
    event RegistryLocked();
    

    modifier onlyGovernance() {
        require(msg.sender == governance, "StorageV1: not governance");
        _;
    }

    modifier adminPriviledged() {
        require(msg.sender == governance ||
        isAdmin(msg.sender),
        "StorageV1: not governance or admin");
        _;
    }

    modifier registryNotLocked() {
        require(!registryLocked, "StorageV1: registry locked");
        _;
    }

    constructor() {
        governance = msg.sender;
    }

    function initialize(address _governance, address _proxyAdmin) external initializer {
        require(_governance != address(0), "!empty");
        require(_proxyAdmin != address(0), "!empty");
        governance = _governance;
        proxyAdmin = _proxyAdmin;
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "!empty");
        emit GovernanceChanged(governance, _governance);
        governance = _governance;
    }

    function treasury() external view returns (address) {
        if(_treasury == address(0)) {
            return governance;
        } else {
            return _treasury;
        }
    }

    function setTreasury(address _newTreasury) external onlyGovernance {
        require(_newTreasury != address(0));
        emit TreasuryChanged(_treasury, _newTreasury);
        _treasury = _newTreasury;
    }

    function setRegistry(address _registry) external onlyGovernance registryNotLocked {
        require(_registry != address(0), "!empty");
        emit RegistryChanged(registry, _registry);
        registry = _registry;
    }

    function lockRegistry() external onlyGovernance {
        emit RegistryLocked();
        registryLocked = true; 
        // While the contract doesn't provide an unlock method
        // It is still possible to unlock this via Timelock, by upgrading the 
        // implementation of the Timelock proxy.
    }

    function setSwapCenter(address _swapCenter) external onlyGovernance {
        emit SwapCenterChanged(swapCenter, _swapCenter);
        swapCenter = _swapCenter;
    }

    function setAddress(bytes32 index, address _newAddr)
        external
        onlyGovernance
    {
        addressStorage[index] = _newAddr;
    }

    function setAddressArray(bytes32 index, address[] memory _newAddrs)
        external
        onlyGovernance
    {
        addressArrayStorage[index] = _newAddrs;
    }

    function setUint256(bytes32 index, uint256 _newUint256)
        external
        onlyGovernance
    {
        uint256Storage[index] = _newUint256;
    }

    function setUint256Array(bytes32 index, uint256[] memory _newAddrs)
        external
        onlyGovernance
    {
        uint256ArrayStorage[index] = _newAddrs;
    }

    function setUint256(bytes32 index, bool _newBool) external onlyGovernance {
        boolStorage[index] = _newBool;
    }

    function setBoolArray(bytes32 index, bool[] memory _newBools)
        external
        onlyGovernance
    {
        boolArrayStorage[index] = _newBools;
    }

    function numOfAdmin() public view returns (uint256) {
        return admin.length();
    }

    function numOfOperator() public view returns (uint256) {
        return operator.length();
    }

    function getAdmin(uint256 idx) public view returns (address){
        return admin.at(idx);
    }

    function getOperator(uint256 idx) public view returns (address){
        return operator.at(idx);
    }

    function addAdmin(address _who) public onlyGovernance returns (bool) {
        emit AdminAdded(_who);
        return admin.add(_who);
    }

    function addOperator(address _who) public adminPriviledged returns (bool) {
        emit OperatorAdded(_who);
        return operator.add(_who);
    }

    function removeAdmin(address _who) public onlyGovernance returns (bool) {
        emit AdminRetired(_who);
        return admin.remove(_who);
    }

    function removeOperator(address _who) public adminPriviledged returns (bool) {
        emit OperatorRetired(_who);
        return operator.remove(_who);
    }

    function isAdmin(address _who) public view returns (bool) {
        return admin.contains(_who);
    }

    function isOperator(address _who) public view returns (bool) {
        return operator.contains(_who);
    }
}
