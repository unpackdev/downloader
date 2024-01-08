// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.4;

import "./CToken.sol";

/// @dev We use interfaces instead of actual contracts, as importing actual contracts
///      exceeds the contract size limits.

/// These interface are used instead of the contracts to decrease the size of the deployable 
/// contract so that they can be deployed withing an ethereum block.
interface IKComptroller {
    function redeemAllowed(CToken cToken, uint256 redeemTokens) external;
    function borrowAllowed(CToken cToken, uint256 redeemTokens) external;
    function postWithdrawalCheck(CToken cToken) external view;
    function seizeTokenAmount(address cTokenRepay, address cTokenCollateral, uint256 repayAmount) external returns (uint);
    function requireNoError(uint errCode, string calldata message) external pure;
    function provideBuffer(address _cToken, uint256 _amount) external;
    function clearBuffer(address _cToken) external returns (uint256);
    function tokenBalance(address _wallet, CToken _cToken) external returns (uint256);
    function checkBufferValue(address _token, uint256 _amount) external;

    function isUnderwritten(address _account) external view returns (bool);
    function unhealth(address _account) external view returns (uint256);    
    function bufferCollateralValueInUSD(address _account) external view returns (uint256);    
    function collateralValueInUSD(CToken _cToken, uint256 _amount) external view returns (uint256);
}

interface ICompoundPositionFactory {
    function create(address _vars) external returns (ICompoundPosition);
}

interface ICompoundPosition {
    function deposit(address token, uint256 amount) external;
    function repay(address token, uint256 amount) external;
    function withdraw(address to, address token, uint256 amount) external;
    function borrow(address to, address token, uint256 amount) external;
    function claimCOMP(address to) external;
    function migrate(address account, uint256 amount) external;

    function tokenBalance(address token) external returns (uint256);
    function outstandingLoan(address token) external returns (uint256);
    function enterSupportedMarkets() external;
}