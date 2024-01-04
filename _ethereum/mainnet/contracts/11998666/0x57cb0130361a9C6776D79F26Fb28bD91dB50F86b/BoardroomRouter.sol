// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IVault.sol";
import "./SafeMath.sol";
import "./Operator.sol";
import "./IBoardroom.sol";

contract BoardroomRouter is Operator {
    using SafeMath for uint256;

    IERC20 public token;

    IBoardroom[] public boardrooms;
    uint256[] public percentages;

    constructor(
        IERC20 token_,
        IBoardroom[] memory boardrooms_,
        uint256[] memory percentages_,
        address operator,
        address owner
    ) {
        require(boardrooms_.length == percentages_.length);
        boardrooms = boardrooms_;
        percentages = percentages_;
        token = token_;

        transferOperator(operator);
        transferOwnership(owner);
    }

    function refundReward() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setBoardrooms(
        IBoardroom[] memory boardrooms_,
        uint256[] memory percentages_
    ) external onlyOwner {
        require(boardrooms_.length == percentages_.length);
        boardrooms = boardrooms_;
        percentages = percentages_;
    }

    function allocateSeigniorage(uint256 amount) public onlyOperator {
        // take from treasury
        token.transferFrom(msg.sender, address(this), amount);

        // proxy it to everyone else
        for (uint256 index = 0; index < boardrooms.length; index++) {
            uint256 amt = amount.mul(100).div(percentages[index]);
            token.approve(address(boardrooms[index]), amt);
            boardrooms[index].allocateSeigniorage(amt);
        }
    }

    function deposit(
        IERC20 _token,
        uint256 amount,
        string memory reason
    ) public onlyOperator {
        allocateSeigniorage(amount);
        emit Deposit(_token, msg.sender, block.timestamp, reason);
    }

    event Deposit(
        IERC20 indexed token,
        address indexed from,
        uint256 at,
        string reason
    );
}
