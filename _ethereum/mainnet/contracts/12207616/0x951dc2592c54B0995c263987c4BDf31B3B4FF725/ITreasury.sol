// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ITreasury {
        function mintControlForIdeaFund(address goingTo, uint256 amount) external;
        function burnControlForIdeaFund(address burningFrom, uint256 amount) external;
}
