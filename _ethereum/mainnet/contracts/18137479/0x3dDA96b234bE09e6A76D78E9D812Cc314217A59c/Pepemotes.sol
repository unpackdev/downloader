// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";

/**
https://pepemotes.fun
https://x.com/pepemotes
https://opensea.io/collection/pepemotes
⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣠⡶⠛⠉⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⢦⡀⠀⢀⣴⠞⠋⠉⠉⠉⠉⠙⠛⠶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢀⡾⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣶⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢠⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⠀⠸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠘⠀⠀⠀⠀⠀⠀⢀⣴⠖⠛⠋⠉⠉⠉⠉⠉⠉⠙⠛⠻⢦⣄⠀⠀⣀⣠⣤⣤⣤⣤⣤⣄⣀⠈⢷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢠⡾⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢻⣏⠉⠀⠀⠀⠀⠀⠀⠈⠉⠙⠲⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠻⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣀⣀⣀⣀⣤⣄⣤⣤⣄⣀⣀⣤⣀⡈⢷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⡈⢻⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⡴⠟⠉⣉⣉⣩⣭⣽⠥⠦⣤⣌⣉⠛⠿⢦⣄⠈⠛⢶⣗⠀⠀⠀⠀⠀⢰⣞⣻⣽⣽⣭⣭⣭⣽⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⡴⢋⣠⠾⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢦⣄⡙⢷⣄⠀⠹⣧⡀⠀⢀⡶⠟⣫⣭⢿⡿⠿⠿⠷⣦⡉⢻⣿⡄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢻⣧⣾⣁⣤⡤⠴⠶⠖⣶⣶⣶⣶⣶⣶⣶⣶⠒⠛⠛⠳⣿⢷⣤⢺⣇⠀⠉⣢⣿⣿⣿⣾⣶⣶⣦⣄⡀⠹⣾⡏⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠉⠙⡳⠶⣄⣼⣿⣷⢾⣿⡟⠋⠛⣿⡇⠀⠀⠀⠈⣷⠘⢷⡟⢀⡾⣿⣿⣩⣿⣿⠿⢿⣧⠈⠙⠳⢾⣇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⡈⠻⢿⣿⣼⣿⣷⣦⣾⣿⠇⠀⠀⠀⠀⠘⣧⢸⢣⡟⠀⣿⣿⣟⣿⣿⣤⣾⡿⠀⢀⣴⢿⡟⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⣀⠀⠉⠉⠛⠿⠿⠿⢤⣤⣤⡴⠖⠛⢉⣿⠈⢹⡓⢿⠿⠿⠿⠿⠿⠿⠷⠞⠋⣡⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠛⠛⠛⠛⠳⠶⠤⠴⠶⢤⣴⠾⠋⠁⠀⠈⠛⠶⣤⡤⠤⠴⠆⢀⡾⢷⣾⢯⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣴⡶⠶⠖⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠈⢳⣄⠀⠀⠛⠛⠛⠁⠀⢻⣆⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣀⣠⣴⡶⠾⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⠶⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢧⠀⠀⠀⠀⠀⠀⠀⣿⣦⠀⠀⠀⠀⠀⠀⠀
⠀⣼⢏⣿⠛⠿⠶⢤⣄⣀⡀⠀⠀⠀⠀⠐⠻⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠇⢸⡇⠀⠀⠀⠀⠀⠀
⠀⠈⠘⣿⣄⠘⢷⣄⣀⠉⠙⠛⠒⠲⠶⣤⣤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡾⠃⣠⡟⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠈⠙⠷⣄⣈⠉⠙⠳⠶⢤⣄⣀⡀⠀⠀⠉⠉⠉⠛⠛⠳⠶⠶⠶⠶⠶⠶⠤⢤⣤⣤⣤⣤⣤⣤⡤⠶⠾⠋⣠⣾⡋⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠙⠛⢦⣄⡀⠀⠈⠉⠙⠛⠛⠛⠛⠛⠛⠶⢦⣤⣤⣤⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣤⠾⠋⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠳⢶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⣰⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠶⠦⠤⠤⢤⣄⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣠⣤⣄⣀⣀⣠⡤⠞⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⣉⣭⣉⠁⠀⣠⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⡶⠛⠉⠉⠙⢷⣴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡴⠛⠁⠀⠀⠀⠀⠀⠀⠹⠦⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡶⠒⠳⣦⠾⠛⢷⡄⠀⠀⣠⡴⢶⣤⣄⠀⣠⡌⠙⠷⣄⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣄⠀⠀⠹⣦⣠⣾⣃⡴⠟⢁⡼⢋⣴⣯⠞⠋⠀⠀⠀⠈⠻⣆⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⡀⠀⠈⠉⢿⠁⢠⡼⣋⡴⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠙⢷⡄⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⡄⠀⠀⢸⣶⢋⣼⠋⠀⠀⠀⠀⣀⡴⠟⠀⠀⠀⠀⠀⠀⢻⣄⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠙⠿⣧⡀⠀⠀⠀⣴⠏⠀⠀⠀⢀⣴⠆⠀⢀⠀⠻⣆⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣇⠀⠀⠀⠀⠀⠈⠻⣦⣤⣼⠃⠀⠀⢀⣠⠞⠁⠀⣠⡾⠀⠀⠻⡆
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠟⠃⠹⠗⠀⠀⠀⠀⠀⠀⠀⠀⠙⠓⠀⠀⠾⠃⠀⠀⠸⠋⠀⠀⠀⠀⠿
 */

error TokenURINotAvailable();
error WithdrawTransfer();
contract Pepemotes is ERC721Enumerable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public baseURI;
    uint256 public price = 0.0 ether;
    uint256 public constant MAX_SUPPLY = 1_234;
    Counters.Counter private _totalTokensMinted;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) { }

    modifier isUser() {
        require(tx.origin == msg.sender, "Invalid User");
        _;
    }

    modifier mintCompliance() {
        require(totalSupply() < MAX_SUPPLY, 'Max Supply Exceeded!');
        _;
    }

    function mintPonzi() public payable nonReentrant isUser mintCompliance {
        require(msg.value >= price, 'Insufficient Funds!');
        uint256 tokenId = _totalTokensMinted.current() + 1;
        _safeMint(msg.sender, tokenId);
        _totalTokensMinted.increment();
        if (tokenId >= 123 && tokenId < 456) {
            price = 0.00123 ether;
        }
        if (tokenId >= 456 && tokenId < 789) {
            price = 0.00369 ether;
        }
        if (tokenId >= 789) {
            price = 0.00420 ether;
        }
    }

    function mint() 
        public
        onlyOwner {
        for(uint i = 0; i < 50; i++){
            uint256 tokenId = _totalTokensMinted.current() + 1;
            _safeMint(msg.sender, tokenId);
            _totalTokensMinted.increment();
        }
    } 

    function totalSupply() public view override returns (uint256) {
        return _totalTokensMinted.current();
    }

    function setURI(string memory uri) 
        public
        onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) {
            revert TokenURINotAvailable();
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdrawPayments(address payable payee) 
        external 
        onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}
