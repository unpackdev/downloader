// SPDX-License-Identifier: MIT
/**
 * @title WAAGTC
 * @author purpleeggmilk
 */

/*                                
                                                                                __ _.--..--._ _
                                                                             .-' _/   _/\_   \_'-.
                                                                            |__ /   _/\__/\_   \__|
 ___       __   ________  ________  ________ _________  ________               |___/\_\__/  \___
|\  \     |\  \|\   __  \|\   __  \|\   ____\\___   ___\\   ____\                     \__/
\ \  \    \ \  \ \  \|\  \ \  \|\  \ \  \___\|___ \  \_\ \  \___|                     \__/
 \ \  \  __\ \  \ \   __  \ \   __  \ \  \  ___  \ \  \ \ \  \                         \__/
  \ \  \|\__\_\  \ \  \ \  \ \  \ \  \ \  \|\  \  \ \  \ \ \  \____                     \__/
   \ \____________\ \__\ \__\ \__\ \__\ \_______\  \ \__\ \ \_______\                ____\__/___
    \|____________|\|__|\|__|\|__|\|__|\|_______|   \|__|  \|_______|          . - '             ' -.
                                                                              /                      \
~~~~~~~  ~~~~~ ~~~~~  ~~~ ~~~  ~~~~~~~~~~~~  ~~~~~ ~~~~~  ~~~ ~~~  ~~~~~~~~~~~~  ~~~~~ ~~~~~  ~~~ ~~~  ~~~~~
*/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";


contract WAAGTC is ERC721A, Ownable, ReentrancyGuard {
    bool public publicSale = false;
    bool public whitelistSale = false;
    bool public revealed = false;

    uint256 public constant MAX_PER_TX = 20;
    uint256 public constant MAX_PER_ADDRESS = 100;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 0.03 ether;

    string private baseTokenURI = 
        "ipfs://QmPdavwSVb869J5MuGcjNs87gXjZWJuaFHoLmNUQ1Qv972/";
    string public notRevealedUri = 
        "ipfs://QmdqZbwinpJo885AaWaqcE9JCPsen6KpYU8pYU5fWKU6Fu/";

    bytes32 root;

    constructor() ERC721A("We Are All Going to California", "WAAGTC") {}

    mapping (address => bool) public freeMinted;

    mapping (address => bool) public whitelistIndex;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function checkIfFreeminted(address owner) 
        public 
        view 
        returns (bool) 
    {
        if (freeMinted[owner]) 
        {
            return true;
        } 
        else 
        {
            return false;
        }
    }

    function checkIfWhitelisted(address owner)
        public
        view
        returns (bool)
    {
        if (whitelistIndex[owner])
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    function numberMinted(address owner) 
        public 
        view 
        returns (uint256) 
    {
        return _numberMinted(owner);
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        require(
            _exists(tokenId),
            "Your URI query is for a nonexistent token, man."
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }

    function mint(uint256 quantity) 
        external 
        payable callerIsUser 
    {

        require(
            whitelistSale || publicSale, "nahhh dude, sale hasn't started"
        );

        require(
            numberMinted(msg.sender) + quantity <= MAX_PER_ADDRESS, 
            "I told you man, can't get no more"
        );

        require(
            quantity > 0, 
            "you gotta mint at least one"
        );

        require(
            quantity <= MAX_PER_TX, 
            "save some for the rest of us dude"
        );

        require(
            totalSupply() + quantity < MAX_SUPPLY, 
            "sorry broski, we're all out!"
        );

        if (whitelistSale && !publicSale) {
            require(
                whitelistIndex[msg.sender] == true, 
                "back of the line, brochacho!"
            );
        }

        if(freeMinted[msg.sender]){
            require(
                msg.value >= PRICE * quantity, 
                "don't got enough cash, man"
            );
        } else {
            require(
                msg.value >= (PRICE * quantity) - PRICE, 
                "don't got enough cash, man"
            );

            freeMinted[msg.sender] = true;
        }

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address _address, uint256 quantity) 
        external onlyOwner 
    {
        require(
            totalSupply() + quantity <= MAX_SUPPLY, 
            "sorry bossman, we don't got it"
        );

        _safeMint(_address, quantity);
    }

    function _baseURI()     
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseTokenURI;
    }

    function addWhitelistMember(address _address)
        external onlyOwner 
    {
        whitelistIndex[_address] = true;
    }

    function setRoot(bytes32 _root) 
        external onlyOwner 
    {
        root = _root;
    }

    function togglePublicSaleState() 
        external onlyOwner 
    {
        publicSale = !publicSale;
    }

    function toggleWhitelistState() 
        external onlyOwner 
    {
        whitelistSale = !whitelistSale;
    }

    function setBaseURI(string calldata baseURI) 
        external onlyOwner 
    {
        baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) 
        external onlyOwner 
    {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() 
        external onlyOwner 
    {
        revealed = !revealed;
    }

    function withdraw() 
        external onlyOwner 
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}
