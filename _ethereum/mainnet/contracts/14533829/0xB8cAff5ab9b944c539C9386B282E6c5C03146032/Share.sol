// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./ERC1155.sol";
import "./ERC721.sol";
import "./ERC721A.sol";

contract Share is AccessControl {
    string private _name;

    constructor(string memory name_) {
        _name = name_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function approve20(
        address erc20TokenAddress,
        address spender,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "Share: The amount must more than 0!");
        require(spender != address(0), "Share: spender address must not be 0x0!");

        ERC20 tokenContract = ERC20(erc20TokenAddress);
        require(tokenContract.approve(spender, amount), "Share: approve failure");
    }

    function approve1155(
        address erc1155TokenAddress,
        address operator,
        bool approved
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(operator != address(0), "Share: operator address must not be 0x0!");

        ERC1155 tokenContract = ERC1155(erc1155TokenAddress);
        tokenContract.setApprovalForAll(operator, approved);
    }

    function approve721(
        address erc721TokenAddress,
        address operator,
        bool approved
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(operator != address(0), "Share: operator address must not be 0x0!");

        ERC721 tokenContract = ERC721(erc721TokenAddress);
        tokenContract.setApprovalForAll(operator, approved);
    }

    function approve721A(
        address erc721ATokenAddress,
        address operator,
        bool approved
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(operator != address(0), "Share: operator address must not be 0x0!");

        ERC721A tokenContract = ERC721A(erc721ATokenAddress);
        tokenContract.setApprovalForAll(operator, approved);
    }
}
