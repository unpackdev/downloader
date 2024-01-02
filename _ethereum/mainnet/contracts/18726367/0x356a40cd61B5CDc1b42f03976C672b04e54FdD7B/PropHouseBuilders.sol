// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PropHouseBuilders is ERC1155, Ownable {
    /// @notice The Prop House entrypoint contract address.
    address public immutable propHouse;

    constructor(address initialOwner, address propHouse_) ERC1155('ipfs://bafybeibus3mnpmm2kez6shxqvnawv4ixxfz2besdh3hug4j55p4ihkspgm/') Ownable(initialOwner) {}

    /// @notice The IPFS URI of contract-level metadata.
    function contractURI() external pure returns (string memory) {
        return 'ipfs://bafkreihv6y4jrxfgp6tszuk432bua3tgqig3abx5s5np7yu4e45u2aaw2i';
    }

    /// @notice Returns the metadata for the provided token id.
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(_baseURI, Strings.toString(id), '.json');
    }

    /// @notice Override isApprovedForAll so users can use as a Prop House award without approving.
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        if (operator == propHouse) {
            return true;
        }
        return super.isApprovedForAll(account, operator);
    }

    /// @notice Updates the base URI.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /// @notice Creates `amount` of tokens of type `id`, and assigns them to `to`.
    function mint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, '');
    }

    /// @notice Creates `amounts` of tokens of type `ids`, and assigns them to `to`.
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) external onlyOwner {
        _mintBatch(to, ids, amounts, '');
    }
}
