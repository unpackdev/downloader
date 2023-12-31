// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./Game.sol";

contract GameBlastOff is Game, ICaller {
    constructor (address _USDT, address _console, address _house, address _SLP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) Game(_USDT, _console, _house, _SLP, _rng, _id, _numbersPerRoll, _maxMultibets, _supportsMultibets) {}

    function fulfillRNG(uint256 _requestId, uint256[] memory _randomNumbers) external nonReentrant onlyRNG {
        Types.Bet memory _Bet = house.getBetByRequestId(_requestId);
        uint256 _bet = _Bet.bet;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](1);
        uint256 _roll = (95 * (10**22)) / rollFromToInclusive(_randomNumbers[0], 0, 1000000);
        if (_roll >= (_bet * (10**16))) {
            _payout = _Bet.stake * _bet / 100;
        }
        _rolls[0] = _roll;
        house.closeWager(_Bet.player, id, _requestId, _payout);
        emit GameEnd(_requestId, _randomNumbers, _rolls, _Bet.stake, _payout, _Bet.player, block.timestamp);
    }

    function validateBet(uint256 _bet, uint256[50] memory, uint256) public override pure returns (uint256[50] memory) {
        if (_bet < 200 || _bet > 200000) {
            revert InvalidBet(_bet);
        }
        uint256[50] memory _empty;
        return _empty;
    }

    function getMaxPayout(uint256 _bet, uint256[50] memory) public override pure returns (uint256) {
        return _bet * (10**16);
    }
}