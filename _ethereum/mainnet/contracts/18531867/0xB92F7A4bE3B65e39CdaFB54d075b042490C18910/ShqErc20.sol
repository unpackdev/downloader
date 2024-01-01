// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract SheqToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    
    mapping(address => bool) public restrictedIndividuals;
    mapping(address => mapping(address=>bool)) public approvedIndividualTransfers;
    mapping(address => bool) public approvedCharities;
    
    event RestrictedIndividualAdded(address indexed _address);
    event RestrictedIndividualRemoved(address indexed _address);
    event IndividualTransferApproved(address indexed _from, address indexed _to);
    event IndividualTransferApprovalRemoved(address indexed _from, address indexed _to);
    event CharityApproved(address indexed _address);
    event CharityApprovalRemoved(address indexed _address);
    
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC20_init("SheqToken", "SHEQ");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init("SheqToken");
        __UUPSUpgradeable_init();

        _mint(initialOwner, 10000000000 * 10 ** decimals());
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    function _update(address from, address to, uint256 value)
    internal
    override(ERC20Upgradeable, ERC20PausableUpgradeable)
{
    // If the sender is restricted, check for individual transfer approval or charity approval
    if (restrictedIndividuals[from]) {
        // If the transfer is neither approved to an individual nor to a charity, revert
        require(approvedIndividualTransfers[from][to] || approvedCharities[to] || to == owner(), "Sender is restricted");
    }
    
    // If the `to` address is not the owner, or if the sender is not restricted,
    // or if it is a transfer to a charity or an approved individual transfer, proceed with the update.
    super._update(from, to, value);
}

    function addRestrictedIndividual(address _address) public onlyOwner {
        restrictedIndividuals[_address] = true;
        emit RestrictedIndividualAdded(_address);
    }
    
    function removeRestrictedIndividual(address _address) public onlyOwner {
        restrictedIndividuals[_address] = false;
        emit RestrictedIndividualRemoved(_address);
    }
    
    function isRestrictedIndividual(address _address) public view returns (bool) {
        return restrictedIndividuals[_address];
    }
    
    function approveIndividualTransfer(address _from, address _to) public onlyOwner {
        approvedIndividualTransfers[_from][_to] = true;
        emit IndividualTransferApproved(_from, _to);
    }
    
    function removeIndividualTransferApproval(address _from, address _to) public onlyOwner {
        approvedIndividualTransfers[_from][_to] = false;
        emit IndividualTransferApprovalRemoved(_from, _to);
    }
    
    function isIndividualTransferApproved(address _from, address _to) public view returns (bool) {
        return approvedIndividualTransfers[_from][_to];
    }
    
    function approveCharity(address _address) public onlyOwner {
        approvedCharities[_address] = true;
        emit CharityApproved(_address);
    }
    
    function removeCharityApproval(address _address) public onlyOwner {
        approvedCharities[_address] = false;
        emit CharityApprovalRemoved(_address);
    }
    
    function isCharityApproved(address _address) public view returns (bool) {
        return approvedCharities[_address];
    }

}
