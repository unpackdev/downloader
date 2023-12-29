// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./ISonic.sol";




abstract contract SonicImplementationPointerUpgradeable is OwnableUpgradeable {
    ISonic internal sonic;

    event Updatesonic(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlysonic() {
        require(
            address(sonic) != address(0),
            "Implementations: sonic is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(sonic),
            "Implementations: Not sonic"
        );
        _;
    }

    function getsonicImplementation() public view returns (address) {
        return address(sonic);
    }

    function changesonicImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(sonic);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "sonic: You can only set 0x0 or a contract address as a new implementation"
        );
        sonic = ISonic(newImplementation);
        emit Updatesonic(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}