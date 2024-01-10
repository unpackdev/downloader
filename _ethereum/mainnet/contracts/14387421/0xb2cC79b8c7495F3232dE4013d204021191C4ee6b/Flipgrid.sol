//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                                                                       .:::::=. 
                                                                     =+=::::-:  
                 :=    .--=::--:-=::+-:=-:--                       .=      =    
                .:== :=-:+:.-+..*::+-:-*:-*:::::::::::.           :=:::::-*     
                --:::-+.        :=        --          .--.      .=+::::::+      
   ..     .:::-:      :-         .=        .=            :---::-.       .-      
  .=-*-:::.    :-+*=-  -:         :-        .=             .+:::::::::::*.      
   +.:+=       .-=+--   --.....::::*          +::::::::::::-+:::::::::::*       
   =: ==                =:..      :=         -:            :+:::        :=      
  =..=:......         --         --        --            --     -*:::::::+      
   -=:.   ...:::--  .=.         =.       :=           .--        .*::::::-+     
                  -:+::::::::=:+=::::::--+--:=:=:=-==:.           .=      :=    
                             =  --         =:+===-+:+               +=:::::-=   
                              =. .=.                                 .::::::-:  
                               :-: -:                                           
                                  ::-                                           
                                                                              

 ######   ##        ####    #####              ####    #####     ####    ####    
 ##       ##         ##     ##  ##            ##  ##   ##  ##     ##     ## ##   
 ##       ##         ##     ##  ##            ##       ##  ##     ##     ##  ##  
 ####     ##         ##     #####             ## ###   #####      ##     ##  ##  
 ##       ##         ##     ##                ##  ##   ####       ##     ##  ##  
 ##       ##         ##     ##                ##  ##   ## ##      ##     ## ##   
 ##       ######    ####    ##                 ####    ##  ##    ####    ####        
*/

import "./ERC721.sol";
import "./IERC2981.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";


interface InfiniteGrid {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Flipgrid is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI = 'https://infinitegrid.art/api/flipgrid';
    
    bool public isPublicSaleActive = false;
    bool public isGridSaleActive = false;

    uint256 public MAX_SUPPLY = 60; 
    uint256 public MAX_PER_WALLET = 1;
    uint256 public PUBLIC_SALE_PRICE = 0.1 ether;
    uint256 public ROYALTY = 5; // 10% - don't resell friends
    uint256 public GRID_THRESHOLD = 1; // 1 Grid
    address public GRID_ADDRESS = 0x78898ffA059D170F887555d8Fd6443D2ABe4E548; // Infinite Grid

    // Modifiers

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier gridSaleActive() {
        require(isGridSaleActive, "Grid sale is not open");
        _;
    }

    modifier canMintToken() {
        require(
            tokenCounter.current() <=
                MAX_SUPPLY,
            "Not enough tickets remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price) {
        require(
            price <= msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier hasGrid() {
        require(
            InfiniteGrid(GRID_ADDRESS).balanceOf(msg.sender) >= GRID_THRESHOLD,
            "You must hold an Infinte Grid to purchase a Flipgrid."
        );
        _;
    }

    modifier hasMinted() {
        require(
            balanceOf(msg.sender) < MAX_PER_WALLET,
            "This address has already minted."
        );
        _;
    }

    constructor() ERC721("Flip Grid 01", "FLIPGRID01") {
    }

    function mint()
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE)
        gridSaleActive
        hasGrid
        canMintToken
        hasMinted
    {
        _safeMint(msg.sender, nextTokenId());
    }

    function mintPublic()
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE)
        publicSaleActive
        canMintToken
    {
        _safeMint(msg.sender, nextTokenId());
    }


    function mintOwner(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // Public

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // Admin

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setGridAddress(address _address) external onlyOwner {
        GRID_ADDRESS = _address;
    }

    function setThreshold(uint256 _num) external onlyOwner {
        GRID_THRESHOLD = _num;
    }

    function setMaxPerWallet(uint256 _max) external onlyOwner {
        MAX_PER_WALLET = _max;
    }

    function setRoyalty(uint256 _royalty) external onlyOwner {
        ROYALTY = _royalty;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsGridSaleActive(bool _isGridSaleActive)
        external
        onlyOwner
    {
        isGridSaleActive = _isGridSaleActive;
    }

    // Counter stuff

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // Royalties

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString()));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, ROYALTY), 100));
    }
}