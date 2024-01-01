// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IExchangeAdapter {

    struct AdapterCalldata{
        address spender;
        address target;
        uint256 value;
        bytes  data;    
    }
    function getAdapterCallData(
        address _vault,
        address _sendAsset,
        address _receiveAsset,
        uint256 _adapterType,     
        uint256 _amountIn,
        uint256 _amountLimit,
        bytes memory _data
    )
        external
        view
        returns (
          AdapterCalldata memory _adapterCalldata
        );
}
