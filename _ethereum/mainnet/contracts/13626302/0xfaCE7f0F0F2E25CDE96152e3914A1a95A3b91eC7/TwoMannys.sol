// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

interface IMannysGame {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external returns (uint256);
}

contract TwoMannys is ERC20 {
    IMannysGame private MannysGame =
        IMannysGame(0x2bd58A19C7E4AbF17638c5eE6fA96EE5EB53aed9);

    bool private over;

    constructor() ERC20("Mannys Gold", "MGLD") {}

    function dEaD458() public {
        require(!over, "game over");
        require(MannysGame.balanceOf(msg.sender) > 0, "no");
        MannysGame.transferFrom(
            0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407,
            0x000000000000000000000000000000000000dEaD,
            458
        );
        _mint(msg.sender, 10000 * 10**decimals());
        over = true;
    }

    function dEaD1042() public {
        require(!over, "game over");
        require(MannysGame.balanceOf(msg.sender) > 0, "no");
        MannysGame.transferFrom(
            0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407,
            0x000000000000000000000000000000000000dEaD,
            1042
        );
        _mint(msg.sender, 10000 * 10**decimals());
        over = true;
    }
}
