//SPDX-License-Identifier: MIT

// @title: Code Boy Sai: Listening Pass
// @author: @spencerobsitnik

///  ________  ________  ________  _______   ________  ________      ___    ___      ________  ________  ___            
/// |\   ____\|\   __  \|\   ___ \|\  ___ \ |\   __  \|\   __  \    |\  \  /  /|    |\   ____\|\   __  \|\  \           
/// \ \  \___|\ \  \|\  \ \  \_|\ \ \   __/|\ \  \|\ /\ \  \|\  \   \ \  \/  / /    \ \  \___|\ \  \|\  \ \  \          
///  \ \  \    \ \  \\\  \ \  \ \\ \ \  \_|/_\ \   __  \ \  \\\  \   \ \    / /      \ \_____  \ \   __  \ \  \         
///   \ \  \____\ \  \\\  \ \  \_\\ \ \  \_|\ \ \  \|\  \ \  \\\  \   \/  /  /        \|____|\  \ \  \ \  \ \  \        
///    \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\__/  / /            ____\_\  \ \__\ \__\ \__\       
///     \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|\___/ /            |\_________\|__|\|__|\|__|       
///                                                                \|___|/             \|_________|                     


//  _____ ______   ________      _____ ______           ___       ________  ________  ___  __    ________              
// |\   _ \  _   \|\   __  \    |\   _ \  _   \        |\  \     |\   __  \|\   __  \|\  \|\  \ |\   ____\             
// \ \  \\\__\ \  \ \  \|\  \  /\ \  \\\__\ \  \       \ \  \    \ \  \|\  \ \  \|\  \ \  \/  /|\ \  \___|_            
//  \ \  \\|__| \  \ \__     \/  \ \  \\|__| \  \       \ \  \    \ \  \\\  \ \  \\\  \ \   ___  \ \_____  \           
//   \ \  \    \ \  \|_/  __     /\ \  \    \ \  \       \ \  \____\ \  \\\  \ \  \\\  \ \  \\ \  \|____|\  \          
//    \ \__\    \ \__\/  /_|\   / /\ \__\    \ \__\       \ \_______\ \_______\ \_______\ \__\\ \__\____\_\  \         
//     \|__|     \|__/_______   \/  \|__|     \|__|        \|_______|\|_______|\|_______|\|__| \|__|\_________\        
//                   |_______|\__\                                                                 \|_________|        
//                           \|__|                                                                                     


//  ________  ________  ___       __   _______   ________  _______   ________          ________      ___    ___        
// |\   __  \|\   __  \|\  \     |\  \|\  ___ \ |\   __  \|\  ___ \ |\   ___ \        |\   __  \    |\  \  /  /|___    
// \ \  \|\  \ \  \|\  \ \  \    \ \  \ \   __/|\ \  \|\  \ \   __/|\ \  \_|\ \       \ \  \|\ /_   \ \  \/  / /\__\   
//  \ \   ____\ \  \\\  \ \  \  __\ \  \ \  \_|/_\ \   _  _\ \  \_|/_\ \  \ \\ \       \ \   __  \   \ \    / /\|__|   
//   \ \  \___|\ \  \\\  \ \  \|\__\_\  \ \  \_|\ \ \  \\  \\ \  \_|\ \ \  \_\\ \       \ \  \|\  \   \/  /  /     ___ 
//    \ \__\    \ \_______\ \____________\ \_______\ \__\\ _\\ \_______\ \_______\       \ \_______\__/  / /      |\__\
//     \|__|     \|_______|\|____________|\|_______|\|__|\|__|\|_______|\|_______|        \|_______|\___/ /       \|__|
//                                                                                                 \|___|/             


//  ________  ________  ________  _______           ___       ___  ________ _______                                    
// |\   ____\|\   __  \|\   ___ \|\  ___ \         |\  \     |\  \|\  _____\\  ___ \                                   
// \ \  \___|\ \  \|\  \ \  \_|\ \ \   __/|        \ \  \    \ \  \ \  \__/\ \   __/|                                  
//  \ \  \    \ \  \\\  \ \  \ \\ \ \  \_|/__       \ \  \    \ \  \ \   __\\ \  \_|/__                                
//   \ \  \____\ \  \\\  \ \  \_\\ \ \  \_|\ \       \ \  \____\ \  \ \  \_| \ \  \_|\ \                               
//    \ \_______\ \_______\ \_______\ \_______\       \ \_______\ \__\ \__\   \ \_______\                              
//     \|_______|\|_______|\|_______|\|_______|        \|_______|\|__|\|__|    \|_______|                              


//  ________  _______   ________  ________  ________  ________  ________           ________  ________  ________        
// |\   __  \|\  ___ \ |\   ____\|\   __  \|\   __  \|\   ___ \|\   ____\         |\   ___ \|\   __  \|\   __  \       
// \ \  \|\  \ \   __/|\ \  \___|\ \  \|\  \ \  \|\  \ \  \_|\ \ \  \___|_        \ \  \_|\ \ \  \|\  \ \  \|\  \      
//  \ \   _  _\ \  \_|/_\ \  \    \ \  \\\  \ \   _  _\ \  \ \\ \ \_____  \        \ \  \ \\ \ \   __  \ \  \\\  \     
//   \ \  \\  \\ \  \_|\ \ \  \____\ \  \\\  \ \  \\  \\ \  \_\\ \|____|\  \        \ \  \_\\ \ \  \ \  \ \  \\\  \    
//    \ \__\\ _\\ \_______\ \_______\ \_______\ \__\\ _\\ \_______\____\_\  \        \ \_______\ \__\ \__\ \_______\   
//     \|__|\|__|\|_______|\|_______|\|_______|\|__|\|__|\|_______|\_________\        \|_______|\|__|\|__|\|_______|   
//                                                                \|_________|                                         


pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract CBSaiListeningPass is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _tokenCount;

    string private _tokenUriBase;
    uint256 public _maxPasses = 1302;
    uint256 public _mintPrice = 0 ether;

    mapping(address => bool) private _minted;

    bool public _saleActive;


    constructor() ERC721("CB Sai Listening Pass", "SAILP") {
        _saleActive = false;
        _tokenUriBase = "ipfs://bafybeianavycqderkflhuuxptkzvbv3rk27u7lnkaj7kedikobcs7hwrli";
    }

    modifier canMint(address minter) {
        require (
            _saleActive,
            "Sale not active"
        );
        require (
            _tokenCount.current() + 1 <= _maxPasses,
            "Not enough passes remaining to mint"
        );
        if (_msgSender() != owner()) {
            require (
                _minted[minter] != true,
                "Only 1 mint per address"
            );
        }
        _;
    }

    modifier isCorrectPayment(uint256 price) {
        require(
            msg.value >= _mintPrice,
            "Incorrect ETH value sent"
        );
        _;
    }

    // ------- Public read-only function --------
    function getBaseURI() external view returns (string memory) {
        return _tokenUriBase;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(_tokenUriBase, "/", tokenId.toString(), ".json"));
    }
    // ------------------------------------------

    function mint()
        external
        payable
        nonReentrant
        isCorrectPayment(_mintPrice)
        canMint(_msgSender())
    {
        _tokenCount.increment();
        _safeMint(_msgSender(), _tokenCount.current());
        _minted[_msgSender()] = true;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenUriBase = baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function setSaleActive(bool active) external onlyOwner {
        _saleActive = active;
    }

    function setMaxPasses(uint256 newPasses) external onlyOwner {
        require (
            newPasses >= _tokenCount.current(),
            "Burning is the only way to destroy NFTs"
        );
        _maxPasses = newPasses;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }
}