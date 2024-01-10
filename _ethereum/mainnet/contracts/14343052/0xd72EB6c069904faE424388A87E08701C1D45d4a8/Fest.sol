//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
          .          .           .     .                .       .
  .      .      *           .       .          .                       .
                 .       .   . *             August 12 - 14, 2022
  .       ____     .      . .            .       Idyllwild, CA
         >>         .        .               .
 .   .  /WWWI; \  .       .    .  ____               .         .     .         
  *    /WWWWII; \=====;    .     /WI; \   *    .        /\_             .
  .   /WWWWWII;..      \_  . ___/WI;:. \     .        _/M; \    .   .         .
     /WWWWWIIIIi;..      \__/WWWIIII:.. \____ .   .  /MMI:  \   * .
 . _/WWWWWIIIi;;;:...:   ;\WWWWWWIIIII;.     \     /MMWII;   \    .  .     .
  /WWWWWIWIiii;;;.:.. :   ;\WWWWWIII;;;::     \___/MMWIIII;   \              .
 /WWWWWIIIIiii;;::.... :   ;|WWWWWWII;;::.:      :;IMWIIIII;:   \___     *
/WWWWWWWWWIIIIIWIIii;;::;..;\WWWWWWIII;;;:::...    ;IMIII;;     ::  \     .
WWWWWWWWWIIIIIIIIIii;;::.;..;\WWWWWWWWIIIII;;..  :;IMIII;:::     :    \   
WWWWWWWWWWWWWIIIIIIii;;::..;..;\WWWWWWWWIIII;::; :::::::::.....::       \
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%XXXXXXX
▄████   ▄ ▄   ███       ▄████  ▄███▄     ▄▄▄▄▄      ▄▄▄▄▀ 
█▀   ▀ █   █  █  █      █▀   ▀ █▀   ▀   █     ▀▄ ▀▀▀ █    
█▀▀   █ ▄   █ █ ▀ ▄     █▀▀    ██▄▄   ▄  ▀▀▀▀▄       █    
█     █  █  █ █  ▄▀     █      █▄   ▄▀ ▀▄▄▄▄▀       █     
 █     █ █ █  ███        █     ▀███▀               ▀      
  ▀     ▀ ▀               ▀           
*/

import "./ERC721.sol";
import "./IERC2981.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./SignedAllowance.sol";

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract FWBFest is ERC721, IERC2981, Ownable, ReentrancyGuard, SignedAllowance {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI = 'https://fest.fwb.help/api';
    
    bool public isPublicSaleActive = false;
    bool public isSignedSaleActive = false;

    uint256 public MAX_TICKETS = 250; 
    uint256 public MAX_PER_WALLET = 1;
    uint256 public PUBLIC_SALE_PRICE = 0.5 ether;
    uint256 public ROYALTY = 10; // 10% - don't resell friends
    uint256 public FWB_THRESHOLD = 75000000000000000000; // 75 FWB
    address public FWB_ADDRESS = 0x35bD01FC9d6D5D81CA9E055Db88Dc49aa2c699A8; // FWB PRO

    // Modifiers

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier signedSaleActive() {
        require(isSignedSaleActive, "Sale is not open");
        _;
    }

    modifier canMintTicket() {
        require(
            tokenCounter.current() <=
                MAX_TICKETS,
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

    modifier hasFWB() {
        require(
            IERC20(FWB_ADDRESS).balanceOf(msg.sender) >= FWB_THRESHOLD,
            "You must hold FWB to purchase a ticket"
        );
        _;
    }

    modifier hasMinted() {
        require(
            balanceOf(msg.sender) < MAX_PER_WALLET,
            "This address has already minted a ticket."
        );
        _;
    }

    constructor() ERC721("FWB Fest", "FWBFEST") {}

    function mint()
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE)
        publicSaleActive
        hasFWB
        canMintTicket
        hasMinted
    {
        _safeMint(msg.sender, nextTokenId());
    }

    // Minty
    function mintSigned(uint256 nonce, bytes memory signature)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE)
        canMintTicket
        signedSaleActive
    {
        _useAllowance(msg.sender, nonce, signature);
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

    function getFWBBalance() external view returns (uint256) {
        return IERC20(FWB_ADDRESS).balanceOf(msg.sender);
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // Admin

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setFWBAddress(address _address) external onlyOwner {
        FWB_ADDRESS = _address;
    }

    function setThreshold(uint256 _num) external onlyOwner {
        FWB_THRESHOLD = _num;
    }

    function setNumTickets(uint256 _num) external onlyOwner {
        MAX_TICKETS = _num;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PUBLIC_SALE_PRICE = _price;
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

    // signature stuff

    function setIsSignedSaleActive(bool _isSignedSaleActive)
        external
        onlyOwner
    {
        isSignedSaleActive = _isSignedSaleActive;
    }

    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
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