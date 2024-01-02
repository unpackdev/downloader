// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibClaimTokenStorage.sol";

interface IClaimToken {
    function isClaimToken(
        address _claimTokenAddress
    ) external view returns (bool);

    function getClaimTokensData(
        address _claimTokenAddress
    ) external view returns (LibClaimTokenStorage.ClaimTokenData memory);

    function getClaimTokenofSUNToken(
        address _sunToken
    ) external view returns (address);
}
