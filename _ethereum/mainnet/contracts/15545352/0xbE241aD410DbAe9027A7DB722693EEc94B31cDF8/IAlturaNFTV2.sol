// Altura ERC1155 token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAlturaNFTV2 {
    /**
		Initialize from Swap contract
	 */
    function initialize(
        string memory _name,
        string memory _uri,
        address _creator,
        address _factory,
        bool _public
    ) external;

    /**
		Create Card - Only Minters
	 */
    function addItem(
        uint256 maxSupply,
        uint256 supply,
        uint256 _fee
    ) external returns (uint256);

    /**
     * Create Multiple Cards - Only Minters
     */
    function addItems(uint256 count, uint256 _fee) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external returns (bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function creatorOf(uint256 id) external view returns (address);

    function royaltyOf(uint256 id) external view returns (uint256);
}
