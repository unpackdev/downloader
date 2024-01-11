// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract JsonGmi is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 8888;

    uint256 public constant FREE_MINT_LIMIT = 1;
    uint256 public constant MAX_MINT = 10;
    uint256 public constant MINT_PRICE = 0.025 ether;

    bool public isPublicSaleActive = false;

    bool _revealed = false;

    string private baseURI = "";

    address signer;

    mapping(address => uint256) addressBlockBought;
    mapping(address => bool) public mintedPublic;

    
    mapping(bytes32 => bool) public usedDigests;

    constructor(address _signer) ERC721A("JsonGmi", "JSONGMI") {
        signer = _signer;
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isPublicSaleActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    //Essential
    function publicMint(uint64 expireTime, bytes memory sig, uint256 numberOfTokens) external isSecured(1) payable {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(numberMinted(msg.sender) <= MAX_MINT,"MAX_MINT_REACHED");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");

        if(numberMinted(msg.sender) < 1) {
            require(msg.value == MINT_PRICE * (numberOfTokens - 1), "WRONG_ETH_VALUE");
        } else {
            require(msg.value == MINT_PRICE * numberOfTokens, "WRONG_ETH_VALUE_2");
        }

        usedDigests[digest] = true;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    //Essential
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    //Essential
    function togglePublicMintStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
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

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function isAuthorized(bytes memory sig, bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(msg.sender).transfer(address(this).balance);
    }
}
