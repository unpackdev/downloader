// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./AccessControlEnumerable.sol";
import "./EnumerableSet.sol";
import "./IContractAllowList.sol";

contract ContractAllowList is IContractAllowList, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // ==========================================================================
    // Section constants
    // ==========================================================================
    bytes32 public constant ALLOW_LIST_EDITOR = keccak256("ALLOW_LIST_EDITOR");

    // ==========================================================================
    // Section variables
    // ==========================================================================
    mapping(uint256 => EnumerableSet.AddressSet) private allowedAddresses;
    uint256 public maxLevel = 0;

    // ==========================================================================
    // Section modifier
    // ==========================================================================
    modifier onlyEditor() {
        require(hasRole(ALLOW_LIST_EDITOR, msg.sender), "You are not editor.");
        _;
    }

    modifier levelMustBeSequencial(uint256 _level) {
        require(_level <= maxLevel + 1, "Level must be sequencial.");
        _;
    }

    modifier exitsLevel(uint256 _level) {
        require(_level <= maxLevel, "Level is not exist.");
        _;
    }

    // ==========================================================================
    // Section external and public functions
    // ==========================================================================

    constructor(address[] memory _governors) {
        _setRoleAdmin(ALLOW_LIST_EDITOR, ALLOW_LIST_EDITOR);

        for (uint256 i = 0; i < _governors.length; i++) {
            _setupRole(ALLOW_LIST_EDITOR, _governors[i]);
        }
    }

    // --------------------------------------------------------------------------
    // For maintain
    // --------------------------------------------------------------------------
    function addAllowed(address _allowd, uint256 _level)
        external
        override
        onlyEditor
        levelMustBeSequencial(_level)
    {
        allowedAddresses[_level].add(_allowd);
        if(_level == maxLevel + 1){
            maxLevel++;
        }
        emit ChangeAllowList(_allowd,_level,true);
    }

    function removeAllowed(address _allowd, uint256 _level)
        external
        override
        onlyEditor
        exitsLevel(_level)
    {
        allowedAddresses[_level].remove(_allowd);
        if(_level == maxLevel && EnumerableSet.length(allowedAddresses[_level]) == 0 && maxLevel > 0){
            maxLevel--;
        }
        emit ChangeAllowList(_allowd,_level,false);
    }

    function getAllowedList(uint256 _level)
        external
        view
        override
        returns (address[] memory)
    {
        return allowedAddresses[_level].values();
    }

    // --------------------------------------------------------------------------
    // For user
    // --------------------------------------------------------------------------
    function isAllowed(address _transferer, uint256 _level)
        public
        view
        override
        returns (bool)
    {
        if(_level == 0){
            return false;   // all ban
        }

        bool Allowed = false;
        for(uint256 i = 1; i < _level + 1; i++){
            if(allowedAddresses[_level].contains(_transferer) == true){
                Allowed = true;
                break;
            }
        }
        return Allowed;
    }
}
