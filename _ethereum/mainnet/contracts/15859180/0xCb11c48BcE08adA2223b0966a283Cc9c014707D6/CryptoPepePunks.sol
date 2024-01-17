//Frogtober 2022
// ▄▄▄▄▄▄▄ ▄▄▄▄▄▄   ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄    ▄ ▄▄▄   ▄ ▄▄▄▄▄▄▄ 
//█       █   ▄  █ █  █ █  █       █       █       █       █       █       █       █       █  █ █  █  █  █ █   █ █ █       █
//█       █  █ █ █ █  █▄█  █    ▄  █▄     ▄█   ▄   █    ▄  █    ▄▄▄█    ▄  █    ▄▄▄█    ▄  █  █ █  █   █▄█ █   █▄█ █  ▄▄▄▄▄█
//█     ▄▄█   █▄▄█▄█       █   █▄█ █ █   █ █  █ █  █   █▄█ █   █▄▄▄█   █▄█ █   █▄▄▄█   █▄█ █  █▄█  █       █      ▄█ █▄▄▄▄▄ 
//█    █  █    ▄▄  █▄     ▄█    ▄▄▄█ █   █ █  █▄█  █    ▄▄▄█    ▄▄▄█    ▄▄▄█    ▄▄▄█    ▄▄▄█       █  ▄    █     █▄█▄▄▄▄▄  █
//█    █▄▄█   █  █ █ █   █ █   █     █   █ █       █   █   █   █▄▄▄█   █   █   █▄▄▄█   █   █       █ █ █   █    ▄  █▄▄▄▄▄█ █
//█▄▄▄▄▄▄▄█▄▄▄█  █▄█ █▄▄▄█ █▄▄▄█     █▄▄▄█ █▄▄▄▄▄▄▄█▄▄▄█   █▄▄▄▄▄▄▄█▄▄▄█   █▄▄▄▄▄▄▄█▄▄▄█   █▄▄▄▄▄▄▄█▄█  █▄▄█▄▄▄█ █▄█▄▄▄▄▄▄▄█
//A collection of Pepe characters on the blockchain.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Psi.sol";
import "./Ownable.sol";

contract CryptoPepePunks is ERC721Psi, Ownable {

    uint256 public maxPepes = 10000;
    uint256 public publicPepes = 9000;
    uint256 public privatePepes = 1000;
    uint256 public publicMaxMint = 5;
    uint256 public privateMintTotal = 0;
    bool public Active = false;
    mapping(address => uint256) public howmanyminted;

    string public metaURI = "ipfs://bafybeifctik2dz3abrlq4qlas4xr7uzmtvlhbxb244jdumfooh7xg4csfa/";

    constructor() 
        ERC721Psi ("CryptoPepePunks", "CPP"){} 
    
    function _baseURI() internal view virtual override returns (string memory) {
        return metaURI;
    }
    
    function freeMint(uint256 quantity) external payable {
       
        require(Active, "Sale paused.");
        uint256 totalPepes = totalSupply();
        require(msg.sender == tx.origin);
        require(totalPepes < maxPepes, "CryptoPepePunks mint is sold out.");
        require(totalPepes <= publicPepes, "CryptoPepePunks public mint is sold out.");
        require(howmanyminted[msg.sender] < publicMaxMint, "You have already max minted.");
        require(howmanyminted[msg.sender] + quantity <= publicMaxMint, "You have exceeded the maximum allowed per wallet, lower mint amount and try again.");
        require(totalPepes + quantity <= (publicPepes + privateMintTotal), "Public supply exceeded, lower mint quantity and try again.");

        // _safeMint's second argument now takes in a quantity, not a tokenId. (same as ERC721A)
        _safeMint(msg.sender, quantity);
        howmanyminted[msg.sender] += quantity;
    }

    function privateMint(address sendTo, uint256 howMany) external onlyOwner {

        uint256 totalPepes = totalSupply();
        require(totalPepes < maxPepes, "CryptoPepePunks mint is sold out.");
        require(privateMintTotal < privatePepes, "You have already minted 1000.");
        require(privateMintTotal + howMany <= privatePepes, "Private supply exceeded, lower mint quantity and try again.");
        require(totalPepes + howMany <= maxPepes, "CryptoPepePunks supply exceeded, lower mint quantity and try again.");

        // _safeMint's second argument now takes in a quantity, not a tokenId. (same as ERC721A)
        _safeMint(sendTo, howMany);
        privateMintTotal += howMany;
    }

    function Sale(bool _status) external onlyOwner {
        Active = _status;
    }

    function setMaxMint(uint256 _max) external onlyOwner {
        publicMaxMint = _max;
    }

    function setMetaURI(string memory loc) external onlyOwner {
        metaURI = loc;
    }

    function withdrawal() public payable onlyOwner {
	    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

}
