// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICollectibles {
    function mintBatch(
        uint256[] memory _tokenTypes,
        uint256[] memory _amounts,
        address _receiver
    ) external;

    function burnBatch(
        uint256[] memory _tokenTypes,
        uint256[] memory _amounts,
        address _receiver
    ) external;

    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;

    function mint(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;
}
