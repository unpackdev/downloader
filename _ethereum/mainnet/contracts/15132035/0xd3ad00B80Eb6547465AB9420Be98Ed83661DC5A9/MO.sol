// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./Ownable.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

contract ModusOperandi is Ownable, ERC721A {


    uint256 public maxSupply = 1355;

    uint256 public BLOCK_FOR_REVEAL;

    string public baseURI;

    constructor()
    ERC721A("Modus Operandi", "MONFT")
    {
        BLOCK_FOR_REVEAL = 15000 + block.number;
        _safeMint(address(this), 1);
        _burn(0);
    }

    function mint() external
    {
        require(msg.sender == tx.origin, "MONFT/BAD_ORIGIN");
        require(totalSupply() + 1 <= maxSupply, "MONFT/SOLD_OUT");
        require(_numberMinted(msg.sender) == 0, "MONFT/ALREADY_MINTED");
        _safeMint(msg.sender, 1);
    }

    function tokenURI(
        uint256 id
    ) public view override returns (string memory)
    {
        return block.number >= BLOCK_FOR_REVEAL ? string(abi.encodePacked(baseURI, Strings.toString(id))) : "https://gateway.pinata.cloud/ipfs/QmZHMRBtgEhJrQAzP19HKfdxREKcSxWEF6PBg22RNXR48p";
    }

    function contractURI() public pure returns (string memory)
    {
        return "https://gateway.pinata.cloud/ipfs/QmVSw7Ln7h9ifiiJrbLu2TvURqZ3Pkt6HT2dUvt6YAFsC9";
    }

    function setBaseURI(
        string memory _uri
    ) external onlyOwner
    {
        baseURI = _uri;
    }

}