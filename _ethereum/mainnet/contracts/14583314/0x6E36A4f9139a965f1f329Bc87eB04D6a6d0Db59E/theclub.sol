// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract THECLUB is ERC721A {
    constructor() ERC721A("THE CLUB  2.0", "$F11CLUB") {
        _safeMint(msg.sender, 99);
    }

    function mint(uint256 quantity) external payable onlyOwner{
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, quantity);
    }
     function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://bafybeie6v2xtg4ey35nod5fib7xwzllgxcdq4auyvqtzppinwx6qb2wfhq.ipfs.nftstorage.link/";
    }

    function tokenURI(uint256 tokenId) override public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(tokenId),
                ".json"
            )
        );
    }

    function withdrawEth() public onlyOwner{
        uint256 Balance = address(this).balance;

        (bool succ, ) = address(msg.sender).call{value: Balance}("");
        require(succ, "ETH not sent");
    }

}

// contract THECLUB is Ownable, ERC721  {

//     uint256 public sold;
//     constructor () ERC721("THE CLUB  2.0", "$F11CLUB") {
//         _safeMint(msg.sender, 1);
//         _safeMint(msg.sender, 2);
//         _safeMint(msg.sender, 3);
//         _safeMint(msg.sender, 4);
//         _safeMint(msg.sender, 5);
//         _safeMint(msg.sender, 6);
//     }

//     function _baseURI() internal pure override returns (string memory) {
//         return "https://ipfs.io/ipfs/bafybeiatu2dqn32xprwi4z26kuxr5ezkwr33xpicqxpy3ga2jftven2swe/";
//     }

//     function tokenURI(uint256 tokenId) override public view virtual returns (string memory) {
//         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

//         string memory baseURI = _baseURI();
//         return string(
//             abi.encodePacked(
//                 baseURI,
//                 Strings.toString(tokenId),
//                 ".json"
//             )
//         );
//     }

//     function withdrawEth() public {
//         require(msg.sender == owner, "only admin");
//         uint256 Balance = address(this).balance;

//         (bool succ, ) = address(owner).call{value: Balance}("");
//         require(succ, "ETH not sent");
//     }
// }