// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

error WithdrawalFailedUser1();
error WithdrawalFailedUser2();
error WithdrawalFailedUser3();
error WithdrawalFailedUser4();
error ZeroBalance();
error ZeroAddress();

contract JungleFreaksMotorClubRoyaltyReceiver is Ownable, ReentrancyGuard {
    address public user1;
    address public user2;
    address public user3;
    address public user4;

    constructor() {
        user1 = 0x8e5F332a0662C8c06BDD1Eed105Ba1C4800d4c2f;
        user2 = 0x954BfE5137c8D2816cE018EFd406757f9a060e5f;
        user3 = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
        user4 = 0xd196e0aFacA3679C27FC05ba8C9D3ABBCD353b5D;
    }

    receive() external payable {}

    function calculateSplit(uint256 balance)
        public
        pure
        returns (
            uint256 user1Amount,
            uint256 user2Amount,
            uint256 user3Amount,
            uint256 user4Amount
        )
    {
        uint256 rest = balance;
        user1Amount = (balance * 7000) / 10000; // 70.00%
        rest -= user1Amount;

        user2Amount = (balance * 1000) / 10000; // 10.00%
        rest -= user2Amount;

        user3Amount = (balance * 1000) / 10000; // 10.00%
        rest -= user3Amount;

        user4Amount = rest; // 10.00%
    }

    function withdrawErc20(IERC20 token) public nonReentrant {
        uint256 totalBalance = token.balanceOf(address(this));
        if (totalBalance == 0) revert ZeroBalance();

        (
            uint256 user1Amount,
            uint256 user2Amount,
            uint256 user3Amount,
            uint256 user4Amount
        ) = calculateSplit(totalBalance);

        if (!token.transfer(user1, user1Amount)) revert WithdrawalFailedUser1();

        if (!token.transfer(user2, user2Amount)) revert WithdrawalFailedUser2();

        if (!token.transfer(user3, user3Amount)) revert WithdrawalFailedUser3();

        if (!token.transfer(user4, user4Amount)) revert WithdrawalFailedUser4();
    }

    function withdrawEth() public nonReentrant {
        uint256 totalBalance = address(this).balance;
        if (totalBalance == 0) revert ZeroBalance();

        (
            uint256 user1Amount,
            uint256 user2Amount,
            uint256 user3Amount,
            uint256 user4Amount
        ) = calculateSplit(totalBalance);

        if (!payable(user1).send(user1Amount)) revert WithdrawalFailedUser1();

        if (!payable(user2).send(user2Amount)) revert WithdrawalFailedUser2();

        if (!payable(user3).send(user3Amount)) revert WithdrawalFailedUser3();

        if (!payable(user4).send(user4Amount)) revert WithdrawalFailedUser4();
    }

    function setUser1(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user1 = address_;
    }

    function setUser2(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user2 = address_;
    }

    function setUser3(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user3 = address_;
    }

    function setUser4(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user4 = address_;
    }
}
