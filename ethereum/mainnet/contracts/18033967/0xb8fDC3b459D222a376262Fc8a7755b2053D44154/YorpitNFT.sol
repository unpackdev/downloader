// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721PSI.sol";

contract YorpitNFT is ERC721Psi, Pausable, Ownable {
    string private _metadataBaseURI;

    constructor() ERC721Psi("Yorpit's memories", "YRP") {
        _metadataBaseURI = "ipfs://bafybeietaq6etgh5ewya3e747lrsyhcahkx2lj2fydqhu5imxm3vckynbe/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 amount) public onlyOwner {
        _safeMint(to, amount);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _metadataBaseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {}
}