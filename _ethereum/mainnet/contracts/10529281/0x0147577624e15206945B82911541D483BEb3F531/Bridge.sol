// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
import "./ERC20.sol";
import "./Ownable.sol";

contract Bridge is Ownable {
    event Mint(
        ERC20 indexed token,
        bytes32 ellipticoin_address,
        uint256 amount
    );

    function mint(
        ERC20 token,
        bytes32 ellipticoin_address,
        uint256 amount
    ) public {
        token.transferFrom(msg.sender, address(this), amount);
        Mint(token, ellipticoin_address, amount);
    }

    function release(
        ERC20 token,
        address to,
        uint256 amount
    ) public onlyOwner {
        token.transfer(to, amount);
    }
}
