//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract xObjectsERC721_p3 is ERC721, Ownable {

    constructor() ERC721("xObj.com", "XOBJ3") {
        mint();
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://xobj.com/p3/meta/";
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mint() internal {
        _safeMint(msg.sender, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function claim() external payable {
        require(_tokenIdTracker.current() < 690, "Max tokens minted");
        require(msg.value == 0.018 ether, "claiming costs 0.018 eth");
        mint();
        payable(owner()).transfer(0.018 ether);
    }

}
