// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MockNFT is Ownable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) whitelists;

    constructor(string memory name, string memory symbol)
        public
        ERC721(name, symbol)
    {}

    function mint() external {
        require(whitelists[msg.sender], "Permission denied");
        _tokenIds.increment();
        super._safeMint(msg.sender, _tokenIds.current());
    }

    function addWhitelists(address[] calldata _whitelists) external onlyOwner {
        for (uint i = 0; i < _whitelists.length; i++) {
            whitelists[_whitelists[i]] = true;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmfW6DALjEct2Ak3QnoufeFxpRPwdi9aupKkuRyJTHu6WF";
    }
}
