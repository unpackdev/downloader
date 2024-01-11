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

contract ToolsOfTheGreatSpecial is ERC721, ERC721Enumerable, Ownable {

    /**
     * Token
     */
    uint256 public constant MAX_SUPPLY = 12;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant PRICE_PER_TOKEN = 0.12 ether;

    constructor() ERC721("ToolsOfTheGreatSpecial", "TOTGS") {
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
    string public PROVENANCE;
    string private _baseURIextended;

    function reserve(uint numberOfTokens) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < numberOfTokens; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}


