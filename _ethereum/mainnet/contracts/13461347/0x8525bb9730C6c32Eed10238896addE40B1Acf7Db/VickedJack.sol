// SPDX-License-Identifier: MIT
/*
____   ____.____________  ____  __.___________________    
\   \ /   /|   \_   ___ \|    |/ _|\_   _____/\______ \   
 \   Y   / |   /    \  \/|      <   |    __)_  |    |  \  
  \     /  |   \     \___|    |  \  |        \ |    `   \ 
   \___/   |___|\______  /____|__ \/_______  //_______  / 
                       \/        \/        \/         \/  
.____       _____ __________  _________                   
|    |     /  _  \\______   \/   _____/                   
|    |    /  /_\  \|    |  _/\_____  \                    
|    |___/    |    \    |   \/        \                   
|_______ \____|__  /______  /_______  /                   
        \/       \/       \/        \/                    
 */
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract VickedJacks is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public MAX_SUPPLY = 2500;
    uint256 public MAX_PUBLIC_MINT = 5;
    uint256 public PRICE_PER_TOKEN = 0.05 ether;

    mapping(address => uint8) private _allowList;

    constructor() ERC721("VickedJacks", "VickedJacks") {}

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint)
        external
        onlyOwner
    {
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
        require(
            numberOfTokens <= _allowList[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function mintJack(address to, uint256 num) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < num; i++) {
            _safeMint(to, supply + i);
        }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        MAX_PUBLIC_MINT = newMaxMint;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        PRICE_PER_TOKEN = newPrice;
    }

    function getMaxMint() public view returns (uint256) {
        return MAX_PUBLIC_MINT;
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

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
