// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./MintableERC20.sol";

contract ONE is MintableERC20 {
    function __ONE_init(address governor_, address vault_, address oneMine) external initializer {
        __Context_init_unchained();
        __ERC20_init_unchained("One Eth", "ONE");
        __Governable_init_unchained(governor_);
        __ApprovedERC20_init_unchained(vault_);
        __ONE_init_unchained(oneMine);
    }

    function __ONE_init_unchained(address oneMine) public governance {
        _mint(oneMine, 100 * 10 ** uint256(decimals()));
    }

}
