// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./Address.sol";

contract ERC20Drop {
    using Address for address;

    struct Recipient {
        address account;
        uint256 amount;
    }

    event Drop(
        address indexed tokenAddress,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    function dropFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) public {
        IERC20 token = IERC20(tokenAddress);

        require(to != from, "Can't sending tokens sender");
        require(
            token.allowance(from, address(this)) >= amount,
            "The sending amount exceeds the allowance"
        );
        require(token.balanceOf(from) >= amount, "The sending amount exceeds sender's balance");
        require(!to.isContract(), "The receiver is a contract");

        token.transferFrom(from, to, amount);

        emit Drop(tokenAddress, from, to, amount);
    }

    function dropManyFrom(
        address tokenAddress,
        address from,
        Recipient[] calldata recipients
    ) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            dropFrom(tokenAddress, from, recipients[i].account, recipients[i].amount);
        }
    }

    function drop(
        address tokenAddress,
        address to,
        uint256 amount
    ) external {
        dropFrom(tokenAddress, msg.sender, to, amount);
    }

    function dropMany(address tokenAddress, Recipient[] calldata recipients) external {
        dropManyFrom(tokenAddress, msg.sender, recipients);
    }
}
