// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract GolfTrollTollPass is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string private _customURI;
    uint256 private immutable i_maxSupply;
    Counters.Counter tokenCounter;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory customURI,
        uint256 maxSupply
    ) ERC721(tokenName, tokenSymbol) {
        i_maxSupply = maxSupply;
        _customURI = customURI;
    }

    function mintTollToken(address to) public onlyOwner nonReentrant {
        _safeMint(to, tokenCounter.current());
        tokenCounter.increment();
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmQozmDy3g2hxfvjk6Pb8631MAnqQrTtgokwj6xHFyPT1M/GTTPContractMetaData";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _customURI;
    }
}
