//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AccessControlEnumerable.sol";

import "./ERC1155.sol";

contract _0Ycollection is ERC1155, AccessControlEnumerable, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(string memory uri_) ERC1155(uri_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "_0Ycollection: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "_0Ycollection: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    function airdrop(
        address[] memory recipients,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "_0Ycollection: must have minter role to mint");

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id, amount, data);
        }
    }

    function setURI(string calldata uri_) public onlyOwner {
        _setURI(uri_);
    }
}