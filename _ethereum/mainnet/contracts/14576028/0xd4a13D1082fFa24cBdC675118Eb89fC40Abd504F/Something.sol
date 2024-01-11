// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract Something is Ownable, ERC721A {
    string private _tokenBaseURI;

    constructor() ERC721A("Something", "SMTH") {}

    function airdrop(address[] calldata _claimList) external onlyOwner {
        for (uint256 i = 0; i < _claimList.length; i++) {
            _safeMint(_claimList[i], 1);
        }
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _tokenBaseURI;
    }
}
