// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Relation is ReentrancyGuard, Ownable {
    address public GuessWinner;
    address public GuessVictory;
    address public GuessScore;

    struct ShareStruct {
        address superior;
        bool active;
    }
    mapping(address => ShareStruct) private shareData;

    event BonusEvent(address account, address referrer);

    function bind(address _account, address _referrer) external {
        require(
            msg.sender == GuessWinner ||
                msg.sender == GuessVictory ||
                msg.sender == GuessScore,
            "unauthorized"
        );
        require(_account != _referrer, "Can't be yourself");

        shareData[_account].active = true;
        shareData[_account].superior = _referrer;

        emit BonusEvent(_account, _referrer);
    }

    function getUserSuperior(address _user) external view returns (address) {
        return shareData[_user].superior;
    }

    function getUserActive(address _user) external view returns (bool) {
        return shareData[_user].active;
    }

    function setGuessContracts(
        address _guessWinner,
        address _guessVictory,
        address _guessScore
    ) public onlyOwner {
        GuessWinner = _guessWinner;
        GuessVictory = _guessVictory;
        GuessScore = _guessScore;
    }

    constructor() {}
}
