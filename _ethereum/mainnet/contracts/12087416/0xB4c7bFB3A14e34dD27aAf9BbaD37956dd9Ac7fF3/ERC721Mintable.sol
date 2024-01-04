// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Operatable.sol";

interface IERC721Mintable {
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    function exists(uint256 _tokenId) external view returns (bool);
    function mint(address _to, uint256 _tokenId) external;
    function isMinter(address account) external view returns (bool);
    function addMinter(address account) external;
    function removeMinter(address account) external;
}

abstract contract ERC721Mintable is ERC721, IERC721Mintable, Operatable {
    using Roles for Roles.Role;
    Roles.Role private minters;

    constructor () {
        addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Must be minter");
        _;
    }

    function isMinter(address account) override public view returns (bool) {
        return minters.has(account);
    }

    function addMinter(address account) override public onlyOperator() {
        minters.add(account);
        emit MinterAdded(account);
    }

    function removeMinter(address account) override public onlyOperator() {
        minters.remove(account);
        emit MinterRemoved(account);
    }
    
    function exists(uint256 tokenId) override public view returns (bool) {
        return super._exists(tokenId);
    }

    function mint(address to, uint256 tokenId) virtual override public onlyMinter() {
        super._mint(to, tokenId);
    }

}
