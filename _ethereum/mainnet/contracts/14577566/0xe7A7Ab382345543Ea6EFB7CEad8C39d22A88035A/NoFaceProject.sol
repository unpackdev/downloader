// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract NoFaceProject is ERC721A, Ownable, ReentrancyGuard {
    using Strings
    for uint256;

    string private baseURI;
    string private baseExtension = ".json";
    string private HiddenUri;
    string public provenanceHash;
    bytes32 private ogRoot;
    bytes32 private wlRoot;
    
    uint256 public preSaleStartTime = 1649872800;
    uint256 public publicSaleStartTime = 1649959200;
    
    uint256 public mintPrice = 0.06 ether;
    uint256 public mintPriceWL = 0.045 ether;
    uint256 public mintPriceOG2 = 0.045 ether;
    uint256 public mintPriceOG1 = 0.00 ether;
    
    uint256 public maxSupply = 888;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public maxMintAmountPerWhitelist = 2;
    uint256 public freeMintAmountPerOG = 1;
    
    bool public isContractActive = false;
    bool private isHidden = true;
    mapping(address => uint256) public mintCountPerAdd;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initHiddenUri,
        string memory _initProvenanceHash,
        bytes32[] memory _ogRoot,
        bytes32[] memory _wlRoot
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setHiddenURI(_initHiddenUri);
        setProvenanceHash(_initProvenanceHash);
        setOgRoot(_ogRoot[0]);
        setWlRoot(_wlRoot[0]);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    // presales
    function preSaleMint(uint256 _mintAmount, bytes32[] calldata _proof) external payable callerIsUser nonReentrant {
        require(isContractActive, "Contract is not Active");
        require(_mintAmount > 0, "At least 1 NFT is needed");
        require(_mintAmount <= maxMintAmountPerTx, "Max Mint Amount Exceeded");
        require(preSaleStartTime != 0 && block.timestamp >= preSaleStartTime, "presale has not started yet");
        require(publicSaleStartTime != 0 && block.timestamp < publicSaleStartTime, "presale has ended");
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");

        uint256 mintedCount = mintCountPerAdd[msg.sender];
        uint256 calculatedMintPrice = mintPrice * _mintAmount;

        bool isOG = isOGlisted(_proof);
        if (isOG || isWhitelisted(_proof)) {
            require(_mintAmount + mintedCount <= maxMintAmountPerWhitelist, "Exceed Minting Limit");
            //calculate price for OG
            if (isOG) {
                uint256 freeMintBalance = freeMintAmountPerOG - mintedCount;
                if (freeMintBalance >= _mintAmount) {
                    calculatedMintPrice = mintPriceOG1 * _mintAmount;
                } else {
                    calculatedMintPrice = (mintPriceOG1 * freeMintBalance) + (mintPriceOG2 * (_mintAmount - freeMintBalance));
                }
            }
            //calculate price for WL
            else {
                calculatedMintPrice = (mintPriceWL * _mintAmount);
            }
        } else {
            require(false, "This Address is not whitelisted");
        }
        require(msg.value >= calculatedMintPrice, "Insufficient Funds");
        mintCountPerAdd[msg.sender] += _mintAmount;
        
        _safeMint(msg.sender, _mintAmount);
    }

    // public
    function mint(uint256 _mintAmount) external payable nonReentrant {
        require(isContractActive, "Contract is not Active");
        require(publicSaleStartTime != 0 && block.timestamp >= publicSaleStartTime, "sale has not started yet");
        require(_mintAmount > 0, "At least 1 NFT is needed");
        require(_mintAmount <= maxMintAmountPerTx, "Max Mint Amount Exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");

        uint256 calculatedMintPrice = mintPrice * _mintAmount;
        require(msg.value >= calculatedMintPrice, "Insufficient Funds");

        _safeMint(msg.sender, _mintAmount);
    }

    function isWhitelisted(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, wlRoot, leaf);
    }

    function isOGlisted(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, ogRoot, leaf);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (isHidden == true) {
            return HiddenUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ?
            string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) :
            "";
    }

    function getMintedCountPerAdd(address user) public view returns(uint256) {
            uint256 count = mintCountPerAdd[user];
            return count;
        }

    //only Owner	
    
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
          provenanceHash = _provenanceHash;
    }
    
    function giveaway(address to, uint256 _mintAmount) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");
        require(_mintAmount <= maxSupply, 'Minting would exceed total supply');
        _safeMint(to, _mintAmount);
    }

    function reservedMint(uint256 _mintAmount) public onlyOwner {
        require(_mintAmount <= maxSupply, 'Minting would exceed total supply');
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");
        _safeMint(msg.sender, _mintAmount);
    }

    function setContractActive(bool _state) public onlyOwner {
        isContractActive = _state;
    }

    function setHiddenURI(string memory _URI) public onlyOwner {
        HiddenUri = _URI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }
    
    function setWLMintPrice(uint256 _newPrice) public onlyOwner {
        mintPriceWL = _newPrice;
    }
    
    function setOG1MintPrice(uint256 _newPrice) public onlyOwner {
        mintPriceOG1 = _newPrice;
    }
    
    function setOG2MintPrice(uint256 _newPrice) public onlyOwner {
        mintPriceOG2 = _newPrice;
    }

    function setMaxMintAmountPerTx(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmountPerTx = _newmaxMintAmount;
    }

    function setMaxMintAmountPerWhitelist(uint256 _limit) public onlyOwner {
        maxMintAmountPerWhitelist = _limit;
    }

    function setOgRoot(bytes32 _root) public onlyOwner {
        ogRoot = _root;
    }

    function setWlRoot(bytes32 _root) public onlyOwner {
        wlRoot = _root;
    }

    function setPreSaleStartTime(uint256 _startTime) public onlyOwner {
        preSaleStartTime = _startTime;
    }

    function setPublicSaleStartTime(uint256 _startTime) public onlyOwner {
        publicSaleStartTime = _startTime;
    }

    function reveal() public onlyOwner {
        isHidden = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call {
            value: address(this).balance
        }("");
        require(success);
    }
}