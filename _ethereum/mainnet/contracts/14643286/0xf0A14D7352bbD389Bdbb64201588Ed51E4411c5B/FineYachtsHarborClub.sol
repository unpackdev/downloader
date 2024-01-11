// SPDX-License-Identifier: None
pragma solidity 0.8.11;

//  ██████▒▓██   ██▓ ██░ ██  ▄████▄
// ▓██   ▒  ▒██  ██▒▓██░ ██▒▒██▀ ▀█
// ▒████ ░   ▒██ ██░▒██▀▀██░▒▓█    ▄
// ░▓█▒  ░   ░ ▐██▓░░▓█ ░██ ▒▓▓▄ ▄██▒
// ░▒█░      ░ ██▒▓░░▓█▒░██▓▒ ▓███▀ ░
//  ▒ ░       ██▒▒▒  ▒ ░░▒░▒░ ░▒ ▒  ░
//  ░       ▓██ ░▒░  ▒ ░▒░ ░  ░  ▒
//  ░ ░     ▒ ▒ ░░   ░  ░░ ░░
//          ░ ░      ░  ░  ░░ ░
//          ░ ░             ░

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

import "./Errors.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FineYachtsHarborClub is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;
    address private adminAddress;

    // Metadata base URI
    string public baseURI;
    string public provenance = "";

    // Max mints per wallet
    uint256 public constant presaleMaxMints = 10;
    uint256 public publicSaleMaxMints = 10;

    // Mint price & supply
    uint256 public constant mintPrice = 0.058 ether;
    uint256 public maxSupply = 8888;

    // Presale merkle root
    bytes32 public merkleRoot;

    // Contract states
    bool public publicSaleActive = false;
    bool public presaleActive = false;
    bool public isLocked = false;

    // Contract events
    event BaseURIUpdated(string _baseUri);
    event PermanentURI(string _value, uint256 indexed _id);

    mapping (address => uint256) private mintsPerWallet;

    struct InfoStruct {
        uint256 maxMints;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 mintPrice;
        uint256 presaleMaxMints;
        uint256 publicSaleMaxMints;
        string baseURI;
        bool isLocked;
        bool presaleActive;
        bool publicSaleActive;
    }

    constructor(string memory _baseURI, address[] memory _payees, uint256[] memory _shares) ERC721A("Fine Yachts Harbor Club", "FYHC") PaymentSplitter(_payees, _shares) payable {
        baseURI = _baseURI;
    }

    function freezeMetadata() public onlyOwner {
        isLocked = true;

        uint256 s = totalSupply();
        for (uint i = 0; i < s; ++i) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    function setPublicSale(bool state) public onlyOwner {
        publicSaleActive = state;
    }

    function setPreSale(bool state) public onlyOwner {
        presaleActive = state;
    }

    function setAdminAddress(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        if (isLocked) revert ContractLocked();

        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        if (isLocked) revert ContractLocked();

        maxSupply = supply;
    }

    function setMaxMints(uint256 _maxMints) external onlyOwner {
        publicSaleMaxMints = _maxMints;
    }

    function mint(uint256 amount) external payable nonReentrant {
        if(!publicSaleActive) revert SaleClosed();

        uint256 s = totalSupply();
        if(s + amount > maxSupply) revert SoldOut();
        if(mintsPerWallet[msg.sender] + amount > publicSaleMaxMints) revert WalletLimitReached(publicSaleMaxMints);
        if(msg.value < mintPrice * amount) revert InvalidPriceSentForAmount(msg.value, mintPrice * amount);

        _safeMint(msg.sender, amount);
        mintsPerWallet[msg.sender] += amount;
        delete s;
    }

    function mintPresale(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        if(!presaleActive) revert PresaleClosed();

        // Check if address is allowed to mint in presale status
        if (!isPresaleEligible(msg.sender, _merkleProof)) revert NotOnAllowlist();

        uint256 s = totalSupply();
        if (s + amount > maxSupply) revert SoldOut();
        if (mintsPerWallet[msg.sender] + amount > presaleMaxMints) revert WalletLimitReached(presaleMaxMints);
        if (msg.value < mintPrice * amount) revert InvalidPriceSentForAmount(msg.value, mintPrice * amount);

        _safeMint(msg.sender, amount);
        mintsPerWallet[msg.sender] += amount;
        delete s;
    }

    function isPresaleEligible(address _addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // Used to mint founders reserve and promotional giveaways.
    function gift(address[] calldata toAddresses, uint256 amount) public onlyOwner {
        uint total = 0;
        uint len = toAddresses.length;
        uint256 s = totalSupply();
		for(uint i = 0; i < len; ++i){
            total += amount;
		}
        if(s + total >= maxSupply) revert SoldOut();
        delete total;

        for(uint256 i = 0; i < len; i++) {
            _safeMint(toAddresses[i], amount);
        }

        delete s;
        delete len;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function withdrawSplit(address[] calldata addresses) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < addresses.length; i++) {
            address payable wallet = payable(addresses[i]);
            release(wallet);
        }
    }

    function burn(uint tokenId) public {
        if(msg.sender != adminAddress) revert NotAuthorized();
        _burn(tokenId);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getInfo() public view returns (InfoStruct memory) {
        InfoStruct memory info;
        info.presaleMaxMints = presaleMaxMints;
        info.publicSaleMaxMints = publicSaleMaxMints;
        info.maxSupply = maxSupply;
        info.totalSupply = totalSupply();
        info.mintPrice = mintPrice;
        info.baseURI = baseURI;
        info.presaleActive = presaleActive;
        info.publicSaleActive = publicSaleActive;
        info.isLocked = isLocked;
        return info;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

