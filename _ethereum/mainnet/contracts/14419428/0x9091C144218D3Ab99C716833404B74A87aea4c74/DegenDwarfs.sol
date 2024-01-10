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

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";

contract DegenDwarfs is ERC721A, ERC721ABurnable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;      
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
    ) ERC721A(name, symbol) {
        beneficiary = _beneficiary;
        _baseTokenUri = _tokenURI;
        _whitelist[_msgSender()] = 1;
    }

    // External function
    /*
     * @notice Claim mint discounts applied to your address
     */   
    function discount() external payable whenNotPaused {
        uint256 discounted = (mintPrice * (1e18 - _discount[_msgSender()])) / 1e18;
        require(msg.value == uint256(discounted), "ETH value incorrect");
        require(totalSupply()  <= maxSupply, "Mint is over");
        _safeMint(_msgSender(), 1);
        // delete discount
        delete _discount[_msgSender()];
    }

    /*
     * @notice Mint a Degen Dwarf NFT
     * @param _mintAmount How many NFTs would you like to batch mint?
     */    
    function claim(uint256 _mintAmount) external payable whenNotPaused {
        require((totalSupply() + _mintAmount) <= maxSupply, "Mint is over");
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
        
        _safeMint(_msgSender(), _mintAmount);
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

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {
        // safeTransferFrom(from, to, tokenId, "");
        _addTokenToOwnerEnumeration(to, tokenId);        
        _removeTokenFromOwnerEnumeration(from, tokenId);            
        super.safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721A)  {
        _addTokenToOwnerEnumeration(to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);    
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A)  {
        // //solhint-disable-next-line max-line-length
        _addTokenToOwnerEnumeration(to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);            
        super.transferFrom(from, to, tokenId);
    }    

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721A.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        uint256 length = ERC721A.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }    

        /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721A.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}
