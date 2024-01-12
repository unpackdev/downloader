// SPDX-License-Identifier: MIT

/*

 ██░ ██  ▄▄▄       ██▓     ██▓        ██▓███   ▄▄▄        ██████   ██████ 
▓██░ ██▒▒████▄    ▓██▒    ▓██▒       ▓██░  ██▒▒████▄    ▒██    ▒ ▒██    ▒ 
▒██▀▀██░▒██  ▀█▄  ▒██░    ▒██░       ▓██░ ██▓▒▒██  ▀█▄  ░ ▓██▄   ░ ▓██▄   
░▓█ ░██ ░██▄▄▄▄██ ▒██░    ▒██░       ▒██▄█▓▒ ▒░██▄▄▄▄██   ▒   ██▒  ▒   ██▒
░▓█▒░██▓ ▓█   ▓██▒░██████▒░██████▒   ▒██▒ ░  ░ ▓█   ▓██▒▒██████▒▒▒██████▒▒
 ▒ ░░▒░▒ ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░   ▒▓▒░ ░  ░ ▒▒   ▓▒█░▒ ▒▓▒ ▒ ░▒ ▒▓▒ ▒ ░
 ▒ ░▒░ ░  ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░   ░▒ ░       ▒   ▒▒ ░░ ░▒  ░ ░░ ░▒  ░ ░
 ░  ░░ ░  ░   ▒     ░ ░     ░ ░      ░░         ░   ▒   ░  ░  ░  ░  ░  ░  
 ░  ░  ░      ░  ░    ░  ░    ░  ░                  ░  ░      ░        ░

*/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface IASM {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address ownerAddress) external view returns (uint256);
}

contract AsylumHallPass is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //proxy info
    address public purgatory = 0x000000000000000000000000000000000000dEaD;
    address public asm = 0x8513Db429F5fB564f473fD2e5c523fae33331Aa5;
    IASM public iasm = IASM(asm);

    //whitelist settings
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    
    //collection settings
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    //sale settings
    uint256 public cost = 0 ether;
    uint256 public maxSupply = 2500;
    uint256 public maxMintAmountPerTx;
    
    //contract control variables
    bool public whitelistMintEnabled = false;
    bool public paused = true;
    bool public revealed = true;

    constructor(uint256 _maxMintAmountPerTx, string memory _hiddenMetadataUri) 
        ERC721A("Hall Pass", "HP") {
        maxMintAmountPerTx = _maxMintAmountPerTx;
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }


    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount) {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof!");

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount, uint256 _burnTokenId) public mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        address ownerNftMatch = iasm.ownerOf(_burnTokenId);
        uint256 ownerAmount = iasm.balanceOf(_msgSender());
        require(ownerAmount >= 2, "must at least own 2 asylum residents");
        require(ownerNftMatch == _msgSender(), "Our patient records indicate IDENTITY FRAUD ! ... (not your patient/nft)");

        iasm.safeTransferFrom(_msgSender(),purgatory,_burnTokenId);
        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function trialWinnersDrop(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        require(addresses.length == count.length, "mismatching lengths!");

        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], count[i]);
        }

        require(totalSupply() <= maxSupply, "Exceed MAX_SUPPLY");
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI,_tokenId.toString(),uriSuffix))
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
