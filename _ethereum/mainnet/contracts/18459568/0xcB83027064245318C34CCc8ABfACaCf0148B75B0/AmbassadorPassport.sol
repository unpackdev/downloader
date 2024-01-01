// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./PassportUpgradable.sol";
import "./PassportRegistry.sol";
import "./Initializable.sol";


contract AmbassadorPassport is Initializable, PassportUpgradable {

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize(address defaultAdmin_, string[] memory levels_, uint256 maxSupply_,
        PassportRegistry passportRegistry_) initializer public {
        __Passport_init(defaultAdmin_, levels_, maxSupply_, "Ambassador Passport", "QTAPASS", passportRegistry_);
    }

    function safeMint(address to) public override onlyRole(MINTER_ROLE) {
        super.safeMint(to);
    }

}