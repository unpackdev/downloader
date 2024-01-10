//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "./IERC20.sol";
// import "./SafeERC20.sol";

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./console.sol";


contract CarrotERC20 is OwnableUpgradeable, ERC20Upgradeable {

    /**
     * initial constant value should be set in initialize,
     * since this contract is behind proxy
     */
    uint256 internal _1_MILLION;
    address public multisigAddress;

    function initialize(
        string memory name_,
        string memory symbol_,
        address multisigAddress_
    )
        public
        initializer
    {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        multisigAddress = multisigAddress_;
        _1_MILLION = 1e24; // 1e6 * 1e18 = 1e24
        uint256 multisigEntitlement = _1_MILLION * 100; // 100mm
        _mint(multisigAddress_, multisigEntitlement);
    }

}
