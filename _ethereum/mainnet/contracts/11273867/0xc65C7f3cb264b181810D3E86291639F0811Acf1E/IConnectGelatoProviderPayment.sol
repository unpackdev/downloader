// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./IInstaDapp.sol";

interface IConnectGelatoProviderPayment is ConnectorInterface {
    function setProvider(address _provider) external;

    function payProvider(
        address _token,
        uint256 _amt,
        uint256 _getId,
        uint256 _setId
    ) external payable;

    function gelatoProvider() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function GELATO_CORE() external pure returns (address);
}
