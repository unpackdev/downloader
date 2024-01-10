// SPDX-License-Identifier: MIT
/**
.____                       .___                      _____                    
|    |   _____    ____    __| _/___________    ______/ ____\___________  ______
|    |   \__  \  /    \  / __ |/ __ \_  __ \  /     \   __\/ __ \_  __ \/  ___/
|    |___ / __ \|   |  \/ /_/ \  ___/|  | \/ |  Y Y  \  | \  ___/|  | \/\___ \ 
|_______ (____  /___|  /\____ |\___  >__|    |__|_|  /__|  \___  >__|  /____  >
        \/    \/     \/      \/    \/              \/          \/           \/ 
 */
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract LMFERS is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 6900;
    uint256 public constant MAX_PER_MINT = 10;
    
    address public constant w1 = 0x539d7B4eaAbF5d78a3482a549f05786a444A3153;
    address public constant w2 = 0xB7217E1378e30f58f50471F2Ce1413c88d559A42;
    address public constant w3 = 0xe5BAE101f36abDcf7e8B661D1021A8e5656Bb008; //dev wallet
    

    uint256 public price = 0.0096 ether;

    bool public publicSaleStarted = false;

    string public baseURI = "";

    constructor() ERC721A("Lander mfers", "LMFER", MAX_PER_MINT,MAX_TOKENS) {
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// Public Sale mint function
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "LMFER: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "LMFER: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "LMFER: Minting would exceed max supply");
        require(tokens > 0, "LMFER: Must mint at least one token");

        //first 900 free
        if (totalSupply() + tokens <= 900) {
            _safeMint(_msgSender(), tokens);
        } else {
            require(price * tokens == msg.value, "LMFER: ETH amount is incorrect");
            _safeMint(_msgSender(), tokens);
        }
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "LMFER: Insufficent balance");
        _widthdraw(w3, ((balance * 22) / 100));
        _widthdraw(w2, ((balance * 23) / 100));
        _widthdraw(w1, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "LMFER: Failed to widthdraw Ether");
    }
}