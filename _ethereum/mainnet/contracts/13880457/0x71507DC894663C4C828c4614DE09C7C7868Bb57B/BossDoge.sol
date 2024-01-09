// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "ERC721.sol";
import "Ownable.sol";
import "SafeMath.sol";

contract BossDoge is ERC721, Ownable { 
    using SafeMath for uint256;
    uint256 public constant MAX_TOKENS = 100;
    uint256 public tokenCounter;
    constructor () public ERC721 ("BossDoge", "BOSS"){
        tokenCounter = 0;
    }

    function createCollectible(string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 newItemId = tokenCounter;
        if(tokenCounter == 0) {
            _safeMint(msg.sender, 0);
            _setTokenURI(0, "https://ipfs.io/ipfs/QmUdxBTbdP4wL7wRXDnnjNed6h3UNtXt1EJ7ytdNBCKsoV?filename=0.json");
            _safeMint(msg.sender, 1); 
            _setTokenURI(1, "https://ipfs.io/ipfs/QmapCZDELnZozKvZQq1wk8sa1dXMBUW8fRxfva8TMHK6FJ?filename=1.json");
            _safeMint(msg.sender, 2);
            _setTokenURI(2, "https://ipfs.io/ipfs/QmWpM4m4wVLV6z8BtLLB5VwxfTLgev56oidHbtGbAUQPk5?filename=2.json");
            _safeMint(msg.sender, 3);
            _setTokenURI(3, "https://ipfs.io/ipfs/QmbhrvgBu1fMCNcHWX9Gu3Y38U4NADx82GKLrgpPTEy49W?filename=3.json");
            _safeMint(msg.sender, 4);
            _setTokenURI(4, "https://ipfs.io/ipfs/QmdYjjTYgiiWjzxgzVh1vr777uLD7UBs3P39MJaAUb9qpj?filename=4.json");

            tokenCounter = tokenCounter.add(5);
            
        }

        else if (tokenCounter > 0) {
            uint256 lastId = tokenCounter;
            while (tokenCounter < lastId.add(5)) {
                if (tokenCounter < MAX_TOKENS) {
                    newItemId = tokenCounter;
                    _safeMint(msg.sender, newItemId);
                    tokenCounter = tokenCounter.add(1);
                }
                else if (tokenCounter >= MAX_TOKENS) {
                    break;
                }
            }
        }
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        bytes memory uri_check = bytes(tokenURI(tokenId));

        if (uri_check.length == 0) {
            _setTokenURI(tokenId, _tokenURI);
        }
    }
}