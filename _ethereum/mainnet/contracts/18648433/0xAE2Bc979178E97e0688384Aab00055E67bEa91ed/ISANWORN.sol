// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface ISANWORN {
    function mint(address _to, uint256 _colorwayId) external;
    function mintBatch(address _to, uint256[] calldata _colorwayIds, uint256[] calldata _amounts) external;
}
