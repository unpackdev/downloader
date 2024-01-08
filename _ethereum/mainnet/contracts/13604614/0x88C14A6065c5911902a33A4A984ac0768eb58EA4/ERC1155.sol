// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";

abstract contract ERC1155 is IERC1155, IERC1155MetadataURI {
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        require(account != address(0), "ERC1155: balance of address(0)");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: param lengths mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
        public
    {
        require(msg.sender != operator, "ERC1155: approval for self");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        from; to; id; amount; data; 
        _enforceNonTransferable();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        from; to; ids; amounts; data;
        _enforceNonTransferable();
    }

    function _enforceNonTransferable() internal pure {
        revert("WearYourBadgeProudly!");
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        data;
        _balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }
}
