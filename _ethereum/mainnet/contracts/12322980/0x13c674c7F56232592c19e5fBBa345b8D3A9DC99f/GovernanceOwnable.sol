// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IGovernanceOwnable.sol";

abstract contract GovernanceOwnable is IGovernanceOwnable {
    address private _governanceAddress;

    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    constructor (address governance_) public {
        require(governance_ != address(0), "Governance address should be not null");
        _governanceAddress = governance_;
        emit GovernanceSetTransferred(address(0), governance_);
    }

    /**
     * @dev Returns the address of the current governanceAddress.
     */
    function governance() public view override returns (address) {
        return _governanceAddress;
    }

    /**
     * @dev Throws if called by any account other than the governanceAddress.
     */
    modifier onlyGovernance() {
        require(_governanceAddress == msg.sender, "Governance: caller is not the governance");
        _;
    }

    /**
     * @dev SetGovernance of the contract to a new account (`newGovernance`).
     * Can only be called by the current onlyGovernance.
     */
    function setGovernance(address newGovernance) public virtual override onlyGovernance {
        require(newGovernance != address(0), "GovernanceOwnable: new governance is the zero address");
        emit GovernanceSetTransferred(_governanceAddress, newGovernance);
        _governanceAddress = newGovernance;
    }

}