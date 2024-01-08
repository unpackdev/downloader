// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";

contract RuggedMugs is ERC721URIStorage, ERC721Enumerable, Ownable {
    
    // Token/Mint data
    uint256 private constant MAX_NUM_SHARES = 10000;
    uint256 public constant MAX_MINTS_PER_TXN = 25;
    uint256 public m_maxTokenSupply;
    uint256 public m_mintPrice;
    bool public m_saleIsActive;
    string public m_baseURI;
    string public m_provenanceHash;
    
    // Shareholder data
    address[7] private m_shareholders;
    uint[7] private m_shares;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxMugSupply) ERC721(name, symbol) {
        m_maxTokenSupply = maxMugSupply;
        m_mintPrice = 30000000 gwei; // 0.03 ETH
        m_saleIsActive = false;
        m_provenanceHash = "";
        m_baseURI = "";

        m_shareholders[0] = 0x078dC8FF71Ebf938ffe746De7e2c926f64b14F1E; // Cryptic Coffee
        m_shareholders[1] = 0x16272E839A5C29A3Fa90E670Cb599d233b6943aC; // Leo Sal
        m_shareholders[2] = 0x78C46A46AF5F751bA96ba3ae1EFfcF08A04E3af3; // Iron Mike
        m_shareholders[3] = 0x88eae1D977d1B909165c904A23891878CB02F1F3; // Mocha Maniac
        m_shareholders[4] = 0x1e8A65A4d38aC5aA5739fB45A09A06a967Dc4A8d; // Charity
        m_shareholders[5] = 0x7B34Eb433D08C1100F1e5F81AEeD64e47583880E; // Community
        m_shareholders[6] = 0xD6061818731934Feb49BFE954Cf970017806340F; // Roadmap
        
        m_shares[0] = 2041;
        m_shares[1] = 2041;
        m_shares[2] = 2041;
        m_shares[3] = 474;
        m_shares[4] = 2632;
        m_shares[5] = 386;
        m_shares[6] = 385;
    }

    /// Functions for minting

    function chugMugs(uint256 numberOfTokens) public payable {
        require(m_saleIsActive, "Sale must be active to chug Rugged Mugs");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can only mint 25 mugs at a time");
        require(numberOfTokens + totalSupply() <= m_maxTokenSupply, "Purchase would exceed max available mugs");
        require(numberOfTokens * m_mintPrice <= msg.value, "Ether value sent is not enough");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 nextTokenId = totalSupply() + 1;
            if (nextTokenId <= m_maxTokenSupply) {
                _safeMint(msg.sender, nextTokenId);
            }
        }
    }

    function reserveMint(uint256 numberOfTokens) public onlyOwner {        
        reserveMint(numberOfTokens, msg.sender);
    }

    function reserveMint(uint256 numberOfTokens, address mintAddress) public onlyOwner {        
        require(numberOfTokens + totalSupply() <= m_maxTokenSupply, "Purchase would exceed max available mugs");
        
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 nextTokenId = totalSupply() + 1;
            if (nextTokenId <= m_maxTokenSupply) {
                _safeMint(mintAddress, nextTokenId);
            }
        }
    }

    /// Functions for managing token metadata

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory ipfsHash) public onlyOwner {
        _setTokenURI(tokenId, ipfsHash);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        m_baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return m_baseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        m_provenanceHash = provenanceHash;
    }

    /// Functions to change mint state - ONLY OWNER

    function setMaxTokenSupply(uint256 maxMugSupply) public onlyOwner {
        m_maxTokenSupply = maxMugSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        m_mintPrice = newPrice;
    }

    function flipSaleState() public onlyOwner {
         m_saleIsActive = !m_saleIsActive;
    }
    
    /// Functions for ether withdrawal - ONLY OWNER

    function forceWithdraw(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        for (uint256 i = 0; i < m_shareholders.length; i++) {
            uint256 payment = amount * m_shares[i] / MAX_NUM_SHARES;
            Address.sendValue(payable(m_shareholders[i]), payment);
            emit PaymentReleased(m_shareholders[i], payment);
        }
    }

    /// Overrides

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}