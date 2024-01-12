// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

contract AQPMembership is ERC1155, Ownable, ERC1155Supply {
    constructor() ERC1155("https://app.aqp.io/metadata/") {}

    /// @dev not required by ERC-1155 standard, but for OpenSea to display
    function name() public pure returns (string memory) {
        return "AQP membership";
    }

    /// @dev not required by ERC-1155 standard, but for OpenSea to display
    function symbol() public pure returns (string memory) {
        return "AQPM";
    }

    /// @dev the newuri should be the base uri of the metadata uris,
    ///         e.g, https://app.aqp.io/metadata/ instead of
    ///         https://app.aqp.io/metadata/{id}.json
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /// @dev override the default implementation for the NFT to display correctly on OpenSea
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId), ".json"));
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    /// @dev The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
