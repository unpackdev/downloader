// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Pausable.sol";
import "./MintBatchInterface.sol";

contract DoggyNFT is ERC721Pausable, Ownable, MintBatchInterface {
    using Strings for string;

    string private _contractUri;
    string private _baseUri;

    uint256 constant public totalSupply = 1E4;
    address private operatorAddress;

    constructor() ERC721("Crypto Doggies", "CryptoDoggies")  {
        _pause();
    }

    function mintBatch(address to, uint256[] memory ids) public override {
        require(_msgSender() == owner() || _msgSender() == operatorAddress, 'Error: sender');
        require(ids.length > 0, 'Error: ids');
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(id >= 0 && id < totalSupply, 'Error: id');
            _mint(to, id);
        }
    }

    function setOperatorAddress(address _operatorAddress) public onlyOwner {
        operatorAddress = _operatorAddress;
    }

    function setBaseUri(string memory newUri) public onlyOwner {
        _baseUri = newUri;
    }

    function setContractUri(string memory newUri) public onlyOwner {
        _contractUri = newUri;
    }

    function contractUri() public view returns (string memory) {
        return _contractUri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    function uri(uint256 tokenId) public view virtual returns (string memory) {
        return tokenURI(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseUri, Strings.toString(tokenId), ".json"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from != address(0)) {
            super._beforeTokenTransfer(from, to, tokenId);
        }
    }

}
