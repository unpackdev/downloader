/*

 _____       _                  _____                             _____                   
/  __ \     | |         ___    /  __ \                           |  __ \                  
| /  \/_   _| |_ ___   ( _ )   | /  \/_ __ ___  ___ _ __  _   _  | |  \/ __ _ _ __   __ _ 
| |   | | | | __/ _ \  / _ \/\ | |   | '__/ _ \/ _ \ '_ \| | | | | | __ / _` | '_ \ / _` |
| \__/\ |_| | ||  __/ | (_>  < | \__/\ | |  __/  __/ |_) | |_| | | |_\ \ (_| | | | | (_| |
 \____/\__,_|\__\___|  \___/\/  \____/_|  \___|\___| .__/ \__, |  \____/\__,_|_| |_|\__, |
                                                   | |     __/ |                     __/ |
                                                   |_|    |___/                     |___/ 
 _____                                  _____                     _                       
/  ___|                                /  __ \                   (_)                      
\ `--.  ___  __ _ ___  ___  _ __  ___  | /  \/_ __ ___  ___ _ __  _ _ __   __ _ ___       
 `--. \/ _ \/ _` / __|/ _ \| '_ \/ __| | |   | '__/ _ \/ _ \ '_ \| | '_ \ / _` / __|      
/\__/ /  __/ (_| \__ \ (_) | | | \__ \ | \__/\ | |  __/  __/ |_) | | | | | (_| \__ \      
\____/ \___|\__,_|___/\___/|_| |_|___/  \____/_|  \___|\___| .__/|_|_| |_|\__, |___/      
                                                           | |             __/ |          
                                                           |_|            |___/           

*/

/**
 * @title  Smart Contract 
 * @author SteelBalls
 * @notice NFT Minting
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";

error InsufficientPayment();

contract SeasonsCreepings is ERC721A, DefaultOperatorFilterer, Ownable, PaymentSplitter {

    string public baseTokenURI;
    uint256 public maxTokens = 6666;
    uint256 public tokenReserve = 100;

    bool public publicMintActive = false;
    uint256 public publicMintPrice = 0.005 ether;
    uint256 public maxTokenPurchase = 8; 
    
    // Team Wallets & Shares
    address[] private teamWallets = [
        0x7608E1d480B2a254A0F0814DADc00169745CF55B, 
        0xCECD66ff3D2f87d0Af011b509b832748Dc2CD8E2, 
        0xd38eF170FcB60EE0FE7478DE0C9f2b2cCF3Ab574,
        0x75710cf256C0C5d157a792CB9D7A9cCc2D7E13a7
    ];
    uint256[] private teamShares = [4000, 4000, 1500, 500];

    // Constructor
    constructor()
        PaymentSplitter(teamWallets, teamShares)
        ERC721A("Cute & Creepy Gang: Seasons Creepings", "CREEPINGS")
    {}

    modifier onlyOwnerOrTeam() {
        require(
            teamWallets[0] == msg.sender ||
            teamWallets[1] == msg.sender || 
            teamWallets[2] == msg.sender || 
            teamWallets[3] == msg.sender || 
            owner() == msg.sender,
            "caller is not the Owner or a Team Member"
        );
        _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
        payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Mint from reserve allocation for team, promotions and giveaways
    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {        
        require(_reserveAmount <= tokenReserve, "RESERVE_EXCEEDED");
        require(totalSupply() + _reserveAmount <= maxTokens, "MAX_SUPPLY_EXCEEDED");

        _safeMint(_to, _reserveAmount);
        tokenReserve -= _reserveAmount;
    }

    /*
       @dev   Public mint
       @param _numberOfTokens Quantity to mint
    */
    function publicMint(uint _numberOfTokens) external payable {
        require(publicMintActive, "SALE_NOT_ACTIVE");
        require(msg.sender == tx.origin, "CALLER_CANNOT_BE_CONTRACT");
        require(_numberOfTokens <= maxTokenPurchase, "MAX_TOKENS_EXCEEDED");
        require(totalSupply() + _numberOfTokens <= maxTokens - tokenReserve, "MAX_SUPPLY_EXCEEDED");

        uint256 cost = _numberOfTokens * publicMintPrice;
        if (msg.value < cost) revert InsufficientPayment();
        
        _safeMint(msg.sender, _numberOfTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function setPublicMintPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    function setMaxTokenPurchase(uint256 _newMaxTokenPurchase) external onlyOwner {
        maxTokenPurchase = _newMaxTokenPurchase;
    }

    function setTokenReserve(uint256 _newTokenReserve) external onlyOwner {
        tokenReserve = _newTokenReserve;
    }

    function remainingSupply() external view returns (uint256) {
        return maxTokens - totalSupply();
    }

    function setMaxSupply(uint256 _newMax) external onlyOwner {
        require(_newMax >= totalSupply(), "Can't set below current supply");
        maxTokens = _newMax;
    }

    function withdrawShares() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);
        for (uint256 i = 0; i < teamWallets.length; i++) {
            address payable wallet = payable(teamWallets[i]);
            release(wallet);
        }
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

}