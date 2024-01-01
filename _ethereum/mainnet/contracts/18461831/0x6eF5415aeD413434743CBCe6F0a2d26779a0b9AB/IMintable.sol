// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMintable {
    function mint(
        address buyer,
        uint256 id,
        uint256 editions,
        string calldata meta,
        address royaltyReceiver,
        uint96 royalty
    ) external;

    function exists(uint256 id) external view returns (bool);
}
