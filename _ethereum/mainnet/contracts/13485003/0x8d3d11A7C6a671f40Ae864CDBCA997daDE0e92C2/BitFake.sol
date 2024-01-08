// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//EXTENDED
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./UUPSUpgradeable.sol";


contract BitFake is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable, UUPSUpgradeable  {

    
    string private _contractVersion;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");


    function initialize() initializer public virtual{

        __ERC20_init("BitFake", "REKT");
        __Pausable_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();
        
        _contractVersion = "0.0.1";
        
        

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(APPROVER_ROLE, msg.sender);

        _mint(msg.sender, 55555555555 * 10 ** decimals());
        
        
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function setContractVersion(string memory version) public virtual onlyRole(UPGRADER_ROLE) {
        _contractVersion = version;
    }

    function getContractVersion() public virtual view returns (string memory){
        return _contractVersion;
    }

}
