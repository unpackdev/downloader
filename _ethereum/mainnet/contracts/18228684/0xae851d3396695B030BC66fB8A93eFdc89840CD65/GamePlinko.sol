// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./Game.sol";

contract GamePlinko is Game, ICaller {
    constructor (address _USDT, address _console, address _house, address _SLP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) Game(_USDT, _console, _house, _SLP, _rng, _id, _numbersPerRoll, _maxMultibets, _supportsMultibets) {}

    function fulfillRNG(uint256 _requestId, uint256[] memory _randomNumbers) external nonReentrant onlyRNG {
        Types.Bet memory _Bet = house.getBetByRequestId(_requestId);
        uint256 _stake = _Bet.stake / _Bet.rolls;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](_Bet.rolls);
        for (uint256 _i = 0; _i < _Bet.rolls; _i++) {
            uint256 _roll = rollFromToInclusive(_randomNumbers[_i], 1, 72089);
            if (_roll == 1 || _roll == 65536) {
                _payout += _stake * 110;
            } else if ((_roll > 1 && _roll <= 17) || (_roll > 65519 && _roll <= 65535)) {
                _payout += _stake * 41;
            } else if ((_roll > 17 && _roll <= 137) || (_roll > 65399 && _roll <= 65519)) {
                _payout += _stake * 10;
            } else if ((_roll > 137 && _roll <= 697) || (_roll > 64839 && _roll <= 65399)) {
                _payout += _stake * 5;
            } else if ((_roll > 697 && _roll <= 2517) || (_roll > 63019 && _roll <= 64839)) {
                _payout += _stake * 3;
            } else if ((_roll > 2517 && _roll <= 6885) || (_roll > 58651 && _roll <= 63019)) {
                _payout += _stake * 15000 / 10000;
            } else if ((_roll > 6885 && _roll <= 14893) || (_roll > 50643 && _roll <= 58651)) {
                _payout += _stake;
            } else if ((_roll > 14893 && _roll <= 26333) || (_roll > 39203 && _roll <= 50643) || (_roll > 65536)) {
                _payout += _stake * 10000 / 20000;
            } else if (_roll > 26333 && _roll <= 39203) {
                _payout += _stake / 10000 * 3000;
            }
            _rolls[_i] = _roll;
        }
        house.closeWager(_Bet.player, id, _requestId, _payout);
        emit GameEnd(_requestId, _randomNumbers, _rolls, _Bet.stake, _payout, _Bet.player, block.timestamp);
    }

    function validateBet(uint256 _bet, uint256[50] memory, uint256) public override pure returns (uint256[50] memory) {
        if (_bet > 0) {
            revert InvalidBet(_bet);
        }
        uint256[50] memory _empty;
        return _empty;
    }

    function getMaxPayout(uint256, uint256[50] memory) public override pure returns (uint256) {
        return 110 * (10**18);
    }
}