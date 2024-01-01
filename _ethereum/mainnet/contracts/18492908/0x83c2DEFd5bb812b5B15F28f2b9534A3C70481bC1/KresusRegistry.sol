// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./Ownable.sol";
import "./IKresusRegistry.sol";

/**
 * @title KresusRegistry
 * @notice Registry of authorised modules.
 * Modules must be registered before they can be authorised on a vault.
 */
contract KresusRegistry is IKresusRegistry, Ownable {

    uint256 private removeGuardianTd = 5 days;
    uint256 private unlockTd = 10 days;

    struct ModuleInfo {
        bool exists;
        string name;
    }

    struct ContractInfo {
        bytes4[] selectors;
        mapping(bytes4 => uint256) index;
    }

    // deployed module address to Info struct mapping.
    mapping (address => ModuleInfo) internal modules;

    // contract addresses which are whitelisted.
    mapping (address => ContractInfo) internal contracts;

    // emitted when a new module is registered.
    event ModuleRegistered(address indexed module, string name);

    // emitted when an existing module is removed from the registry.
    event ModuleDeRegistered(address module);

    // emitted when a new contract is registered with selectors.
    event ContractRegistered(address[] contracts, bytes4[] selectors);

    // emitted when an existing contract is removed from the registry
    event ContractDeRegistered(address[] contracts, bytes4[] selectors);

    // emitted when time delay is changed for unlock
    event UnlockTdChanged(uint256 _td);

    // emitted when time delay is changed for remove guardian
    event RemoveGuardianTdChanged(uint256 _td);

    /**
     * @inheritdoc IKresusRegistry
     */
    function registerModule(
        address _module,
        string calldata _name
    )
        external
        onlyOwner
    {
        require(_module != address(0), "KRe: Invalid module");
        require(!modules[_module].exists, "KRe: module already exists");
        modules[_module] = ModuleInfo({exists: true, name: _name});
        emit ModuleRegistered(_module, _name);
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function deregisterModule(address _module) external onlyOwner {
        require(modules[_module].exists, "KRe: module does not exist");
        delete modules[_module];
        emit ModuleDeRegistered(_module);
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function registerContract(
        address[] calldata _contracts,
        bytes4[] calldata _selectors
    )
        external
        onlyOwner
    {
        uint256 len = _contracts.length;
        require(len == _selectors.length, "KRe: Inconsistent lengths");
        for(uint256 i=0; i<len; i++) {
            ContractInfo storage ci = contracts[_contracts[i]];
            require(ci.index[_selectors[i]] == 0, "KRe: Already registered");
            ci.selectors.push(_selectors[i]);
            ci.index[_selectors[i]] = ci.selectors.length;
        }
        emit ContractRegistered(_contracts, _selectors);
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function deregisterContract(
        address[] calldata _contracts,
        bytes4[] calldata _selectors
    )
        external
        onlyOwner
    {
        uint256 len = _contracts.length;
        require(len == _selectors.length, "KRe: Inconsistent lengths");
        for(uint256 i=0; i<len; i++) {
            ContractInfo storage ci = contracts[_contracts[i]];
            uint256 j = ci.index[_selectors[i]];
            require(j != 0, "KRe: Already deregistered");
            ci.selectors[j - 1] = ci.selectors[ci.selectors.length - 1];
            ci.index[ci.selectors[j-1]] = j;
            ci.index[_selectors[i]] = 0;
            ci.selectors.pop();
        }
        emit ContractDeRegistered(_contracts, _selectors);
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function setRemoveGuardianTd(
        uint256 _td
    ) 
        external
        onlyOwner
    {
        removeGuardianTd = _td;
        emit RemoveGuardianTdChanged(_td);
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function setUnlockTd(
        uint256 _td
    )
        external
        onlyOwner
    {
        unlockTd = _td;
        emit UnlockTdChanged(_td);
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function moduleInfo(address _module) external view returns (string memory) {
        return modules[_module].name;
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function isRegisteredModule(
        address _module
    )
        external
        view
        returns(bool)
    {
        return modules[_module].exists;
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function isRegisteredModule(address[] calldata _modules) external view returns (bool) {
        for (uint256 i = 0; i < _modules.length; i++) {
            if (!modules[_modules[i]].exists) {
                return false;
            }
        }
        return true;
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function isRegisteredCalls(
        address[] memory _contracts,
        bytes4[] memory _sigs
    )
        external
        view
        returns(bool registered)
    {
        registered = true;
        uint256 len = _contracts.length;
        require(len == _sigs.length, "KRe: Inconsistent lengths");
        for(uint256 i=0;i<len;i++) {
            uint256 index = contracts[_contracts[i]].index[_sigs[i]];
            if(index == 0)
                return false;
        }
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function getUnlockTd() external view returns(uint256) {
        return unlockTd;
    }

    /**
     * @inheritdoc IKresusRegistry
     */
    function getRemoveGuardianTd() external view returns(uint256) {
        return removeGuardianTd;
    }
}