// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";

contract Scoop is ERC20 {

    constructor() ERC20("SCOOP", "SCOOP") {

        _mint(0x3533A9Cd2005b166CDdCE4167d76819f8fcAd13f, 380000000 * 10 ** decimals());
        _mint(0xfe0cB1305fBa37228a0Ddf45C54Ec68a11906BFF, 200000000 * 10 ** decimals());
        _mint(0x4249ff7593C037E1a01455A99a4d774D7f8F46fd, 130000000 * 10 ** decimals());
        _mint(0x716b50bb6B21C3B6689234f93E5d1746dbA0d69D, 120000000 * 10 ** decimals());
        _mint(0x73BF5d274F228a835860B2a709Bc1aD8faa74Eb1, 170000000 * 10 ** decimals());

    }
}
