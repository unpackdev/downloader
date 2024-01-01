// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Address.sol";
import "./IAggregatorV3Source.sol";

contract HoneyPot is Ownable {
    struct HoneyPotDetails {
        int256 liquidationPrice;
        uint256 balance;
    }

    mapping(address => HoneyPotDetails) public honeyPots;
    IAggregatorV3Source public oracle; // OEV Share serving as a Chainlink oracle

    event OracleUpdated(address indexed newOracle);
    event HoneyPotCreated(address indexed creator, int256 liquidationPrice, uint256 initialBalance);
    event HoneyPotEmptied(address indexed honeyPotCreator, address indexed trigger, uint256 amount);
    event PotReset(address indexed owner, uint256 amount);

    constructor(IAggregatorV3Source _oracle) {
        oracle = _oracle;
    }

    function setOracle(IAggregatorV3Source _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleUpdated(address(_oracle));
    }

    function createHoneyPot() external payable {
        require(honeyPots[msg.sender].liquidationPrice == 0, "Liquidation price already set for this user");
        require(msg.value > 0, "No value sent");

        (, int256 currentPrice,,,) = oracle.latestRoundData();

        honeyPots[msg.sender].liquidationPrice = currentPrice;
        honeyPots[msg.sender].balance = msg.value;

        emit HoneyPotCreated(msg.sender, currentPrice, msg.value);
    }

    function _emptyPotForUser(address honeyPotCreator, address recipient) internal {
        HoneyPotDetails storage userPot = honeyPots[honeyPotCreator];

        uint256 amount = userPot.balance;
        userPot.balance = 0; // reset the balance
        userPot.liquidationPrice = 0; // reset the liquidation price
        Address.sendValue(payable(recipient), amount);
    }

    function emptyHoneyPot(address honeyPotCreator) external {
        (, int256 currentPrice,,,) = oracle.latestRoundData();
        require(currentPrice >= 0, "Invalid price from oracle");

        HoneyPotDetails storage userPot = honeyPots[honeyPotCreator];

        require(currentPrice != userPot.liquidationPrice, "Liquidation price reached for this user");
        require(userPot.balance > 0, "No balance to withdraw");

        _emptyPotForUser(honeyPotCreator, msg.sender);
        emit HoneyPotEmptied(honeyPotCreator, msg.sender, userPot.balance);
    }

    function resetPot() external {
        _emptyPotForUser(msg.sender, msg.sender);
        emit PotReset(msg.sender, honeyPots[msg.sender].balance);
    }
}
