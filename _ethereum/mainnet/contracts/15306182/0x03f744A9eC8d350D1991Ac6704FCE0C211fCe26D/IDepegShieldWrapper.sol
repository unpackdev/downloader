// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IDepegShieldWrapper {
    function checkAndToggleTrigger(uint256 _pid, address _underlyingToken) external returns (bool);

    function trigger(
        uint256 _pid,
        address _underlyingToken,
        uint256 _tokens
    ) external;

    function protect(
        uint256 _pid,
        bytes32 _lendingId,
        uint256 _tokens,
        address _underlyingToken
    ) external returns (bool);

    function unprotect(bytes32 _lendingId) external;

    function solved(bytes32 _lendingId, address _recipient) external returns (address, uint256);

    function calculateAmount(bytes32 _lendingId) external view returns (uint256);

    function isProtect(bytes32 _lendingId) external view returns (bool, address);

    function isTriggered(uint256 _pid, address _underlyingToken) external view returns (bool);

    function getInfo(uint256 _pid, address _underlyingToken)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}
