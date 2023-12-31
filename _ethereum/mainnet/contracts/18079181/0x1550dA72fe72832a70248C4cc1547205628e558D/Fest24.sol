// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*
          .          .           .     .                .       .
  .      .      *           .       .          .                       .
                 .       .   . *                 FWB FEST 2024
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

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Fest24 is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI =
        "https://bronze-crowded-tuna-558.mypinata.cloud/ipfs/QmVxrXmWCYhR18vVk8pYAfmKNnTXg99WAKNJDWamxwWtY7";

    bool public isPublicSaleActive = false;

    uint256 public MAX_TICKETS = 299;
    uint256 public MAX_PER_WALLET = 2;
    uint256 public PUBLIC_SALE_PRICE = 55 ether;
    uint256 public ROYALTY = 10;
    address public FWB_ADDRESS = 0x35bD01FC9d6D5D81CA9E055Db88Dc49aa2c699A8;

    address public FUNDS_RECIPIENT = 0x69602b7a324e927cfc47e6C5Ebfd9ED7754a964A;

    /*
     * ----------------------------------------------------------------------------
     * Modifiers
     * ----------------------------------------------------------------------------
     */

    /*
     * ----------------------------------------------------------------------------
     * totalSupply Function
     * ----------------------------------------------------------------------------
     * This function returns the total supply of tokens.
     * ----------------------------------------------------------------------------
     */
    function totalSupply() public view returns (uint256) {
        return tokenCounter.current();
    }

    /*
     * ----------------------------------------------------------------------------
     * publicSaleActive Modifier
     * ----------------------------------------------------------------------------
     * This modifier checks if the public sale is active.
     * ----------------------------------------------------------------------------
     */
    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    /*
     * ----------------------------------------------------------------------------
     * canMintTicket Modifier
     * ----------------------------------------------------------------------------
     * This modifier checks if the number of tickets to be minted does not exceed the maximum limit.
     * ----------------------------------------------------------------------------
     */
    modifier canMintTicket(uint256 numberOfTickets) {
        require(
            tokenCounter.current() + numberOfTickets <= MAX_TICKETS,
            "Not enough tickets remaining to mint"
        );
        _;
    }

    /*
     * ----------------------------------------------------------------------------
     * hasMinted Modifier
     * ----------------------------------------------------------------------------
     * This modifier checks if the address has already minted the maximum number of tickets.
     * ----------------------------------------------------------------------------
     */
    modifier hasMinted(uint256 numberOfTickets) {
        require(
            balanceOf(msg.sender) + numberOfTickets <= MAX_PER_WALLET,
            "This address has already minted the maximum number of tickets."
        );
        _;
    }

    constructor() ERC721("FWB Fest", "FWBFEST") {}

    /*
     * ----------------------------------------------------------------------------
     * mint Function
     * ----------------------------------------------------------------------------
     * This function mints the specified number of tickets and transfers the FWB from the sender to the recipient.
     * ----------------------------------------------------------------------------
     */
    function mint(
        uint256 numberOfTickets
    )
        external
        payable
        nonReentrant
        publicSaleActive
        canMintTicket(numberOfTickets)
        hasMinted(numberOfTickets)
    {
        require(
            IERC20(FWB_ADDRESS).transferFrom(
                msg.sender,
                FUNDS_RECIPIENT,
                PUBLIC_SALE_PRICE * numberOfTickets
            ),
            "Payment failed"
        );
        for (uint256 i = 0; i < numberOfTickets; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    /*
     * ----------------------------------------------------------------------------
     * mintOwner Function
     * ----------------------------------------------------------------------------
     * This function mints the specified number of tokens for the owner.
     * ----------------------------------------------------------------------------
     */
    function mintOwner(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    /*
     * ----------------------------------------------------------------------------
     * getBaseURI Function
     * ----------------------------------------------------------------------------
     * This function returns the base URI.
     * ----------------------------------------------------------------------------
     */
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    /*
     * ----------------------------------------------------------------------------
     * getLastTokenId Function
     * ----------------------------------------------------------------------------
     * This function returns the last token ID.
     * ----------------------------------------------------------------------------
     */
    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    /*
     * ----------------------------------------------------------------------------
     * Admin Functions
     * ----------------------------------------------------------------------------
     */

    /*
     * ----------------------------------------------------------------------------
     * setBaseURI Function
     * ----------------------------------------------------------------------------
     * This function sets the base URI.
     * ----------------------------------------------------------------------------
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /*
     * ----------------------------------------------------------------------------
     * setFWBAddress Function
     * ----------------------------------------------------------------------------
     * This function sets the FWB token address.
     * ----------------------------------------------------------------------------
     */
    function setFWBAddress(address _address) external onlyOwner {
        FWB_ADDRESS = _address;
    }

    /*
     * ----------------------------------------------------------------------------
     * setNumTickets Function
     * ----------------------------------------------------------------------------
     * This function sets the number of tickets.
     * ----------------------------------------------------------------------------
     */
    function setNumTickets(uint256 _num) external onlyOwner {
        MAX_TICKETS = _num;
    }

    /*
     * ----------------------------------------------------------------------------
     * setPrice Function
     * ----------------------------------------------------------------------------
     * This function sets the price of each ticket.
     * Formatted so that you can disregard the decimal point when inputting (ex. 100 = 100 FWB)
     * ----------------------------------------------------------------------------
     */
    function setPrice(uint256 _price) external onlyOwner {
        PUBLIC_SALE_PRICE = _price * 1 ether;
    }

    /*
     * ----------------------------------------------------------------------------
     * setMaxPerWallet Function
     * ----------------------------------------------------------------------------
     * This function sets the maximum number of tickets per wallet.
     * ----------------------------------------------------------------------------
     */
    function setMaxPerWallet(uint256 _max) external onlyOwner {
        MAX_PER_WALLET = _max;
    }

    /*
     * ----------------------------------------------------------------------------
     * setRoyalty Function
     * ----------------------------------------------------------------------------
     * This function sets the royalty percentage.
     * ----------------------------------------------------------------------------
     */
    function setRoyalty(uint256 _royalty) external onlyOwner {
        ROYALTY = _royalty;
    }

    /*
     * ----------------------------------------------------------------------------
     * setFundsRecipient Function
     * ----------------------------------------------------------------------------
     * This function sets the address to which the funds will be sent.
     * ----------------------------------------------------------------------------
     */
    function setFundsRecipient(address _address) external onlyOwner {
        FUNDS_RECIPIENT = _address;
    }

    /*
     * ----------------------------------------------------------------------------
     * setIsPublicSaleActive Function
     * ----------------------------------------------------------------------------
     * This function sets the status of the public sale.
     * ----------------------------------------------------------------------------
     */
    function setIsPublicSaleActive(
        bool _isPublicSaleActive
    ) external onlyOwner {
        isPublicSaleActive = _isPublicSaleActive;
    }

    /*
     * ----------------------------------------------------------------------------
     * nextTokenId Function
     * ----------------------------------------------------------------------------
     * This function increments the token counter and returns the current token ID.
     * ----------------------------------------------------------------------------
     */
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    /*
     * ----------------------------------------------------------------------------
     * supportsInterface Function
     * ----------------------------------------------------------------------------
     * This function checks if the contract supports the specified interface.
     * ----------------------------------------------------------------------------
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*
     * ----------------------------------------------------------------------------
     * withdrawFunds Function
     * ----------------------------------------------------------------------------
     * This function allows the owner to withdraw funds.
     * ----------------------------------------------------------------------------
     */
    function withdrawFunds() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /*
     * ----------------------------------------------------------------------------
     * tokenURI Function
     * ----------------------------------------------------------------------------
     * This function returns the URI of the specified token.
     * ----------------------------------------------------------------------------
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return baseURI;
    }

    /*
     * ----------------------------------------------------------------------------
     * royaltyInfo Function
     * ----------------------------------------------------------------------------
     * This function returns the receiver address and the royalty amount for the specified token and sale price.
     * ----------------------------------------------------------------------------
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Nonexistent token");

        return (
            address(this),
            SafeMath.div(SafeMath.mul(salePrice, ROYALTY), 100)
        );
    }
}
