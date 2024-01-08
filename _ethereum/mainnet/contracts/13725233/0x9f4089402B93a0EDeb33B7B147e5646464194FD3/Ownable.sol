// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// Constructor is removed for upgradeability
abstract contract Ownable {
    event OwnerNominated(address newOwner);
    event OwnerChanged(address newOwner);

    address public owner;
    address public nominatedOwner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "not nominated");

        owner = nominatedOwner;
        nominatedOwner = address(0);

        emit OwnerChanged(owner);
    }
}
