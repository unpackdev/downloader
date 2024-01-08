// SPDX-License-Identifier: MIT

/*
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
*/

pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";

abstract contract ClonexCharacterInterface {
    function mintTransfer(address to) public virtual returns(uint256);
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract Mintvial is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;

    uint256 tokenId = 1;
    uint256 amountMinted = 0;
    uint256 limitAmount = 20000;
    uint256 private tokenPrice = 50000000000000000; // 0.05 ETH

    address clonexContractAddress;

    mapping (address => mapping (uint256 => bool)) usedToken;
    mapping (address => bool) authorizedContract;
    mapping (address => bool) isErc721;

    event priceChanged(uint256 newPrice);
                                
    bool publicSales = false;
    bool salesStarted = false;
    bool migrationStarted = false;
    
    constructor() ERC1155("ipfs://QmQqMF7izNAaU9CY3qV9ZGs4Aksv6ywjx8261khgzQbReW") {
        // ERC-721
        authorizedContract[0x20fd8d8076538B0b365f2ddd77C8F4339f22B970] = true; // Mintdisc 1 - 721
        authorizedContract[0x25708f5621Ac41171F3AD6D269e422c634b1E96A] = true; // Mintdisc 3 - 721
        authorizedContract[0x50B8740D6a5CD985e2B8119Ca28B481AFa8351d9] = true; // RTFKT Easter Eggs - 721
        authorizedContract[0xc541fC1Aa62384AB7994268883f80Ef92AAc6399] = true; // Space Drip 1.2 - 721
        authorizedContract[0xd3f69F10532457D35188895fEaA4C20B730EDe88] = true; // Space Drip 1 - 721
        authorizedContract[0x2250D7c238392f4B575Bb26c672aFe45F0ADcb75] = true; // FewoShoes - 721
        authorizedContract[0xAE3d8D68B4F6c3Ee784b2b0669885a315BA77C08] = true; // Punk sneakers - 721
        authorizedContract[0xDE8350B34b2e6FC79aABCc7030fD9a862562E821] = true; // Metagrails -> 721

        // ERC-1155
        authorizedContract[0xCD1DBc840E1222A445be7C1D8ecB900F9D930695] = true; // Jeff Staples - 1155
        
        // ERC-721 flagging
        isErc721[0x20fd8d8076538B0b365f2ddd77C8F4339f22B970] = true; // Mintdisc 1 - 721
        isErc721[0x25708f5621Ac41171F3AD6D269e422c634b1E96A] = true; // Mintdisc 3 - 721
        isErc721[0x50B8740D6a5CD985e2B8119Ca28B481AFa8351d9] = true; // RTFKT Easter Eggs - 721
        isErc721[0xc541fC1Aa62384AB7994268883f80Ef92AAc6399] = true; // Space Drip 1.2 - 721
        isErc721[0xd3f69F10532457D35188895fEaA4C20B730EDe88] = true; // Space Drip 1 - 721
        isErc721[0x2250D7c238392f4B575Bb26c672aFe45F0ADcb75] = true; // FewoShoes - 721
        isErc721[0xAE3d8D68B4F6c3Ee784b2b0669885a315BA77C08] = true; // Punk sneakers - 721
        isErc721[0xDE8350B34b2e6FC79aABCc7030fD9a862562E821] = true; // Metagrails -> 721
    }
    
    // Set authorized contract address for minting the ERC-721 token
    function setClonexContract(address contractAddress) public onlyOwner {
        clonexContractAddress = contractAddress;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleSales() public onlyOwner {
        salesStarted = !salesStarted;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleMigration() public onlyOwner {
        migrationStarted = !migrationStarted;
    }
    
    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleContractAuthorization(address contractAddress) public onlyOwner {
        authorizedContract[contractAddress] = !authorizedContract[contractAddress];
    }

    // Toggle the type of contract
    function toggleContractType(address contractAddress) public onlyOwner {
        isErc721[contractAddress] = !isErc721[contractAddress];
    }
    
    // Check if a specific address is an authorized mintpass
    function isContractAuthorized(address contractAddress) view public returns(bool) {
        return authorizedContract[contractAddress];
    }

    // Check if contract is internally seen as Erc721
    function isContractErc721(address contractAddress) view public returns(bool) {
        return isErc721[contractAddress];
    }

    // Mint function
    function mint(address[] memory contractIds, uint256[] memory tokenIds, uint256 amountToMint) public payable returns(uint256) {
        // By calling this function, you agreed that you have read and accepted the terms & conditions available at this link: https://rtfkt.com/legaloverview
        require(salesStarted == true, "Sales have not started");
        uint256 amount = amountToMint;
        
        // Check if public sales is active or not
        if(!publicSales) {
            amount = 0;
            for(uint256 i = 0; i < contractIds.length; i++) {
                // Check if contract is authorized
                require(isContractAuthorized(contractIds[i]) == true, "Contract is not authorized");

                // Verify token ownership and if already redeemed
                if(isErc721[contractIds[i]]) {
                    // If token is ERC-721
                    ERC721 contractAddress = ERC721(contractIds[i]);
                    require(contractAddress.ownerOf(tokenIds[i]) == msg.sender, "Doesn't own the token");
                } else {
                    // If token is ERC-1155
                    ERC1155 contractAddress = ERC1155(contractIds[i]);
                    require(contractAddress.balanceOf(msg.sender, tokenIds[i]) > 0, "Doesn't own the token");
                }
                
                require(checkIfRedeemed(contractIds[i], tokenIds[i]) == false, "Token already redeemed");
                
                // Verify if token is mintpass or not (influence the amount to mint)
                if(contractIds[i] == 0x20fd8d8076538B0b365f2ddd77C8F4339f22B970) amount += 1; 
                else amount += 3;
            }
        }
        
        // Add verification on ether required to pay
        require(msg.value == tokenPrice.mul(amount), "Not enough money");
        require(amount + amountMinted <= limitAmount, "Limit reached");

        for(uint256 i = 0; i < contractIds.length; i++) {
            usedToken[contractIds[i]][tokenIds[i]] = true;
        }
        
        _mint(msg.sender, tokenId, amount, "");
        
        uint256 prevTokenId = tokenId;
        tokenId++;
        amountMinted = amountMinted + amount;
        return prevTokenId;
    }
    
    // Allowing direct drop for gievaway
    function airdropGiveaway(address[] memory to, uint256[] memory amountToMint) public onlyOwner {
        for(uint256 i = 0; i < to.length; i++) {
            require(amountToMint[i] + amountMinted <= limitAmount, "Limit reached");
            _mint(msg.sender, tokenId, amountToMint[i], "");
            tokenId++;
            amountMinted = amountMinted + amountToMint[i];
        }
    }
    
    // Allow to use the ERC-1155 to get the CLoneX ERC-721 final token
    function migrateToken(uint256 id) public returns(uint256) {
        require(migrationStarted == true, "Migration has not started");
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        ClonexCharacterInterface clonexContract = ClonexCharacterInterface(clonexContractAddress);
        uint256 mintedId = clonexContract.mintTransfer(msg.sender); // Mint the ERC-721 token
        return mintedId; // Return the minted ID
    }

    // Allow to use the ERC-1155 to get the CLoneX ERC-721 final token (Forced)
    function forceMigrateToken(uint256 id) public onlyOwner {
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token"); // Kept so no one can't force someone else to open a CloneX
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        ClonexCharacterInterface clonexContract = ClonexCharacterInterface(clonexContractAddress);
        uint256 mintedId = clonexContract.mintTransfer(msg.sender); // Mint the ERC-721 token
    }
    
    // Check if the mintpass has been used to mint an ERC-1155
    function checkIfRedeemed(address _contractAddress, uint256 _tokenId) view public returns(bool) {
        return usedToken[_contractAddress][_tokenId];
    }
    
    // Allow toggling of public sales
    function togglePublicSales() public onlyOwner {
        publicSales = !publicSales;
    }
    
    // Get the price of the token (as changing during presale and public sale)
    function getPrice() view public returns(uint256) { 
        return tokenPrice;
    }
    
    // Get amount of 1155 minted
    function getAmountMinted() view public returns(uint256) {
        return amountMinted;
    }
    
    // Used for manual activation on dutch auction
    function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
        emit priceChanged(tokenPrice);
    }
    
    // Basic withdrawal of funds function in order to transfert ETH out of the smart contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}
