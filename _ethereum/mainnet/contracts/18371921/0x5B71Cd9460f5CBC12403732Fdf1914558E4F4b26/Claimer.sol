// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TimeExchange.sol";

contract Claimer {

    using Math for uint256;

    uint256 public lastBlockTimeWasProduced;

    uint256 private constant FACTOR = 10 ** 18;

    TimeExchange public immutable timeExchange;
    ITimeIsUp public immutable tup;
    ITimeToken public immutable timeToken;

    event RewardClaimed(address claimer, uint256 amountInTup, uint256 amountInTime);

    constructor (address tupAddress, address timeTokenAddress, address timeExchangeAddress) {
        tup = ITimeIsUp(payable(tupAddress));
        timeToken = ITimeToken(payable(timeTokenAddress));
        timeExchange = TimeExchange(payable(timeExchangeAddress));
        lastBlockTimeWasProduced = block.number;
    }

    receive() external payable { }

    fallback() external payable {
        require(msg.data.length == 0);
    }

    /// @notice Claims the public reward and convert it into TUP tokens to the user
    /// @dev The goal of this function is to avoid generic MEV bots. It also produces TIME tokens and send them to the informed address
    /// @param claimer Informs the address where the reward should be sent to
    function claim(address claimer) external {
        require(tup.queryPublicReward() > 0, "Claimer: there is not reward to claim");
        try tup.splitSharesWithReward() {
            try timeExchange.swap{value: address(this).balance}(address(0), address(tup), address(this).balance) {
                uint256 amountInTup = tup.balanceOf(address(this));
                try tup.transfer(claimer, amountInTup) { } catch { amountInTup = 0; }
                try timeToken.mining() {
                    lastBlockTimeWasProduced = block.number;
                } catch { }
                uint256 amountInTime = timeToken.balanceOf(address(this));
                if (amountInTime > 0)
                    timeToken.transfer(claimer, amountInTime);
                if (amountInTup > 0 || amountInTime > 0)
                    emit RewardClaimed(claimer, amountInTup, amountInTime);
                else
                    revert("Claimer: not able to claim reward");
            } catch {
                revert("Claimer: not able to claim reward");
            }
        } catch {
            revert("Claimer: not able to claim reward");
        }
    }

    /// @notice Enables the claimer contract to produce TIME Token to give as rewar
    function enableMining() external payable {
        require(msg.value >= timeToken.fee(), "Claimer: please send some amount to enable the contract to produce TIME");
        timeToken.enableMining{value: msg.value}();
    }

    /// @notice Queries an estimate of the public reward amount in terms of TUP tokens
    /// @dev It calculates the reward amount and return it to the user
    /// @return amountInTup The estimated amount in terms of TUP tokens
    /// @return amountInTime The estimated amount in terms of TIME tokens
    function queryPublicRewardEstimate() external view returns (uint256, uint256) {
        uint256 amount = tup.queryPublicReward();
        (uint256 price,) = timeExchange.queryPrice(address(0), address(tup), amount);
        return (amount.mulDiv(price, FACTOR), (block.number - lastBlockTimeWasProduced).mulDiv(FACTOR, 1));
    }
}