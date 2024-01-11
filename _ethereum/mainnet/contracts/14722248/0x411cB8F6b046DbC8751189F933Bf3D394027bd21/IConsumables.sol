// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";

interface IConsumables is IERC1155Upgradeable {
    function mint(uint256 typeId, uint256 qty, address recipient) external;
    function burn(uint256 typeId, uint256 qty, address burnFrom) external;
    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;
    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}