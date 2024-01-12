// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

contract WildpawsTwin is ERC721, Ownable, ReentrancyGuard, ERC721Enumerable {
    using Strings for uint256;
    using ECDSA for bytes32;

    enum SaleStatus {
        PAUSED,
        ALLOWLIST,
        PUBLIC
    }    

    SaleStatus public saleStatus = SaleStatus.PAUSED;
    //allowlist
    bytes32 public allowlistMerkleRoot;
    mapping(address => bool) public allowlistSalePurchased;


    string public PROVENANCE;
    string private _baseURIextended;
    string public uriSuffix = ".json";

    //Configuration
    uint256 public MAX_SUPPLY;


    uint256 public teamAmountMinted;

    // 1/1 mint
    uint256 public constant PRICE_PER_TOKEN_ONE = 0.38 ether;
    mapping(address => uint256) public oneSalesMinterToTokenQty;

    constructor(
        string memory _basesURI,
        uint256 _maxSupply   
    ) ERC721("WildpawsTwin", "WPTWIN") {
        setBaseURI(_basesURI);
        setMaxSupply(_maxSupply);
    }

    event Minted(
        string Type,
        uint256 tokenID,
        address mintedAddress
    );

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    modifier mintCompliance(uint256 tokenID) {
        require(tokenID > 0 && tokenID <= MAX_SUPPLY, 'Wrong Token ID');
        require(totalSupply() + 1 <= MAX_SUPPLY, 'Max supply exceeded!');
        _;
    }
    function getRemainingSupply() public view returns (uint256) {
        unchecked { return MAX_SUPPLY - totalSupply(); }
    }

    function airdrop(address address_to, uint256 tokenID) 
        external 
        nonReentrant
        onlyOwner
        mintCompliance(tokenID)
        {
        unchecked {
            teamAmountMinted += 1;
        }
        _safeMint(address_to, tokenID);
        emit Minted(
            "twin_collection",
            tokenID,
            address_to
        );
    }

    function reserve(uint256 tokenID) 
        external 
        nonReentrant
        onlyOwner
        mintCompliance(tokenID)
        {
        _safeMint(msg.sender, tokenID);
        emit Minted(
            "twin_collection",
            tokenID,
            msg.sender
        );
        
    }

    function mint(uint256 tokenID) 
        external 
        payable
        nonReentrant
        callerIsUser
        mintCompliance(tokenID)
        {
            require(saleStatus == SaleStatus.PUBLIC, "Public Sale Not Active");
            require(msg.value >= PRICE_PER_TOKEN_ONE, "Ether value sent is not correct");
            unchecked {
                oneSalesMinterToTokenQty[msg.sender] += 1 ;
            }
            _safeMint(msg.sender, tokenID);
            emit Minted(
                "twin_collection",
                tokenID,
                msg.sender
            );
    }
    function allowlistMint(bytes32[] memory _proof, uint256 tokenID) 
        external 
        payable
        nonReentrant
        callerIsUser
        mintCompliance(tokenID)
        {
            require(saleStatus == SaleStatus.ALLOWLIST, "Allowlist Sale Not Active");
            require(oneSalesMinterToTokenQty[msg.sender] + 1 <= 5 , "Max Allowlist Exceeded");
            require(
                MerkleProof.verify(_proof, allowlistMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
                "Wallet wildlist not found. Public adoption opens on 14th July, 5:55pm!"
            );
            require(msg.value >= PRICE_PER_TOKEN_ONE, "Ether value sent is not correct");
            unchecked {
                oneSalesMinterToTokenQty[msg.sender] += 1 ;
            }
            _safeMint(msg.sender, tokenID);
            emit Minted(
                "twin_collection",
                tokenID,
                msg.sender
            );
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), uriSuffix)) : "";
    }     
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function setSaleStatus(SaleStatus _status) external onlyOwner {
        saleStatus = _status;
    }
    function setMerkleRoots(bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }
    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }
    function setMaxSupply(uint256 maxSupply) public onlyOwner() {
        MAX_SUPPLY = maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }   

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
   
}
