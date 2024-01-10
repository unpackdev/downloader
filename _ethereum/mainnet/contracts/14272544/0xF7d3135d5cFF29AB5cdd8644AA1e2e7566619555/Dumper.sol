// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./OneSplitDumper.sol";
import "./CurveLPWithdrawer.sol";
import "./YearnWithdrawer.sol";
import "./StakedAaveWithdrawer.sol";

contract Dumper is
    OneSplitDumper,
    CurveLPWithdrawer,
    YearnWithdrawer,
    StakedAaveWithdrawer
{
    function initialize(address _oneSplit, address _xMPHToken)
        external
        initializer
    {
        __OneSplitDumper_init(_oneSplit, _xMPHToken);
    }
}
