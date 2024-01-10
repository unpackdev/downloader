// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*****************************************************************************************************
 ██████╗░███████╗░██████╗░███████╗███╗░░██╗  ██████╗░░██╗░░░░░░░██╗░█████╗░██████╗░███████╗░██████╗
 ██╔══██╗██╔════╝██╔════╝░██╔════╝████╗░██║  ██╔══██╗░██║░░██╗░░██║██╔══██╗██╔══██╗██╔════╝██╔════╝
 ██║░░██║█████╗░░██║░░██╗░█████╗░░██╔██╗██║  ██║░░██║░╚██╗████╗██╔╝███████║██████╔╝█████╗░░╚█████╗░
 ██║░░██║██╔══╝░░██║░░╚██╗██╔══╝░░██║╚████║  ██║░░██║░░████╔═████║░██╔══██║██╔══██╗██╔══╝░░░╚═══██╗
 ██████╔╝███████╗╚██████╔╝███████╗██║░╚███║  ██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║██║░░░░░██████╔╝
 ╚═════╝░╚══════╝░╚═════╝░╚══════╝╚═╝░░╚══╝  ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═════╝░
  Contract Developer: Stinky
  Description: Degen Dwarfs is an ERC-721 NFT series on Ethereum Mainnet.
******************************************************************************************************/

import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";

contract DegenDwarfs is ERC721, Ownable, Pausable, ERC721Enumerable, ReentrancyGuard, ERC721Burnable {
    using Counters for Counters.Counter;

    // @notice Counter for number of minted characters
    Counters.Counter public _tokenIds;    
    // Max Supply of DegenDwarfs
    uint256 public immutable maxSupply = 6969;
    // Store address and discount rate (10% off = 0.01 ether, convert to wei)
    mapping(address => uint256) public _discount;
    // If you are on the list, you can mint early
    mapping(address => uint256) public _whitelist; 
    // Contract managed whitelist mint start
    uint256 public whitelistStart = 1647718854; //Saturday, March 19, 2022 7:40:54 PM UTC
    // Contract managed public mint start and whitelist end
    uint256 public mintStart = 1647813600; // Sunday, March 20, 2022 10:00:00 PM UTC
    // Variable to change mint price if needed
    uint256 public mintPrice = 69000000000000000;
    // Base URI used for token metadata
    string private _baseTokenUri;     
    // DegenDwarf Beneficiary address
    address public beneficiary;

    constructor(
        address _beneficiary,
        string memory name,
        string memory symbol,
        string memory _tokenURI
    ) ERC721(name, symbol) {
        beneficiary = _beneficiary;
        _baseTokenUri = _tokenURI;
        _whitelist[_msgSender()] = 2;
    }

    // External function
    /*
     * @notice Claim mint discounts applied to your address
     */   
    function discount() external payable whenNotPaused nonReentrant {
        uint256 discounted = (mintPrice * (1e18 - _discount[_msgSender()])) / 1e18;
        require(msg.value == uint256(discounted), "ETH value incorrect");
        require(_tokenIds.current() <= maxSupply, "Mint is over");
        _tokenIds.increment();
        _safeMint(_msgSender(), _tokenIds.current());
        // delete discount
        delete _discount[_msgSender()];
    }

    /*
     * @notice Mint a Degen Dwarf NFT
     * @param _mintAmount How many NFTs would you like to batch mint?
     */    
    function claim(uint256 _mintAmount) external payable whenNotPaused nonReentrant {
        require((_tokenIds.current() + _mintAmount) <= maxSupply, "Mint is over");
        require(_mintAmount >= 1, "You must mint at least 1 NFT");    
        require(msg.value == mintPrice * _mintAmount, "ETH value incorrect");
        
        //Whitelist Phase
        if(whitelistStart < block.timestamp && mintStart > block.timestamp)
        {
            require(_whitelist[_msgSender()] >= _mintAmount, "You don't have enought whitelist credits.");
            require(_mintAmount <= 10, "Whitelist can mint up to 10 Dwarfs per transaction.");
            //Remove whitelist credits from Minter
            _whitelist[_msgSender()] -= _mintAmount;
        }
        //Public Phase
        else if(mintStart < block.timestamp)
            require(_mintAmount <= 15, "You can mint up to 15 Dwards per transaction");
        //No Mint Phase
        else
            revert("Whitelist minting has not started.");

        for(uint256 i = 0; i < _mintAmount; i++)
        {
            _tokenIds.increment();
            _safeMint(_msgSender(), _tokenIds.current());
        }
    }    

    /*
     * @notice Change mint price
     * @param newPrice (make sure value is in wei)
     */   
    function overrideMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    /*
     * @notice Add batch discounts
     * @param discountees an array of address 
     * @param discounted an array of the discount the addresses will receive
     */   
    function addDiscounts(address[] memory discountees, uint256[] memory discounted) external onlyOwner {
        for (uint i = 0; i < discountees.length; i++) {
            _discount[discountees[i]] = discounted[i];
          }
    }

    /*
     * @notice Add an multiple addresses to the whitelist
     * @param whitelist array of addresses
     */  
    function addWhitelist(address[] memory whitelist, uint256 credits) external onlyOwner {
        for (uint i = 0; i < whitelist.length; i++) {
            _whitelist[whitelist[i]] = credits;
          }
    }

    /*
     * @notice set the baseURI
     * @param baseURI
     */  
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenUri = baseURI;
    }  

    /* @notice Pause Degen Dwarf minting */  
    function pauseMinting() external onlyOwner {
        _pause();
    }

    /* @notice Resume Degen Dwarf minting*/  
    function unpauseMinting() external onlyOwner {
        _unpause();
    }   

    /* @notice Withdraw funds in Degen Dwarfs contract*/  
    function withdraw() external onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    function setBeneficiary(address newOwner) public onlyOwner {
        beneficiary = newOwner;
    }

    // Internal functions
    /* @notice Returns the baseURI */      
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    // Private functions
    /* @notice Returns the baseURI */         
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), toString(tokenId), ".json"));
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // do stuff before every transfer
        // e.g. check that vote (other than when minted) 
        // being transferred to registered candidate
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
