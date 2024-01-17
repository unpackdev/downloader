//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./Owned.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract ShowArt is ERC721A, Owned {
    using Strings for uint256;

    string public baseURI;
    bool public paused;
    bool public eventFinished;
    mapping (address => bool) minted;

    constructor()ERC721A("Show Art POAP", "SHOW")Owned(msg.sender){}   

    function claim() public payable {
        require(!paused, "Claiming paused");
        require(!eventFinished, "Event has finished");
        require(!minted[msg.sender], "Address already minted");
        require(msg.value == 0, "Free POAP claim");
        minted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    receive() external payable {
      claim();
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function finishEvent() external onlyOwner {
        eventFinished = true;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "This token does not exist");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function withdraw() external onlyOwner {
        assembly {
            let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
            switch result
            case 0 { revert(0, 0) }
            default { return(0, 0) }
        }
    }
}