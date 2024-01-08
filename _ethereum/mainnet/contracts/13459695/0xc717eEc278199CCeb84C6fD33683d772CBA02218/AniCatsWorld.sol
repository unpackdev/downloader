// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

contract AniCatsWorld is ERC721, Ownable {
    uint constant public TICKET_ID = 0;

    uint constant public MAX_SUPPLY = 9000; // 9000 unique AniCats will be in total.
    uint constant public PRICE = 0.07 ether; // 0.07 ETH + gas per transaction
    uint constant public PRESALE_PRICE = 0.065 ether; // 0.07 ETH + gas per transaction
    uint constant public PRESALE_PER_TX_LIMIT = 10; // Up to 10 AniCats per transaction during the presale.
    uint constant public PRESALE_PER_WALLET_LIMIT = 10; // Up to 10 AniCats per unique wallet during the presale.
    uint constant public MINT_PER_TX_LIMIT = 20; // Up to 20 AniCats per transaction.
    
    string private _apiURI = "https://anicats.herokuapp.com/token/";
    uint public reservedTokensLimit = 200; // 200 AniCats will be reserved for marketing needs.

    uint public claimLimit = 874;
    uint public presaleTokensLimit = 3426;

    bool public isClaimingAvailable = false;
    bool public isMintingAvailable = false;
    bool public isPresaleAvailable = false;

    uint public tokensMinted = 0;
    uint public presaleTokensMinted = 0;

    mapping(address => bool) public presaleList;
    mapping(address => uint) public claimedWithMintpass;

    IERC1155 public mintPassContract = IERC1155(0x942c4199312902B45e8032051Ebad08be34a318c); // AniCats Mintpass https://anicats.world/
    IERC721 public friendContract = ERC721(0x1A92f7381B9F03921564a437210bB9396471050C); // Cool Cats https://www.coolcatsnft.com/

    constructor() ERC721("AniCatsWorld", "ACW") {
        mintNFTs(1);
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _apiURI = uri;
    }

    function startClaimAndPresale() external onlyOwner {
        isClaimingAvailable = true;
        isPresaleAvailable = true;
    }
    
    function setIsMintingAvailable(bool state) external onlyOwner {
        isMintingAvailable = state;
    }
    function setIsClaimingAvailable(bool state) external onlyOwner {
        isClaimingAvailable = state;
    }
    function setIsPresaleAvailable(bool state) external onlyOwner {
        isPresaleAvailable = state;
        if (state == false) {
            presaleTokensLimit = presaleTokensMinted;
        }
    }

    function giveAway(address to, uint256 amount) external onlyOwner {
        require(amount <= reservedTokensLimit, "Not enough reserve left for team");
        uint fromToken = tokensMinted + 1;
        tokensMinted += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(to, fromToken + i);
        }
        reservedTokensLimit -= amount;
    }

    // Giveaway from Claim bucket
    function claimGiveAway(address to, uint amount) external onlyOwner() {
        require(amount <= claimLimit, "All mintpasses were claimed");

        claimedWithMintpass[to] += amount;
        claimLimit -= amount;
        mintNFTs(amount);
    }

    function withdraw(address to) external onlyOwner {
        uint balance = address(this).balance;
        payable(to).transfer(balance);
    }
    // endregion

    // Presale helper methods region
    function addToPresale(address wallet) public onlyOwner() {
        presaleList[wallet] = true;
    }

    function removeFromPresale(address wallet) public onlyOwner() {
        presaleList[wallet] = false;
    }
    
    function addToPresaleMany(address[] memory wallets) public onlyOwner() {
        for(uint256 i = 0; i < wallets.length; i++) {
            addToPresale(wallets[i]);
        }
    }

    function removeFromPresaleMany(address[] memory wallets) public onlyOwner() {
        for(uint256 i = 0; i < wallets.length; i++) {
            removeFromPresale(wallets[i]);
        }
    }
    // endregion

    // Claim a token using Mintpass ticket
    function claim(uint amount) external {
        require(isClaimingAvailable, "Claiming is not available");
        require(amount <= claimLimit, "All mintpasses were claimed");

        uint tickets = mintPassContract.balanceOf(msg.sender, TICKET_ID);
        require(claimedWithMintpass[msg.sender] + amount <= tickets, "Insufficient Mintpasses balance");
        claimedWithMintpass[msg.sender] += amount;
        claimLimit -= amount;
        mintNFTs(amount);
    }

    function mintPrice(uint amount) public pure returns (uint) {
        return amount * PRICE;
    }
    function presaleMintPrice(uint amount) public pure returns (uint) {
        return amount * PRESALE_PRICE;
    }

    // Main sale mint
    function mint(uint amount) external payable {
        require(isMintingAvailable, "Minting is not available");
        require(tokensMinted + amount <= MAX_SUPPLY - reservedTokensLimit - claimLimit, "Tokens supply reached limit");
        require(amount > 0 && amount <= MINT_PER_TX_LIMIT, "Can only mint 20 tokens at a time");
        require(mintPrice(amount) == msg.value, "Wrong ethers value");

        mintNFTs(amount);
    }

    // Presale mint
    function presaleMint(uint amount) external payable {
        require(isPresaleAvailable, "Presale is not available");
        require(presaleTokensMinted + amount <= presaleTokensLimit, "Presale tokens supply reached limit"); // Only presale token validation
        require(tokensMinted + amount <= MAX_SUPPLY - reservedTokensLimit, "Tokens supply reached limit"); // Total tokens validation
        require(amount > 0 && amount <= PRESALE_PER_TX_LIMIT, "Can only mint 10 tokens at a time");
    
        require(presaleAllowedForWallet(msg.sender), "Sorry you are not on the presale list");
        require(presaleMintPrice(amount) == msg.value, "Wrong ethers value");
        require(balanceOf(msg.sender) + amount <= PRESALE_PER_WALLET_LIMIT + claimedWithMintpass[msg.sender], "Can only mint 10 tokens during the presale per wallet");
        
        presaleTokensMinted += amount;
        mintNFTs(amount);
    }

    // Validate if sender owns a mintpass or a friend collection token (Cool Cats) or in the presale list
    function presaleAllowedForWallet(address wallet) public view returns(bool) {
        return presaleList[wallet] ||
               friendContract.balanceOf(wallet) > 0 ||
               mintPassContract.balanceOf(wallet, TICKET_ID) > 0;
    }

    function mintNFTs(uint amount) internal {
        uint fromToken = tokensMinted + 1;
        tokensMinted += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, fromToken + i);
        }
    }
    
    function totalSupply() external view returns (uint) {
        return tokensMinted;
    }
}