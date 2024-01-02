// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./AccessControl.sol";
import "./IndelibleGenerative.sol";

contract IndelibleFactory is AccessControl {
    address private defaultOperatorFilter =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    address private generativeImplementation;

    address private indelibleSecurity;

    event ContractCreated(address creator, address contractAddress);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateDefaultOperatorFilter(
        address newFilter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultOperatorFilter = newFilter;
    }

    function updateGenerativeImplementation(
        address newImplementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        generativeImplementation = newImplementation;
    }

    function updateIndelibleSecurity(
        address newIndelibleSecurity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        indelibleSecurity = newIndelibleSecurity;
    }

    function getOperatorFilter() external view returns (address) {
        return defaultOperatorFilter;
    }

    function getGenerativeImplementationAddress()
        external
        view
        returns (address)
    {
        return generativeImplementation;
    }

    function deployGenerativeContract(
        string memory _name,
        string memory _symbol,
        uint _maxSupply,
        Settings calldata _settings,
        RoyaltySettings calldata _royaltySettings,
        bool _registerOperatorFilter
    ) external {
        require(
            generativeImplementation != address(0),
            "Implementation not set"
        );

        address payable clone = payable(Clones.clone(generativeImplementation));
        address operatorFilter = _registerOperatorFilter
            ? defaultOperatorFilter
            : address(0);

        IndelibleGenerative(clone).initialize(
            _name,
            _symbol,
            _maxSupply,
            _settings,
            _royaltySettings,
            FactorySettings(indelibleSecurity, msg.sender, operatorFilter)
        );

        emit ContractCreated(msg.sender, clone);
    }
}
