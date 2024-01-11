// SPDX-License-Identifier: MIT

/**
 *
 * 01001001 00100000 01101000 01100001 01110110 01100101 00100000 01101110 01101111 00100000 
 * 01110011 01110000 01100101 01100011 01101001 01100001 01101100 00100000 01110100 01100001 
 * 01101100 01100101 01101110 01110100 00101110 00100000 01001001 00100000 01100001 01101101 
 *
 *      >=>                      >==>    >=>               >=>   >=>           >=>           
 *      >=>                      >> >=>  >=>             >>      >=>    >>   >>              
 *      >=>      >=>   >=>       >=> >=> >=>   >==>    >=>> >> >=>>==>     >=>> >> >=>   >=> 
 *      >=>>==>   >=> >=>        >=>  >=>>=> >>   >=>    >=>     >=>   >=>   >=>    >=> >=>  
 *      >=>  >=>    >==>         >=>   > >=> >>===>>=>   >=>     >=>   >=>   >=>      >==>   
 *      >=>  >=>     >=>         >=>    >>=> >>          >=>     >=>   >=>   >=>       >=>   
 *      >=>>==>     >=>          >=>     >=>  >====>     >=>      >=>  >=>   >=>      >=>    
 *                 >=>                                                               >=>   
 *
 * 00100000 01101111 01101110 01101100 01111001 00100000 01110000 01100001 01110011 01110011 
 * 01101001 01101111 01101110 01100001 01110100 01100101 01101100 01111001 00100000 01100011 
 * 01110101 01110010 01101001 01101111 01110101 01110011 00100000 00111010 00101101 00101001
 *
 */
 
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";

contract HypeBuddies is ERC721, ERC721Enumerable, ERC721Royalty, Ownable {

    /**
     * Token
     */
    uint256 public constant MAX_SUPPLY = 1111;

    constructor() ERC721("HypeBuddies", "HB") {
    }

    /**
     * Whitelist
     */
    bool public isAllowListActive = false;
    mapping(address => uint8) private _allowList;

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    /**
     * Mint
     */
    bool public saleIsActive = false;

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    /**
     * Utils
     */
    uint256 public MAX_PUBLIC_MINT;
    uint256 public PRICE_PER_TOKEN;

    string public PROVENANCE;
    string private _baseURIextended;

    address public royaltyAddress;
    uint96 public royaltyBps;
    
    function reserve(uint numberOfTokens) public onlyOwner {
      uint256 ts = totalSupply();
      uint i;

      require(ts + numberOfTokens <= MAX_SUPPLY, "Reserve amount would exceed max tokens");
      for (i = 0; i < numberOfTokens; i++) {
          _safeMint(msg.sender, ts + i);
      }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMaxPublicMint(uint256 maxPublicMint) public onlyOwner {
        MAX_PUBLIC_MINT = maxPublicMint;
    }

    function setPricePerToken(uint256 pricePerToken) public onlyOwner {
        PRICE_PER_TOKEN = pricePerToken;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        royaltyAddress = _receiver;
        royaltyBps = _feeNumerator;
        
        _setDefaultRoyalty(royaltyAddress, royaltyBps);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}


