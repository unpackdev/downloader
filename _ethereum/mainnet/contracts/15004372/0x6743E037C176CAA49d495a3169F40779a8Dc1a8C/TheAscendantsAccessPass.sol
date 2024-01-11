// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract TheAscendantsAccessPass is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {

    mapping(uint256 => string) private tokenIdToUri;

    string public name = "The Ascendants Access Pass";
    string public symbol = "TAAP";

    bool redeemOpen = false;

    error NotOpenYet();

    event TokenRedeemed(address user, uint256 tokenId, uint256 timestamp);

    constructor() ERC1155("") {}

    function redeemToken(uint256 tokenId) external {
        if (!redeemOpen) revert NotOpenYet();
        _burn(msg.sender, tokenId, 1);
        emit TokenRedeemed(msg.sender, tokenId, block.timestamp);
    }

    function toggleRedeemOpen() onlyOwner external {
        redeemOpen = !redeemOpen;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    external
    onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    external
    onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function setTokenIdToUri(uint256 _tokenId, string memory _uri) external onlyOwner {
        tokenIdToUri[_tokenId] = _uri;
    }

    /**
      * @dev override default uri method to return separate uri for each token id
    */
    function uri(uint256 tokenId) override public view returns (string memory) {
        return (tokenIdToUri[tokenId]);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}