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

    mapping(uint256 => uint8) public minted;
    uint256 public totalSupply = 1E4;
    address private operatorAddress;

    constructor() ERC721("Crypto Doggies", "CryptoDoggies")  {
        _pause();
    }

    function mintBatch(address to, uint256[] memory ids) public override {
        require(_msgSender() == owner() || _msgSender() == operatorAddress, 'Error: sender');
        require(ids.length > 0, 'Error: ids');
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(minted[id] == 0, 'Exist');
            require(id >= 0 && id < 1E4, 'Error: id');
            minted[id] = 1;
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        _burn(tokenId);
        totalSupply--;
        minted[tokenId] = 2;
    }

    function burnBatch(uint256[] memory ids) public virtual {
        require(ids.length > 0, 'Error: length');
        for (uint256 i = 0; i < ids.length; i++) {
            burn(ids[i]);
        }
    }

    function burnBatchOwner(uint256[] memory ids) public virtual onlyOwner {
        uint256 index;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (minted[id] == 0) {
                minted[id] = 2;
                index++;
            }
        }
        totalSupply -= index;
    }

    function uri(uint256 tokenId) public view virtual returns (string memory) {
        return tokenURI(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < 1E4,'Error: tokenId');
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
