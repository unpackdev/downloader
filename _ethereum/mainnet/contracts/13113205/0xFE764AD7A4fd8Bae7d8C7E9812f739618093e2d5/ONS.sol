// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ApprovedERC20.sol";

contract ONS is ApprovedERC20 {
    function __ONS_init(address governor_, address oneMinter_, address onsMine, address offering, address timelock) external initializer {
        __Context_init_unchained();
        __ERC20_init("One Share", "ONS");
        __Governable_init_unchained(governor_);
        __ApprovedERC20_init_unchained(oneMinter_);
        __ONS_init_unchained(onsMine, offering, timelock);
    }

    function __ONS_init_unchained(address onsMine, address offering, address timelock) public governance {
        _mint(onsMine, 90000 * 10 ** uint256(decimals()));		// 90%
        _mint(offering, 5000 * 10 ** uint256(decimals()));		//  5%
        _mint(timelock, 5000 * 10 ** uint256(decimals()));		//  5%
    }

}
