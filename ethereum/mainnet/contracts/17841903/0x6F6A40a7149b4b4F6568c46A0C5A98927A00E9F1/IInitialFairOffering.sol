// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IInscriptionFactory.sol";

interface IInitialFairOffering {
    function initialize(IInscriptionFactory.Token memory _token) external;
    function setMintData(address _addr, uint128 _ethAmount, uint128 _tokenAmount, uint128 _tokenLiquidity) external;
    function liquidityAdded() external view returns(bool);
}
