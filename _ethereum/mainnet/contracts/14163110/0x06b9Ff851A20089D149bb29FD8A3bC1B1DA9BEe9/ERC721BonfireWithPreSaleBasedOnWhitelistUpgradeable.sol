// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  ________________ _____ ___ __
   ___            ____        
  / _ )___  ___  / _(_)______ 
 / _  / _ \/ _ \/ _/ / __/ -_)
/____/\___/_//_/_//_/_/  \__/ 

     bonfire@livetoken.co
________________ _____ ___ __
*/

import "./ERC721BonfireBaseUpgradeable.sol";

// Inherit from this instead of just ERC721BonfireBaseUpgradeable if you want to have your drop support a pre-sale in which
//  the pre-sale is gated by an on-chain whitelist (vs just a password-protected website and unverified contract).
contract ERC721BonfireWithPreSaleBasedOnWhitelistUpgradeable is ERC721BonfireBaseUpgradeable {

    // constructor params
    uint256 public MAX_PRE_SALE;

    // drop status
    bool public preSaleOngoing;

    // mappings
    mapping(address => bool) public preSaleWhitelist;
    mapping(address => uint256) public preSaleMintedAmounts;

    // make transparent how many token were minted during the pre-sale.
    uint256 public numMintedInPreSale;

    function init(string memory name, string memory symbol, string memory bURI, uint256 maxTotalSupply, uint256 maxPerTx, uint256 maxPerWallet, uint256 mintPrice, uint256 maxPreSaleSupply ) initializer public {
        ERC721BonfireBaseUpgradeable.init(name, symbol, bURI, maxTotalSupply, maxPerTx, maxPerWallet, mintPrice);
        preSaleOngoing = false;
        numMintedInPreSale = 0;
        MAX_PRE_SALE = maxPreSaleSupply;
        contractType = 'WithPreSaleBasedOnWhitelist';
    }
    
    /** MODIFIERS */

    modifier whenPreSaleOngoing() {
        require(preSaleOngoing, "Pre-sale is not active");
        _;
    }

    /** PUBLIC */

    function mintPreSale(uint256 numberOfTokens) public payable whenPreSaleOngoing {
        require(preSaleWhitelist[msg.sender], "Address isn't whitelisted");

        require(MAX_PER_TX == 0 || (numberOfTokens > 0 && numberOfTokens < (MAX_PER_TX + 1)), "Cannot mint that many at once");
        require(MAX_TOTAL_SUPPLY == 0 || totalSupply() + numberOfTokens < (MAX_TOTAL_SUPPLY + 1), "Purchase would exceed max supply");
        require(MAX_PRE_SALE == 0 || (numMintedInPreSale + numberOfTokens) < (MAX_PRE_SALE + 1), "Purchase would exceed max pre-sale supply");
        require(MAX_TOTAL_PER_WALLET == 0 || preSaleMintedAmounts[msg.sender] + numberOfTokens < (MAX_TOTAL_PER_WALLET + 1), "Exceeds pre-sale max per wallet");
        require(MINT_PRICE * numberOfTokens <= msg.value, "Insufficient ether sent");
        require(tx.origin == msg.sender, "You cannot mint from another contract.");

        // do the mint
        _mint(msg.sender, numberOfTokens, msg.value);

        // increment preSaleMintedAmounts for this user
        preSaleMintedAmounts[msg.sender] = preSaleMintedAmounts[msg.sender] + numberOfTokens;

        // increment total that have been minted during the pre-sale
        numMintedInPreSale = numMintedInPreSale + numberOfTokens;
    }

    /** ADMIN **/

    function flipPreSaleState() external onlyOwner {
        preSaleOngoing = !preSaleOngoing;
    }

    function addAddressesToWhitelist(address[] memory whitelisted) external onlyOwner {
        for (uint256 i = 0; i < whitelisted.length; i++) {
            preSaleWhitelist[whitelisted[i]] = true;
        }
    }
    function removeAddressesFromWhitelist(address[] memory whitelisted) external onlyOwner {
        for (uint256 i = 0; i < whitelisted.length; i++) {
            preSaleWhitelist[whitelisted[i]] = false;
        }
    }

    function setMaxPreSaleSupply(uint256 _supply) external onlyOwner {
        MAX_PRE_SALE = _supply;
    }

}