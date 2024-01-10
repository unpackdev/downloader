// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWebacyProxy {
    function transferErc20TokensAllowed(
        address _contractAddress,
        address _ownerAddress,
        address _recipentAddress,
        uint256 _amount
    ) external;

    function transferErc721TokensAllowed(
        address _contractAddress,
        address _ownerAddress,
        address _recipentAddress,
        uint256 _tokenId
    ) external;

    function pauseContract() external;

    function unpauseContract() external;
}
