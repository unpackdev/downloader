// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

contract TabuTokenV1 is Context, AccessControlEnumerable, ERC1155Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public tokenCount;

    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "need minter role");

        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "need minter role");

        _mintBatch(to, ids, amounts, data);
    }

    function nftMintAndTransferBatch(address collector, address[] memory creators, uint256 numTokens, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "need minter role");
        require(creators.length == numTokens, "ids/length mismatch");

        for (uint256 i = 0; i < creators.length; ++i) {
          tokenCount += 1;
          _mint(creators[i], tokenCount, 1, data);
          _transferAfterMint(creators[i], collector, tokenCount, 1, data);
        }
    }

    function setGlobalMarketApprovalBatch(address[] memory operators, bool[] memory approved) public {
      require(hasRole(MINTER_ROLE, _msgSender()), "need minter role");

      require(operators.length == approved.length, "operators/approved mismatch length");

      for (uint256 i = 0; i < operators.length; ++i) {
        _globalCreatorApprovals[operators[i]] = approved[i];
      }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override(ERC1155)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
