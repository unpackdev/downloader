// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface ITreasury {
    function withdraw(address _token, uint256 _amount) external;

    function withdraw(
        address _token,
        uint256 _amount,
        address _tokenReceiver
    ) external;

    function isWhitelistedToken(address _address) external view returns (bool);

    function oracles(address _token) external view returns (address);

    function withdrawable(address _token) external view returns (uint256);

    function whitelistedTokens() external view returns (address[] memory);

    function vusd() external view returns (address);
}
