// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155P.sol";
import "./ERC1155PSupply.sol";
import "./ERC2981.sol";
import "./OwnableRoles.sol";

contract LootBox is ERC1155PSupply, OwnableRoles, ERC2981 {
    string public baseURI;

    constructor() ERC1155P("Beanbag Loot Box", "BBLB") {
        _initializeOwner(tx.origin);

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(tx.origin, 500);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /*
     * Minting
     * Minting can only be done by a designated minter
     */
    function mint(address to, uint256 id, uint256 amount) external onlyRoles(_ROLE_0) {
        _mint(to, id, amount, "");
    }

    function batchMint(address to, uint256[] calldata ids, uint256[] calldata amounts)
        external
        onlyRoles(_ROLE_0)
    {
        _mintBatch(to, ids, amounts, "");
    }

    /*
     * Burning
     * Loot boxes can only be burned by designated burner contract(s)
     */
    function burn(address from, uint256 id, uint256 amount) external onlyRoles(_ROLE_1) {
        if (from != msg.sender) {
            if (!isApprovedForAll(from, msg.sender)) {
                _revert(TransferCallerNotOwnerNorApproved.selector);
            }
        }

        _burn(from, id, amount);
    }

    function batchBurn(address from, uint256[] calldata ids, uint256[] calldata amounts)
        external
        onlyRoles(_ROLE_1)
    {
        if (from != msg.sender) {
            if (!isApprovedForAll(from, msg.sender)) {
                _revert(TransferCallerNotOwnerNorApproved.selector);
            }
        }

        _burnBatch(from, ids, amounts);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155PSupply, ERC2981)
        returns (bool)
    {
        return
            ERC1155PSupply.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
