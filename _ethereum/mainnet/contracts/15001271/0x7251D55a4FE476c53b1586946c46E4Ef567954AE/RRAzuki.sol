/**
____________  ___   _______   _ _   _______ 
| ___ \ ___ \/ _ \ |___  / | | | | / /_   _|
| |_/ / |_/ / /_\ \   / /| | | | |/ /  | |  
|    /|    /|  _  |  / / | | | |    \  | |  
| |\ \| |\ \| | | |./ /__| |_| | |\  \_| |_ 
\_| \_\_| \_\_| |_/\_____/\___/\_| \_/\___/ 
*/                                            

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
                                            
contract RRAZUKI is ERC721A,Ownable,ReentrancyGuard {
    uint public MAX_PER_WALLET = 10;
    uint public MAX_SUPPLY = 10000;
    string private baseUri_;


    constructor() ERC721A("Azuki","AZUKI") {}

    /**
     * non payable :wink:
     */
    function mint(uint _amount) external nonReentrant {
        address sender = msg.sender;
        require(_numberMinted(sender) + _amount <= MAX_PER_WALLET, "your cap reached");
        require(_totalMinted() + _amount <= MAX_SUPPLY,"sold out");
        _mint(sender,_amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri_;
    }

    function setBaseUri(string calldata _uri) external onlyOwner {
        baseUri_ = _uri;
    }

    function setMaxPerWallet(uint _amount) external onlyOwner {
        MAX_PER_WALLET = _amount;
    }
}