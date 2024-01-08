// SPDX-License-Identifier: MIT

//              .--.
//              /} p \             /}
//             `~)-) /           /` }
//              ( / /          /`}.' }
//               / / .-'""-.  / ' }-'}
//              / (.'       \/ '.'}_.}
//             |            `}   .}._}
//             |     .-=-';   } ' }_.}
//             \    `.-=-;'  } '.}.-}
//              '.   -=-'    ;,}._.}
//                `-,_  __.'` '-._}
//                    `|||
//                   .=='=,
//
//@author: Gobble Gang
//@website: gobblegang.io

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract GobbleGang is ERC721Enumerable, Ownable {  
    
    // Sale and Presale status
    bool public saleActive = false;
    bool public presaleActive = false;

    // Initial price
    uint256 public price = 0.04 ether;

    // Total Goblers in the gang
    uint256 constant MAX_GOBBLERS = 8888;
    uint256 constant MAX_PER_MINT = 20;
    uint256 constant MAX_FOR_PRESALE = 10;
    
    // Reserved for giveaways, collabs, and more
    uint256 public reserved = 40;

    // The base link that leads to the image / video of the token
    string public baseTokenURI = "https://gobblegang.io/api/nft/";

    // Team addresses for withdrawals & signer address
    address private teamAddress = 0x466F994cdF3869E26949Ad6E42700032cE5E1a61;

    // Addresses that have a whitelist spot on presale
    mapping (address => bool) public presaleReserved;
    mapping(address => uint256) public presalePurchasesList;
    mapping (address => bool) public freeMintsReserved;
    
    // Constructor
    constructor () ERC721 ("Gobble Gang", "GG") {}

    // Override so the openzeppelin tokenURI() will call this method to get the base token uri from our contract
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Edit reserved presale spots
    function addToPresaleList(address[] memory _addresses) public onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
            presaleReserved[_addresses[i]] = true;
        }
    }

    // Edit free presale spots
    function addToFreeList(address[] memory _addresses) public onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
            freeMintsReserved[_addresses[i]] = true;
        }
    }
    
    // Presale mint
    function mintPresale(uint256 gobblersAmount) public payable {
        require(!saleActive && presaleActive, "presale_is_closed");
        require(presaleReserved[msg.sender], "not_on_presale_whitelist");
        require(totalSupply() + gobblersAmount <= MAX_GOBBLERS, "out_of_stock");
        require(presalePurchasesList[msg.sender] + gobblersAmount <= MAX_FOR_PRESALE, "exceeded_presale_allocation");
        require(price * gobblersAmount <= msg.value, "insufficient_eth");

        for (uint256 i = 0; i < gobblersAmount; i++) {
            presalePurchasesList[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

   // Free mint
    function mintFree() public payable {
        require(saleActive, "sale_is_closed");
        require(freeMintsReserved[msg.sender], "no_free_allocated");
        require(totalSupply() + 1 <= MAX_GOBBLERS, "out_of_stock");

        freeMintsReserved[msg.sender] = false;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    // Reserved mint for giveaways and collabs
    function mintReserved(uint256 amount) public onlyOwner {
        require(amount <= reserved, "Can't reserve more than set amount" );
        require(totalSupply() + amount <= MAX_GOBBLERS, "out_of_stock");
        reserved -= amount;

        for(uint256 i; i < amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // Public minitng, only signed hashs allowed to mint
    function mintGobble(uint256 amount) external payable {
        require(saleActive, "sale_closed");
        require(totalSupply() + amount <= MAX_GOBBLERS, "out_of_stock");
        require(amount <= MAX_PER_MINT, "exceeded_max_amount_per_mint");
        require(price * amount <= msg.value, "insufficient_eth");
        
        for(uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    //////////////////////
    // State Management //
    //////////////////////

    // Start and stop presale
    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
    }

    // Start and stop sale
    function toggleSaleStatus() external onlyOwner {
        saleActive = !saleActive;
    }

    // Set new baseURI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set a different price
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    // Set team addresses
    function setAddress(address newTeamAddress) external onlyOwner {
        teamAddress = newTeamAddress;
    }

    // Withdraw funds from contract for the team
    function withdrawTeam() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
} 