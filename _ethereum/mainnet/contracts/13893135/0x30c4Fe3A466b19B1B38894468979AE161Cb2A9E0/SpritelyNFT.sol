// SPDX-License-Identifier: MIT

/**************************************************************************************
*                                                                                     *
*                                       @@    @@                                      *
*      @@@@@@    @@@@@@@@@  @@  @@@@          @@         @@@@@    @@      @@    @@    *
*    @@          @@@@@@@@@  @@@@      @@@@    @@@@@@@  @@     @@  @@      @@    @@    *
*      @@@@@@    @@     @@  @@          @@    @@       @@@@@@@@@  @@      @@    @@    *
*            @@  @@@@@@@@@  @@          @@    @@       @@         @@        @@@@      *
*    @@      @@  @@@@@@@@@  @@          @@    @@       @@         @@          @@      *
*      @@@@@@    @@         @@        @@@@@@    @@@@@    @@@@@@@    @@@@  @@@@        *
*                @@                                                                   *
*                                                                                     *
**************************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract SpritelyNFT is ERC721Enumerable, Ownable {
    bool public publicSaleIsActive = false;
    bool public presaleIsActive = false;
    bool public revealed = false;

    string public baseURI = "";
    string public previewURI = "";

    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public constant PRICE_PER_TOKEN = 0.06 ether;

    mapping(address => bool) public allowlist;

    constructor() ERC721("SpritelyNFT", "SPRITE") {}

    // Internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Public

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if(!revealed) {
            return previewURI;
        }

        return super.tokenURI(tokenId);
    }

    function mint(uint numToMint) public payable {
        if (!publicSaleIsActive) {
            require(presaleIsActive, "Sale is not active");
            require(allowlist[msg.sender] == true, "Sender address not on allowlist");
        }
        
        uint256 ts = totalSupply();
        require(ts + numToMint <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numToMint <= msg.value, "Not enough Ether sent for mint");

        for (uint256 i = 1; i <= numToMint; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // Only owner

    function addToAllowlist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowlist[_addresses[i]] = true;
        }
    }

    function setPreviewURI(string memory _newPreviewUri) external onlyOwner {
        previewURI = _newPreviewUri;
    }

    function setBaseURI(string memory _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function setPresaleStatus(bool _isActive) external onlyOwner {
        presaleIsActive = _isActive;
    }

    function setPublicSaleStatus(bool _isActive) external onlyOwner {
        publicSaleIsActive = _isActive;
    }

    function revealTokens() external onlyOwner {
        require(bytes(baseURI).length > 0, "baseURI must be set first");
        revealed = true;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}