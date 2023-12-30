pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Actions.sol";
import "./Account.sol";
import "./Types.sol";

abstract contract ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public virtual;

    function getAccountBalances(
        Account.Info memory account
    ) public view virtual returns (
        address[] memory,
        Types.Par[] memory,
        Types.Wei[] memory
    );

    function setOperators(
        OperatorArg[] memory args
    ) public virtual;
}
