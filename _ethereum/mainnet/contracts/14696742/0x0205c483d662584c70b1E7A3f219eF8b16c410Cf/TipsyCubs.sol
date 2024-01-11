// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract TipsyCubs is ERC721A, Ownable {
    using Strings for uint256;
    
    uint256 public PUBLIC_PRICE = 0.1 ether;
    // The project can never go above 5000 supply
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public WHITELIST_SUPPLY = 3000;
    uint256 public PUBLICSALE_SUPPLY = 300;
    uint256 public reserved = 50;

    bool public whitelistMintOpen = false;
    bool public publicSaleOpen = false;
    string public baseExtension = '.json';
    string private _baseTokenURI;
    string public PROVENANCE;

    bytes32 public merkleRoot;

    constructor() ERC721A("Tipsy Cubs", "TIPSYCUBS") {}

    mapping(address=>bool) public claimed;

    function freeMint(bytes32[] calldata _merkleProof) public payable {
        require(whitelistMintOpen, "whitelist claim not open");
        require(totalSupply() + 2 <= WHITELIST_SUPPLY, "supply limit");
        require(claimed[msg.sender] == false, "already claimed");
        claimed[msg.sender] = true;
        require(MerkleProof.verify(_merkleProof, merkleRoot, toBytes32(msg.sender)) == true, "wrong merkle proof");

        _safeMint(msg.sender, 2);
    }

    function mintCubs(uint256 quantity) external payable {
        require(publicSaleOpen, "Public Sale not open");
        require(quantity > 0, "quantity less than or equal to 0");
        require(totalSupply() + quantity <= PUBLICSALE_SUPPLY, "public sale supply limit");
        require(totalSupply() + quantity <= MAX_SUPPLY - reserved, "total supply limit");
        require(msg.value >= PUBLIC_PRICE * quantity, "insufficient ether value");

        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    
    function toBytes32(address addr) pure internal returns (bytes32){
        return bytes32(uint256(uint160(addr)));
    }

    /* *************** */
    /* OWNER FUNCTIONS */
    /* *************** */
    function giveAway(address to, uint256 quantity) external onlyOwner {
        require(quantity <= reserved);
        reserved -= quantity;
        _safeMint(to, quantity);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function toggleWhitelistMint() external onlyOwner {
        whitelistMintOpen = !whitelistMintOpen;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function changePublicSalePrice(uint256 price) external onlyOwner {
        PUBLIC_PRICE = price;
    }

    function changeWhitelistSupply(uint256 newSupply) external onlyOwner {
        WHITELIST_SUPPLY = newSupply;
    }

    function changePublicSupply(uint256 newSupply) external onlyOwner {
        PUBLICSALE_SUPPLY = newSupply;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}