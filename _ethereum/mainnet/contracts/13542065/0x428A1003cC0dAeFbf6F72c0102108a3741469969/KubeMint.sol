// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract KubeMint is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, ReentrancyGuard, Ownable {
    string constant public IPFS_HASH = "Qmerg2mmDfsSbEQFn8FcJDTBggiMoWZrdtx4twTq1BLCvN";
    uint256 constant public ETH_WL_PRICE = 0.05 ether;
    uint256 constant public ETH_PRICE = 0.08 ether;
    uint256 constant public MAX_PER_WL_TX = 2;
    uint256 constant public MAX_PER_TX = 5;
    uint256 constant public MAX_SUPPLY = 4001;
    uint256 constant public RESERVED = 400;
    uint256 constant public WL = 400;
    bool public isBurningEnabled = false;
    bool public isMintingEnabled = true;
    bool public isWLMintingEnabled = true;
    address payable public dat_kube;

    event Minted(address to, uint256 quantity);

    constructor() ERC721("Dat Kube", "DAT3") {
        dat_kube = payable(address(0x7CA220ffD07bE0a729870944FC33545885DBC969));
    }

    function mintOne() public payable nonReentrant {
        _mint(1);
    }

    function mintTwo() public payable nonReentrant {
        _mint(2);
    }

    function mintThree() public payable nonReentrant {
        _mint(3);
    }

    function mintFour() public payable nonReentrant {
        _mint(4);
    }

    function mintFive() public payable nonReentrant {
        _mint(5);
    }

    function mintWLOne() public payable nonReentrant {
        _mintWL(1);
    }

    function mintWLTwo() public payable nonReentrant {
        _mintWL(2);
    }

    function _mint(uint256 quantity) internal {
        require(msg.sender == dat_kube || isMintingEnabled, "Mint: not enabled yet");
        require(quantity <= MAX_PER_TX, "Mint: too many");
        require(totalSupply() < MAX_SUPPLY - RESERVED, "Mint: sold out");
        require(totalSupply() + quantity <= MAX_SUPPLY - RESERVED, "Mint: exceeds max supply");
        require(msg.value >= getPrice(quantity), "Mint: not enough ETH sent");
        
        if (msg.value > getPrice(quantity)) {
            payable(msg.sender).transfer(msg.value - getPrice(quantity));
        }
        
        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;

            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, IPFS_HASH);
        }

        emit Minted(msg.sender, quantity);
    }

    function _mintWL(uint256 quantity) internal {
        require(msg.sender == tx.origin, "Mint: not allowed from contract");
        require(quantity <= MAX_PER_WL_TX, "Mint: too many");
        require(totalSupply() < WL, "Mint: whitelist is closed");
        require(totalSupply() + quantity <= WL, "Mint: exceeds max whitelist supply");
        require(msg.value >= getPrice(quantity), "Mint: not enough ETH sent");

        if (msg.value > getWLPrice(quantity)) {
            payable(msg.sender).transfer(msg.value - getWLPrice(quantity));
        }
        
        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;

            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, IPFS_HASH);
        }

        emit Minted(msg.sender, quantity);
    }

    function mintSpecial(address _to, uint256 quantity) public onlyOwner() {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Mint: exceeds max reserved supply");

        for(uint256 i = 0; i < quantity; i++){
            uint256 tokenId = totalSupply() + 1;

            _safeMint(_to, tokenId);
            _setTokenURI(tokenId, IPFS_HASH);
        }
    }

    function getPrice(uint256 quantity) public pure returns(uint256) {
        return ETH_PRICE * quantity;
    }

    function getWLPrice(uint256 quantity) public pure returns(uint256) {
        return ETH_WL_PRICE * quantity;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i = 0; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        
        return tokensId;
    }

    function withdraw() public {
        dat_kube.transfer(address(this).balance);
    }
    
    function toggleBurner() public onlyOwner {
        isBurningEnabled = !isBurningEnabled;
    }

    function toggleMinter() public onlyOwner {
        isMintingEnabled = !isMintingEnabled;
    }

    function toggleWLMinter() public onlyOwner {
        isWLMintingEnabled = !isWLMintingEnabled;
    }

    function burn(uint256 tokenId) public virtual override {
        require(isBurningEnabled, "Burn: not yet enabled");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Burn: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function remainingSupply() public view returns(uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    fallback() external payable {}
    
    receive() external payable {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://ipfs/";
    }
}