// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";

error NahYoureBoundToMe();
error TooManyBoundToMe();
error CanOnlyBeBoundToMeOnce();

contract LocationTBADAO is Ownable, ERC721A {
    using Address for address;

    uint256 public maxSupply = 3;
    string private _baseTokenURI;

    constructor() ERC721A('LocationTBADAO', 'TBADAO') {
        _mint(msg.sender, 1);
    }

    function airdrop(address receiver) external onlyOwner {
        if (balanceOf(receiver) > 0) revert CanOnlyBeBoundToMeOnce();
        _mint(receiver, 1);
    }

    function mint() public {
        if (totalSupply() < maxSupply) revert TooManyBoundToMe();
        if (balanceOf(msg.sender) > 0) revert CanOnlyBeBoundToMeOnce();
        _mint(msg.sender, 1);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from != address(0)) revert NahYoureBoundToMe();
    }

    function updateMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}