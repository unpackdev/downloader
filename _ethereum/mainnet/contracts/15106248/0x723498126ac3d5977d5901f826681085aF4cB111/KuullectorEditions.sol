// SPDX-License-Identifier: MIT

/***
 __ _  _  _  _  _  ____   __  ____  ____  ____  ____  _  _
(  / )/ )( \/ )( \(  _ \ /  \(_  _)(_  _)(  __)(  _ \( \/ )
 )  ( ) \/ () \/ ( ) __/(  O ) )(    )(   ) _)  )   / )  /
(__\_)\____/\____/(__)   \__/ (__)  (__) (____)(__\_)(__/
 ____  ____  __  ____  __  __   __ _  ____
(  __)(    \(  )(_  _)(  )/  \ (  ( \/ ___)
 ) _)  ) D ( )(   )(   )((  O )/    /\___ \
(____)(____/(__) (__) (__)\__/ \_)__)(____/
*/

// Contract by @Montana_Wong
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract KuullectorEditions is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    string public name = "Kuullector Editions";
    string public symbol = "KE";
    address private authorizedMintingProxy;

    constructor() ERC1155("ipfs://QmVyJxxw24YXKWUnYgXCNyrHVCfvu9S1ZEKpf7rDw3vH4x/{id}.json") {}

    modifier onlyOwnerOrAuthorized() {
        require(owner() == _msgSender() || authorizedMintingProxy == _msgSender(), "KuullectorEditions: caller is not the owner or authorized");
        _;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    public
    onlyOwnerOrAuthorized
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyOwnerOrAuthorized
    {
        _mintBatch(to, ids, amounts, data);
    }

    function airdrop(address[] memory addresses, uint256 id, uint256 amount) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < addresses.length; ++i) {
                mint(addresses[i], id, amount, bytes(""));
            }
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function adminBurn(address account, uint256 id, uint256 amount) external onlyOwner {
        _burn(account, id, amount);
    }

    function setAuthorizedMintProxy(address _authorizedMintingProxy) external onlyOwner {
        authorizedMintingProxy = _authorizedMintingProxy;
    }
}
