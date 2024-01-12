// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IBaseTokenERC1155 {
    function initialize(
        string memory name_,
        string memory symbol_
    ) external;
    function grantRole(bytes32 role, address account) external;
    function DEFAULT_ADMIN_ROLE() external returns(bytes32);
    function MINTER_ROLE() external returns(bytes32);
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
    function minted(uint256) external returns (uint256);
    function maxSupply(uint256) external returns (uint256);
}
