// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAsset {
    // solhint-disable-next-line func-name-mixedcase
    function __Asset_init(
        string[2] memory nameSymbol,
        address[3] memory oracleZVaultAndWeth,
        uint256[3] memory imeTimeInfoAndInitialPrice,
        address[] calldata _tokenWhitelist,
        address[] calldata _tokensInAsset,
        uint256[] calldata _tokensDistribution,
        address payable _feeAddress
    ) external;

    function mint(address tokenToPay, uint256 amount) external payable returns (uint256);

    function redeem(uint256 amount, address currencyToPay) external returns (uint256);
}
