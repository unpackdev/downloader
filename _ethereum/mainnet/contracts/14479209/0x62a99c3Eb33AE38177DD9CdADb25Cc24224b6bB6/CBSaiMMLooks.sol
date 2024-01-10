//SPDX-License-Identifier: MIT

// @title: Code Boy Sai: Looks
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

contract CBSaiMMLooks is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _publicCount;
    Counters.Counter public _privateCount;

    string public _tokenUriBase;
    bool public _saleActive;
    bool private _publicSaleActive;
    uint256 public _mintPricePublic = 0.08 ether;
    uint256 public _mintPricePrivate = 0.08 ether;
    uint256 public _maxPublicCharacters = 7152;
    uint256 public _maxPrivateCharacters = 150;

    IERC721 private _lp;
    
    mapping(address => bool) private _freeMintList;

    mapping(address => bool) private _allowPrivate;


    constructor() ERC721("CB Sai M&M Looks", "SAIL") {
        _publicCount.set(150);
        _saleActive = false;
        _publicSaleActive = false;

        _freeMintList[0x8F4359D1C2166452b5e7a02742D6fe9ca5448FDe] = true;
        _freeMintList[0xA10B19B6C7EE9A4d36d4Cc37b93A296c11Ee3186] = true;
        _freeMintList[0xc91d295CaC60A94Bd95166E17878D6e19a429df1] = true;
        _freeMintList[0x30C6d8b93b954b42844CAF0f8D4421BC09f26DAe] = true;
        _freeMintList[0xB2554D16D63895df1aa04Af06B67f7c2F5FfC0cA] = true;
        
        _freeMintList[0x1D877866D725A2CB21f4599F1eD1fb7671B65189] = true;
        _freeMintList[0xD2f482e43f8fFa6460831f779D5a10050620C559] = true;
        _freeMintList[0x796e6184dd58f81963441c0879AB8249fe380514] = true;
        _freeMintList[0x8be2c123863e44166Db615E33f0769213888879d] = true;
        _freeMintList[0x407c2668808D5D9e8d91dBBc09685C6836804b9a] = true;
    
        _freeMintList[0x3EF442C01cABA5133C098C2047548bae6948907d] = true;
        _freeMintList[0x8A5016858402cB19c3DA59A07b5E188eE7FDC655] = true;
        _freeMintList[0xE97AfE38e3f32518AAC5730e7a2934B196AdCEde] = true;
        _freeMintList[0x6eEDbAE25fc976FbD14eB683d7E4F90737ac88E7] = true;
        _freeMintList[0xd4328D2511Fe87071C13962F3a6b498D592B0AF5] = true;
        
        _freeMintList[0x125d27c9F05d821b6be61c672B6296de858E04E5] = true;
        _freeMintList[0x38A1B646E30dBFFEdA48d7DdF339Dd75A09bbB8B] = true;
        _freeMintList[0x859256df682A8412A393b07bB7c516222DD0627C] = true;
        _freeMintList[0x9EC04B702018565a06aC31dD9Fa70D38FeFd2F63] = true;
        _freeMintList[0xD2f793D5f65449e6992e0c9c52A7334b62e5ec6c] = true;
        
        _freeMintList[0x10901E43CA063eec45EdEEF4C0D16bE43b9d3732] = true;
        _freeMintList[0x966E086DAC6F9a2A90F3348B7683B581743901eB] = true;
        _freeMintList[0x66D49b854a7cAf28df45B4Fb8e47ad727d307926] = true;
        _freeMintList[0x4392113A9B9d3664a9d7e0d1B135142970835549] = true;
        _freeMintList[0x0Ffd5A9659b011B448fBdEACEEE480879bD60aF0] = true;
        
        // set address of listening pass
        _lp = IERC721(0x83BEB7F96a464805F170b881883b97eB8FD64e8D);
        // set ipfs base url
        _tokenUriBase = "ipfs://bafybeidg366yin3dlmro2mou4zdclvepxuwrddxni6kyrpxm7aims6h66m";
    }

    modifier canMintPublic() {
        require(
            _saleActive,
            "Sale not active"
        );
        if (!_publicSaleActive) {
            require(
                _lp.balanceOf(_msgSender()) >= 1,
                "Must hold listening pass to pre mint"
            );
        }
        require(
            _publicCount.current() + 1 <= _maxPublicCharacters,
            "Not enough passes remaining to mint"
        );
        _;
    }

    modifier canMintPrivate() {
        require(
            _msgSender() == owner() || ((_allowPrivate[_msgSender()] && _saleActive)),
            "Not allowed to mint private"
        );
        require(
            _privateCount.current() + 1 <= _maxPrivateCharacters,
            "Not enough passes remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price) {
        require(
            msg.value >= price,
            "Incorrect ETH value sent"
        );
        _;
    }
    
    modifier canMintFree() {
        require(
            _freeMintList[_msgSender()],
            "Not for free"
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

    function mint() external payable nonReentrant canMintPublic isCorrectPayment(_mintPricePublic) {
        _publicCount.increment();
        _safeMint(_msgSender(), _publicCount.current());
    }
    
    function mintPrivate() external payable nonReentrant canMintPrivate isCorrectPayment(_mintPricePrivate) {
        _privateCount.increment();
        _safeMint(_msgSender(), _privateCount.current());
    }
    
    function freeMint() external payable nonReentrant canMintPublic canMintFree {
        _freeMintList[_msgSender()] = false;
        _publicCount.increment();
        _safeMint(_msgSender(), _publicCount.current());
    }

    // ------- Owner functions --------
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenUriBase = baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function setSale(bool saleActive) external onlyOwner {
        _saleActive = saleActive;
    }

    function setPublicSale(bool saleActive) external onlyOwner {
        _publicSaleActive = saleActive;
    }

    function allowPrivateSale(address a) external onlyOwner {
        _allowPrivate[a] = true;
    }

    function allowPrivateSale(address[] memory a) external onlyOwner {
        for (uint256 i = 0; i < a.length; i++) {
            _allowPrivate[a[i]] = true;
        }
    }

    function toggleAllowPrivateSale(address a, bool allow) external onlyOwner {
        _allowPrivate[a] = allow;
    }

    function changeMintPricePublic(uint256 price) external onlyOwner {
        _mintPricePublic = price;
    }

    function changeMintPricePrivate(uint256 price) external onlyOwner {
        _mintPricePrivate = price;
    }

    function changeLPAddress(address newAddress) external onlyOwner {
        _lp = IERC721(newAddress);
    }
    
    function toggleFreeMintAddress(address a, bool allow) external onlyOwner {
        _freeMintList[a] = allow;
    }

    function setMaxPasses(uint256 newPasses) external onlyOwner {
        require (
            newPasses >= _publicCount.current(),
            "Burning is the only way to destroy NFTs"
        );
        _maxPublicCharacters = newPasses;
    }
    // ------------------------------------------
}