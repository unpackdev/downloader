/**
 * @title       Rebel Tiger Club Official NFT Minting Smart Contract - twitter.com/RebelTigerClub
 * @author      OPCODER - twitter.com/opcodereth
 * @notice      An ERC721A extension with added functionality for the desired minting scenarios.      
 *  
 *               .==###.
 *             .--==*=+=-:.... 
 *            :=+++=++==+*+==++==-.             ..:.::-::::.
 *            =+**++=:=:-+**+*+*=#+==+---+=--+=---+===+*==++-==:.  
 *          .=====-:--:=.+*#+*+==**++*==-+=--+=-===**++#%++**+=+=-: 
 *          :=::::-=--=+.=**+*===+*++*+=-+=+==--**++@#**%#++=+*++++- 
 *            =+**+==++++*++++===*=+**+*=*=*+===%%++#@***#=+===#*##+  
 *             ..      =**+*+===+==***+#+*+*#+++#@*+#%****=+==++##*=.  
 *                     .**#++==*+=+#+*#*#+++#**%*#*#+****++*=+#++*%*. 
 *                      :***+=+#=+%#+*#***+=++-**++*+++#*+**==##+-++.
 *                       *#**+%+=#@*+====*=*===++==+#%#@***+++*#*-#*. 
 *                       =#%#*%++*%++++++++*=-:.  :#%@@@#%#++====:+- 
 *                      -=+####*++++-:...         .+*###*******++.**:  :*+.
 *                    .--*##*-=*++++               -*###+ -#%*+===:--- .==.
 *                   .-=+*+:  :*++*=                +***=. .=##*++::**:+#-
 *                  =**#=      +++*=                -+*+-    :*#*+-   ..
 *                 =###*.      +***:               .+*+:      -#**= 
 *                 :==-     ..-+**=             .--+*+.     ::=***: 
 *                         -+++++=              :---:      :===+=.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract RebelTiger is ERC721A, Ownable {

    uint256 constant MAX_SUPPLY_SHIFTED = 7778;
    uint256 constant WL_PRICE = 0.066 ether;
    uint256 constant PRICE = 0.077 ether;
    uint256 constant WL_CAP_SHIFTED = 6; 
    uint256 constant MINT_CAP_SHIFTED = 21; 

    constructor() ERC721A("RebelTiger", "RTC") {}

    // SALE STATE MECHANISM

    uint256 public saleState = 0; // { 0: INACTIVE, 1: PRE_SALE, 2: PUBLIC_SALE }

    function setSaleState(uint256 _saleState) external onlyOwner {
        require(_saleState >= 0 && _saleState < 3, "RTC: Invalid new sale state.");
        saleState = _saleState;
    }

    // PRE-SALE MINTING

    mapping (address => uint256) whitelistMints;  // Mapping from whitelist addresses to their mint counts

    bytes32 public merkleRoot; // Merkle root for off-chain whitelist verification

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function mintPreSale(uint256 amount, bytes32[] calldata merkleProof) external payable {
        require(saleState == 1, "RTC: Pre-sale has not started yet.");
        require(totalSupply() + amount < MAX_SUPPLY_SHIFTED, "RTC: Transaction exceeds maximum supply.");
        require(msg.value >= amount * WL_PRICE, "RTC: Insufficient funds for Pre-sale.");
        require(whitelistMints[msg.sender] + amount <  WL_CAP_SHIFTED, "RTC: Amount exceeds Pre-sale wallet mint cap.");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "RTC: Merkle verification has failed, address is not in the whitelist.");

        _safeMint(msg.sender, amount);
        whitelistMints[msg.sender] += amount;
    }

    // PUBLIC SALE MINTING

    function mintPublicSale(uint256 amount) external payable {
        require(saleState == 2, "RTC: Public sale has not started yet.");
        require(totalSupply() + amount < MAX_SUPPLY_SHIFTED, "RTC: Transaction exceeds maximum supply.");
        require(msg.value >= amount * PRICE, "RTC: Insufficient funds for Public Sale.");
        require(amount < MINT_CAP_SHIFTED, "RTC: Amount exceeds Public Sale transaction mint cap.");

        _safeMint(msg.sender, amount);
    }

    // GIFT MINTING

    function mintGifts(address recipient, uint256 amount) external onlyOwner {
        require(totalSupply() + amount < MAX_SUPPLY_SHIFTED, "RTC: Transaction exceeds maximum supply.");
        
        _safeMint(recipient, amount);
    }

    // TOKEN URI LOGIC

    string public baseURI = "ipfs://QmRL9Zzu3zXWdWnuz3vqcNhSr6ZQGcZyL29XfoaLoPS8jQ/"; // Unrevealed metadata

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    // WITHDRAWAL

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "RTC: No balance to withdraw.");

        _withdraw(payable(0x27131e0D27150655A0E9B467a55bA6a9843775A2), (balance * 430) / 1000); // CEO
        _withdraw(payable(0x7EB5bbE90D399bD78819b7A377337625b4Ced4Dd), (balance * 430) / 1000); // CTO
        _withdraw(payable(0x1bd620d1E234E65F3C7D0dC3C3004d7d1e43e64f), (balance * 100) / 1000); // CVO
        _withdraw(payable(0x4047e17f6066E577D4DacA6AF312f402Ac266E14), (balance * 40) / 1000);  // COO
        
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "RTC: Transfer failed.");
    }
}