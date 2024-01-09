// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract HonoraryPrimeApes is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;
    bool private _sellable = false;
    address private _deployer = 0x2aeCc6eD8cF7d24A4E0322F6a1cBE6fa969e048C;
    string private _contractURI = "https://gateway.pinata.cloud/ipfs/QmfL35fnyWumvtXHgipukwP9HwFsB9SJ7wjQ1huJiSowEf/contract_metadata.json";
    string private baseURI = "ipfs://QmbxQvqbe54dXQ3eR2utJaZo4hCjFkooYgWv1A3nyYD63u/";

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Honorary PrimeApes", "HPPA") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId + 1);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(_sellable, "Honorary PPAs cannot be approved!");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("Tokens cannot be approved");
    }

    function getSellState() public view returns (bool) {
        return _sellable;
    }

    function sellStateOff() public virtual onlyOwner {
        require(_sellable, "Token listing already disabled!");
        _setSaleState(false);
    }

    function sellStateOn() public virtual onlyOwner {
        require(!_sellable, "Token listing already enabled!");
        _setSaleState(true);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        _setBaseURI(_newURI);
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "Balance must be greater than 0!");
        (bool success, ) = _deployer.call{value: address(this).balance}("");
        require(success, "Failed to withdraw ETH");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _setContractURI(string memory _newURI) internal virtual {
        _contractURI = _newURI;
    }

    function _setBaseURI(string memory _newURI) internal virtual {
        baseURI = _newURI;
    }

    function _setSaleState(bool _state) internal virtual {
        _sellable = _state;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}