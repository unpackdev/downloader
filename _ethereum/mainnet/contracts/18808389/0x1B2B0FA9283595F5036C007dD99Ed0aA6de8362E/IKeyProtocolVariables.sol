// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface IKeyProtocolVariables {
    function xTokenMintFee() external view returns (uint256);

    function securityDepositMonths() external view returns (uint8);

    function xTokensSecurityWallet() external view returns (address);

    function landxOperationalWallet() external view returns (address);

    function landxChoiceWallet() external view returns (address);

    function landXOperationsPercentage() external view returns (uint256);

    function landXChoicePercentage() external view returns (uint256);

    function lndxHoldersPercentage() external view returns (uint256);

    function hedgeFundAllocation() external view returns (uint256);

    function hedgeFundWallet() external view returns (address);

    function preLaunch() external view returns (bool);

    function sellXTokenSlippage() external view returns (uint256);
   
    function buyXTokenSlippage() external view returns (uint256);  

    function cTokenSellFee() external view returns (uint256);

    function validatorCommission() external view returns (uint256);

    function validatorCommisionWallet() external view returns (address);

    function payRentFee() external view returns (uint256);

    function maxValidatorFee() external view returns (uint256);
}