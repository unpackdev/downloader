// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";

contract EtherealStatesMintPasses is Ownable, ERC1155, ERC1155Burnable {
    struct Ownership {
        address account;
        uint96 amount;
    }

    string private _uri;

    constructor() ERC1155('') {}

    /**
     * @dev Airdrops `ownerships[i].amount` `tokenId` to `ownerships[i].account`.
     */
    function airdrop(uint256 id, Ownership[] calldata ownerships)
        public
        onlyOwner
    {
        uint256 length = ownerships.length;
        for (uint256 i; i < length; i++) {
            _mint(
                ownerships[i].account,
                id,
                uint256(ownerships[i].amount),
                bytes('')
            );
        }
    }

    function setURI(string calldata newUri) public onlyOwner {
        _uri = newUri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    bytes(_uri).length > 0
                        ? _uri
                        : 'ipfs://QmX6Uopgf4CHPbyBVtbbBS9aZtMU4juvLEtGvrogoVftu1/',
                    tokenId == 1 ? '1' : '2',
                    '.json'
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 amount)
        external
        view
        returns (address, uint256)
    {
        return (owner(), (amount * 5) / 100);
    }
}
