// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC1155URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Operable.sol";

contract PEKEPORTAL is ERC1155URIStorage, Ownable, Operable {
    using Strings for string;

    string public name = 'PEKEPORTAL';
    string public symbol = 'P-PORTAL';
    mapping(address => bool) bondedAddress;

    constructor() ERC1155('') {
        _grantOperatorRole(msg.sender);
        _setBaseURI('ipfs://QmdiYiPVjXXnyPJUxwVNgvRhXjCT7JCmHFBeWjZ21mjyrV/');
        initializeSBT(0, '0.json');
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            operator == owner() || bondedAddress[operator] == true,
            'Cannot approve, transferring not allowed'
        );
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function locked(address to) external view returns (bool) {
        return bondedAddress[to];
    }

    function bound(address to, bool flag) public onlyOperator {
        bondedAddress[to] = flag;
    }

    function setBaseURI(string memory uri_) external onlyOperator {
        _setBaseURI(uri_);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        onlyOperator
    {
        _setURI(tokenId, _tokenURI);
    }

    function initializeSBT(uint256 tokenId, string memory _tokenURI)
        public
        onlyOperator
    {
        require(bytes(uri(tokenId)).length == 0, 'SBT already exists');
        _mint(msg.sender, tokenId, 1, '');
        _setURI(tokenId, _tokenURI);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOperator {
        require(bytes(uri(id)).length != 0, 'Not initialized');
        _mint(to, id, amount, '');
    }

    function batchMintTo(
        address[] memory list,
        uint256 id,
        uint256[] memory amount
    ) public onlyOperator {
        for (uint256 i = 0; i < list.length; i++) {
            _mint(list[i], id, amount[i], '');
        }
    }

    function burnAdmin(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOperator {
        _burn(to, id, amount);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(
            operator == owner() || bondedAddress[operator] == true,
            'Send NFT not allowed'
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
        @dev Operable Role
     */
    function grantOperatorRole(address _candidate) external onlyOwner {
        _grantOperatorRole(_candidate);
    }

    function revokeOperatorRole(address _candidate) external onlyOwner {
        _grantOperatorRole(_candidate);
    }
}