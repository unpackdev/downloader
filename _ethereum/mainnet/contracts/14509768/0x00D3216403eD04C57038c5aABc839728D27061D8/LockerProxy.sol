// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//         .-""-.
//        / .--. \
//       / /    \ \
//       | |    | |
//       | |.-""-.|
//      ///`.::::.`\
//     ||| ::/  \:: ;
//     ||; ::\__/:: ;
//      \\\ '::::' /
//       `=':-..-'`
//    https://duo.cash

import "./TransparentUpgradeableProxy.sol";
import "./Initializable.sol";


contract LockerProxy is TransparentUpgradeableProxy, Initializable{

    // Used for the singleton 
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy (_logic, _admin, _data) initializer {}

    // Used for the clones
    function initialize(
        address _logic,
        address admin_,
        bytes memory _data
    ) external initializer{
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);

        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }
}