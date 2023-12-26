// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface ISANWEAR {
    function mint(address _to, uint256 _id, uint256 _amount) external;
    function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}
