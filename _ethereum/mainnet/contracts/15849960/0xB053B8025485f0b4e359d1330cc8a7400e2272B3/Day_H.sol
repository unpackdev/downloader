// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract Day_H is ERC721A, Ownable, ReentrancyGuard {

    uint256 public MAX_SUPPLY = 999;
    
    uint256 public WL_MINT_LIMIT = 1;
    uint256 public PUBLIC_MINT_LIMIT = 2;
    
    uint256 public WL_PRICE = 0.0099 ether;
    uint256 public PUBLIC_PRICE = 0.015 ether;

    enum MintingState {
        CLOSED,
        WL_SALE,
        PUBLIC_SALE
    }

    MintingState private mintingState = MintingState.CLOSED;

    bool _revealed = false;

    string private baseURI = "https://nftstorage.link/ipfs/bafybeie4hptkikssuzvu3u4psg7ifmgev7e5d5rrdjshgw7ki4sswdkvri";

    bytes32 wlRoot;

    mapping(address => bool) public mintedWL;

    address public constant DEV_ADDRESS = 0xC64aa843afa034AC44584b2804bd52f195c96096;  // 15 
    address public constant PROJECT_ADDRESS = 0x68603361c581e214563f9F60f46bECB32d706301;  // 85

    constructor() ERC721A("Day-H", "DAYH") {}

    function allowMint(uint256 numberOfTokens, bytes32[] memory proof) external payable {
        require(mintingState == MintingState.WL_SALE, "WL_SALE_NOT_ACTIVE");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY, "NOT_ENOUGH_SUPPLY"); 
        require(numberOfTokens <= WL_MINT_LIMIT, "EXCEED_WL_MINT_LIMIT");
        require(!mintedWL[msg.sender],"EXCEED_WL_MINT_LIMIT");
        require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(msg.value >= WL_PRICE * numberOfTokens, "WRONG_ETH_VALUE");
        mintedWL[msg.sender] = true;
        _safeMint(msg.sender, numberOfTokens);
    }

    function publicMint( uint256 numberOfTokens) external payable {
        require(mintingState == MintingState.PUBLIC_SALE, "PUBLIC_SALE_NOT_ACTIVE");
        require(numberMinted(msg.sender) + numberOfTokens <= PUBLIC_MINT_LIMIT,"ONLY_2_IS_ALLOWED");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(msg.value >= PUBLIC_PRICE * numberOfTokens, "WRONG_ETH_VALUE");
        _safeMint(msg.sender, numberOfTokens);
    }

    // URI
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    // MINTING STATE
    function activatePublicMint() external onlyOwner {
        mintingState = MintingState.PUBLIC_SALE;
    }

    function activateWLMint() external onlyOwner {
        mintingState = MintingState.WL_SALE;
    }

    function pauseSale() external onlyOwner {
        mintingState = MintingState.CLOSED;
    }

    function getMintingState() public view returns (MintingState) {
        return mintingState;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ROOT SETTERS
    function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
    }

    // LIMIT SETTERS
    function setPublicMintLimit(uint256 _mintLimit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _mintLimit;
    }

    function setWLMintLimit(uint256 _mintLimit) external onlyOwner {
        WL_MINT_LIMIT = _mintLimit;
    }

    function getPublicMintLimit() public view returns (uint256) {
        return PUBLIC_MINT_LIMIT;
    }

    function getWLMintLimit() public view returns (uint256) {
        return WL_MINT_LIMIT;
    }

    // PRICE SETTERS, GETTERS
    function setPublicPrice(uint256 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setWlPrice(uint256 _price) external onlyOwner {
        WL_PRICE = _price;
    }

    function getPublicPrice() public view returns (uint256) {
        return PUBLIC_PRICE;
    }

    function getWLPrice() public view returns (uint256) {
        return WL_PRICE;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function mintForTeam(uint256 numberOfTokens) external onlyOwner {
       _safeMint(msg.sender, numberOfTokens);
    }

    function batchMint(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "MISMATCH_ADDRESSES_AMOUNT_LENGTH");
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        uint256 bal_a = (balance * 15) / 100;
        payable(DEV_ADDRESS).transfer(bal_a);
        payable(PROJECT_ADDRESS).transfer(address(this).balance);
    }
}
