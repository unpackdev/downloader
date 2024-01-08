pragma solidity ^0.6.12;

import "./ILimaTokenStorage.sol";
import "./IInvestmentToken.sol";
import "./IAmunUser.sol";

/**
 * @title ILimaTokenHelper
 * @author Lima Protocol
 *
 * Standard ILimaTokenHelper.
 */
interface ILimaTokenHelper is IInvestmentToken, IAmunUser, ILimaTokenStorage {
    function getNetTokenValue(address _targetToken)
        external
        view
        returns (uint256 netTokenValue);

    function getNetTokenValueOf(address _targetToken, uint256 _amount)
        external
        view
        returns (uint256 netTokenValue);

    function getExpectedReturn(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256 returnAmount);

    function getUnderlyingTokenBalance()
        external
        view
        returns (uint256 balance);

    function getUnderlyingTokenBalanceOf(uint256 _amount)
        external
        view
        returns (uint256 balanceOf);

    function getPayback(uint256 gas) external view returns (uint256);

    function getGovernanceToken() external view returns (address token);

    function getFee(uint256 _amount, uint256 _fee)
        external
        view
        returns (uint256 feeAmount);

    function getExpectedReturnRedeem(uint256 _amount, address _to)
        external
        view
        returns (uint256 minimumReturn);

    function getExpectedReturnCreate(uint256 _amount, address _from)
        external
        view
        returns (uint256 minimumReturn);

    function getExpectedReturnRebalance(address _bestToken)
        external
        view
        returns (uint256 minimumReturnGov, uint256 minimumReturn);

    function addAmunOracle(address _amunOracle) external;

    function isAmunOracle(address _amunOracle) external view returns (bool);
}
