// SPDX-License-Identifier: UNLICENSED

/*
 ________  ________  ________  ________  ________  ________  ___           ___    ___      ________  ________  _________   
|\   __  \|\   __  \|\   __  \|\   __  \|\   __  \|\   __  \|\  \         |\  \  /  /|    |\   __  \|\   __  \|\___   ___\ 
\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\ /\ \  \|\  \ \  \|\ /\ \  \        \ \  \/  / /    \ \  \|\  \ \  \|\  \|___ \  \_| 
 \ \   ____\ \   _  _\ \  \\\  \ \   __  \ \   __  \ \   __  \ \  \        \ \    / /      \ \   __  \ \   _  _\   \ \  \  
  \ \  \___|\ \  \\  \\ \  \\\  \ \  \|\  \ \  \ \  \ \  \|\  \ \  \____    \/  /  /        \ \  \ \  \ \  \\  \|   \ \  \ 
   \ \__\    \ \__\\ _\\ \_______\ \_______\ \__\ \__\ \_______\ \_______\__/  / /           \ \__\ \__\ \__\\ _\    \ \__\
    \|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|_______|\|_______|\___/ /             \|__|\|__|\|__|\|__|    \|__|
                                                                         \|___|/                                                                                                                                                                                                                                                                                                                                                                                    
*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ProbablyART is ERC721A, Ownable {
    bool public saleEnabled;
    string public metadataBaseURL;

    uint256 public constant MAX_SUPPLY = 2222;
    mapping(address => bool) public claims;

    constructor() ERC721A("Probably ART", "ART", 2222) {
        saleEnabled = false;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }

    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens == 1, "Must mint 1 token");
        require(!claims[msg.sender], "Wallet already claimed");

        claims[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }
}
