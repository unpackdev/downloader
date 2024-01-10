// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

error NotOnWhitelist();

contract PokerDawgsCollection is ERC721, Ownable {
    using Strings for uint256;

    address private mainWallet = 0x5Ea711bF646208eefD322D872565cC5Ba1e199DB;
    uint256 public constant NFT_MAX = 3333;
    uint256 public constant NFT_PRICE = 0.06 ether;
    uint256 public constant NFT_WHITELIST_PRICE = 0.05 ether;
    uint256 public constant NFTS_PER_MINT = 10;
    
    bytes32 private _merkleRoot;

    string private _contractURI;
    string private _tokenBaseURI;
    string public _mysteryURI;
    // end of change

    bool public revealed = false;
    bool public saleLive = false;
    bool public giftLive = false;
    bool public presaleLive = false;

    uint256 public totalSupply;

    constructor(string memory tokenBaseURI, string memory mysteryURI) ERC721("Poker Dawgs", "POKERDAWGS") {
        _tokenBaseURI = tokenBaseURI;
        _mysteryURI = mysteryURI;

        for (uint256 i = 0; i < 25; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += 25;
    }

    // internal 
    function _baseURI() internal view virtual override returns (string memory) {
        return _contractURI;
    }

    function mintGift(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "GIFTING_CLOSED");
        require(tokenQuantity > 0, "INVALID_TOKEN_QUANTITY");
        require(totalSupply <= NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 tokenQuantity) external payable {
        require(totalSupply <= NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");
        require(tokenQuantity > 0, "INVALID_TOKEN_QUANTITY");
        require(presaleLive, "PRESALE_CLOSED");
        require(isWhitelisted(msg.sender, _merkleProof), "USER_NOT_WHITELISTED");
        require(NFT_WHITELIST_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }
    
    function _leaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function isWhitelisted(address sender, bytes32[] memory _merkleProof) public view returns (bool) { 
        return MerkleProof.verify(_merkleProof, _merkleRoot, _leaf(sender));
    }

    function mint(
        uint256 tokenQuantity
    ) external payable {
        require(totalSupply <= NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");
        require(tokenQuantity > 0, "INVALID_TOKEN_QUANTITY");
        require(saleLive, "SALE_CLOSED");
        require(NFT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function withdraw() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        payable(mainWallet).transfer((currentBalance * 1000) / 1000);
    }

    function setMerkleRoot(bytes32 _merkleRootValue) external onlyOwner {
        _merkleRoot = _merkleRootValue;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function toggleGiftStatus() external onlyOwner {
        giftLive = !giftLive;
    }

    function togglePresaleStatus() public onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function setMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setContractURI(string calldata URI) public onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return _mysteryURI;
        }

        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}