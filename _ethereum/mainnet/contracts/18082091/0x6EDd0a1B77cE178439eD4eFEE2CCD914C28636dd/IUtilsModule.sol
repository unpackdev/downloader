/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import "./IJasperVault.sol";

interface IUtilsModule {

    struct  SwapInfo{
        string  exchangeName;
        address assetIn;
        address assetOut;
        uint256 amountIn;
        uint256 amountLimit;
        uint256 approveAmont;
        bool isExact;
        bytes   data;    
    }

    struct Param{
        IJasperVault target;
        IJasperVault follow;
        uint256 positionRate;
        address[]  aTokens;
        address[]  dTokens;
        SwapInfo[] masterToOther;
        SwapInfo[] otherToMaster;    
        int256   rate;  //1000
        SwapInfo[] beforeSwap;
        SwapInfo[] afterSwap;
        address[] spotTokens;
        bool isMirror;
    }
    function initialize(IJasperVault _jasperVault) external;
    function reset(Param memory param) external;  
}
