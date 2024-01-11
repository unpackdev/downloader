/*                                                                                                                                
                                                                                                                                   
  1111111        000000000          000000000     kkkkkkkk           PPPPPPPPPPPPPPPPP   FFFFFFFFFFFFFFFFFFFFFFPPPPPPPPPPPPPPPPP   
 1::::::1      00:::::::::00      00:::::::::00   k::::::k           P::::::::::::::::P  F::::::::::::::::::::FP::::::::::::::::P  
1:::::::1    00:::::::::::::00  00:::::::::::::00 k::::::k           P::::::PPPPPP:::::P F::::::::::::::::::::FP::::::PPPPPP:::::P 
111:::::1   0:::::::000:::::::00:::::::000:::::::0k::::::k           PP:::::P     P:::::PFF::::::FFFFFFFFF::::FPP:::::P     P:::::P
   1::::1   0::::::0   0::::::00::::::0   0::::::0 k:::::k    kkkkkkk  P::::P     P:::::P  F:::::F       FFFFFF  P::::P     P:::::P
   1::::1   0:::::0     0:::::00:::::0     0:::::0 k:::::k   k:::::k   P::::P     P:::::P  F:::::F               P::::P     P:::::P
   1::::1   0:::::0     0:::::00:::::0     0:::::0 k:::::k  k:::::k    P::::PPPPPP:::::P   F::::::FFFFFFFFFF     P::::PPPPPP:::::P 
   1::::l   0:::::0 000 0:::::00:::::0 000 0:::::0 k:::::k k:::::k     P:::::::::::::PP    F:::::::::::::::F     P:::::::::::::PP  
   1::::l   0:::::0 000 0:::::00:::::0 000 0:::::0 k::::::k:::::k      P::::PPPPPPPPP      F:::::::::::::::F     P::::PPPPPPPPP    
   1::::l   0:::::0     0:::::00:::::0     0:::::0 k:::::::::::k       P::::P              F::::::FFFFFFFFFF     P::::P            
   1::::l   0:::::0     0:::::00:::::0     0:::::0 k:::::::::::k       P::::P              F:::::F               P::::P            
   1::::l   0::::::0   0::::::00::::::0   0::::::0 k::::::k:::::k      P::::P              F:::::F               P::::P            
111::::::1110:::::::000:::::::00:::::::000:::::::0k::::::k k:::::k   PP::::::PP          FF:::::::FF           PP::::::PP          
1::::::::::1 00:::::::::::::00  00:::::::::::::00 k::::::k  k:::::k  P::::::::P          F::::::::FF           P::::::::P          
1::::::::::1   00:::::::::00      00:::::::::00   k::::::k   k:::::k P::::::::P          F::::::::FF           P::::::::P          
111111111111     000000000          000000000     kkkkkkkk    kkkkkkkPPPPPPPPPP          FFFFFFFFFFF           PPPPPPPPPP          
                                                                                                                                   
*/

/**
 * @title  Smart Contract for the $100kPFP Club Project
 * @notice NFT Minting
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

error InsufficientPayment();

contract my100kPFP is ERC721A, Ownable, PaymentSplitter {

    // Variables
    string public baseTokenURI;
    uint256 public maxTokens = 5000;
    uint256 public tokenReserve = 100;

    bool public publicMintActive = false;
    uint256 public publicMintPrice = 0.05 ether;
    uint256 public maxTokenPurchase = 10;
    
    // Team Wallets & Shares
    address[] private teamWallets = [
        0x75710cf256C0C5d157a792CB9D7A9cCc2D7E13a7,
        0x78F0a6352E66D5ee3a9dC00376066925Cf2Fc405, 
        0xCECD66ff3D2f87d0Af011b509b832748Dc2CD8E2, 
        0x7608E1d480B2a254A0F0814DADc00169745CF55B  
    ];
    uint256[] private teamShares = [500, 1000, 2500, 6000];

    constructor()
        PaymentSplitter(teamWallets, teamShares)
        ERC721A("$100k PFP Club", "100kPFP")
    {}

    modifier onlyOwnerOrTeam() {
        require(
            teamWallets[0] == msg.sender || teamWallets[1] == msg.sender || teamWallets[2] == msg.sender || teamWallets[3] == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    // Mint from reserve allocation for team, promotions and giveaways
    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {        
        require(_reserveAmount <= tokenReserve, "Not enough reserve left to mint that quantity");
        require(totalSupply() + _reserveAmount <= maxTokens, "Exceeds max supply");

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
        require(totalSupply() + _numberOfTokens <= maxTokens, "MAX_SUPPLY_EXCEEDED");

        uint256 cost = _numberOfTokens * publicMintPrice;
        if (msg.value < cost) revert InsufficientPayment();
        //require(msg.value >= publicMintPrice * _numberOfTokens, "NOT_ENOUGH_ETHER");

        _safeMint(msg.sender, _numberOfTokens);
    }

    // Return baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Set baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // Toggle sale active
    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    // In case we need to update the max token purchase value
    function setMaxTokenPurchase(uint256 _newMaxTokenPurchase) external onlyOwner {
        maxTokenPurchase = _newMaxTokenPurchase;
    }

    // In case we need to update the reserved token value
    function setTokenReserve(uint256 _newTokenReserve) external onlyOwner {
        tokenReserve = _newTokenReserve;
    }

    // How many tokens are left?
    function remainingSupply() external view returns (uint256) {
        return maxTokens - totalSupply();
    }

    // In case we want to lower the supply
    function lowerMaxSupply(uint256 _newMax) external onlyOwner {
        require(_newMax < maxTokens, "Can only lower supply");
        require(maxTokens > totalSupply(), "Can't set below current");
        maxTokens = _newMax;
    }

    // Just in case ETH does something silly
    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    // Withdraw balance to wallets per share allocation
    function withdrawShares() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);
        for (uint256 i = 0; i < teamWallets.length; i++) {
            address payable wallet = payable(teamWallets[i]);
            release(wallet);
        }
    }

    // Backup withdrawal function?
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

}