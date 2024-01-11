// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "_ERC721A.sol";


contract CryptowildDruids is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant DRUID_MAX = 4000;
    uint256 public constant DRUID_FREEMINT_MAX = 1;
    uint256 public constant DRUID_PRESALE_MAX = 7;
    uint256 public constant DRUID_PUBLIC_MAX = 5;

    uint256 public druidPresalePrice = 0.08 ether;
    uint256 public druidPublicPrice = 0.1 ether;

    mapping(address => bool) public presaleList;
    mapping(address => bool) public freeList;
    mapping(address => uint256) public presaleListPurchased;
    mapping(address => uint256) public publicListPurchased;
    mapping(address => uint256) public freeListPurchased;

    string private _contractURI;
    string private _tokenBaseURI;
    address private _companyAddress;

    uint256 public airdropAmountMinted;
    uint256 public freeAmountMinted;
    uint256 public publicAmountMinted;
    uint256 public presaleAmountMinted;

    bool public presaleLive = false; // airdrop, freemint, presale
    bool public saleLive = false; // airdrop, freemint, public sale
    bool public revealed = false;

    constructor(string memory _name, 
                string memory _symbol, 
                string memory _tokenBaseURIConstruct, 
                string memory _contractURIConstruct, 
                address _companyAddressConstruct)
        ERC721A(_name, _symbol)
    {
        _tokenBaseURI = _tokenBaseURIConstruct;
        _contractURI = _contractURIConstruct;
        _companyAddress = _companyAddressConstruct;
    }

    // TODO: Test withdraw
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function isPresaler(address addr) external view returns (bool) {
        return presaleList[addr];
    }

    function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    // TODO: Tests
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        druidPublicPrice = newPrice;
    }

    function setPresalePrice(uint256 newPrice) public onlyOwner {
        druidPresalePrice = newPrice;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function updatePresaleList(
        address[] calldata entries, bool _val
    ) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Null Address");
            presaleList[entry] = _val;
        }
    }

    function updateFreeList(
        address[] calldata entries, bool _val
    ) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Null Address");
            freeList[entry] = _val;
        }
    }

    // How many do I have available to mint before or after minting some at presale?
    function getPresaleAvailable(address entry) public view returns (uint256) {
        if (presaleList[entry]) {
            return DRUID_PRESALE_MAX - presaleListPurchased[entry];
        } else {
            return 0;
        }    }

    // How many do I have available to mint before or after minting some at public sale?
    function getPublicAvailable(address entry) public view returns (uint256) {
        return DRUID_PUBLIC_MAX - publicListPurchased[entry];
    }

    // How many free NFTs can I mint?
    function getFreeMintAvailable(address entry) public view returns (uint256) {
        if (freeList[entry]) {
            return DRUID_FREEMINT_MAX - freeListPurchased[entry];
        } else {
            return 0;
        }
    }
 
    function freeBuy(uint256 tokenQuantity) external payable callerIsUser {
        require(saleLive || presaleLive, "SALE_CLOSED"); // Can free mint on sale or presale
        require(freeList[msg.sender], "NOT_ON_WL"); // Wallet is not on sender list
        require(totalSupply() < DRUID_MAX, "OUT_OF_DRUIDS"); // All druids have already been purchased
        require(totalSupply() + tokenQuantity <= DRUID_MAX, "EXCEED_TOTAL_DRUIDS"); // Amount requested to mint will exceed total druids
        require(freeListPurchased[msg.sender] + tokenQuantity <= DRUID_FREEMINT_MAX, "EXCEED_ALLOCATION"); // Too many druids requested to mint
        
        freeAmountMinted = freeAmountMinted + tokenQuantity;
        freeListPurchased[msg.sender] += tokenQuantity;
        _safeMint(msg.sender, tokenQuantity);
    }

    function presaleBuy(uint256 tokenQuantity) external payable callerIsUser {
        require(!saleLive && presaleLive, "PRESALE_CLOSED"); // Only mint on presale
        require(presaleList[msg.sender], "NOT_ON_WL");  // Wallet is not on sender list
        require(totalSupply() < DRUID_MAX, "OUT_OF_DRUIDS"); // All druids have already been purchased
        require(totalSupply() + tokenQuantity <= DRUID_MAX, "EXCEED_TOTAL_DRUIDS"); // Amount requested to mint will exceed total druids
        require(presaleListPurchased[msg.sender] + tokenQuantity <= DRUID_PRESALE_MAX, "EXCEED_ALLOCATION"); // Too many druids requested to mint
        require(druidPresalePrice * tokenQuantity <= msg.value, "INSUFFICIENT_ETH"); // Not enough ETH for transaction

        presaleAmountMinted = presaleAmountMinted + tokenQuantity;
        presaleListPurchased[msg.sender] += tokenQuantity;
        _safeMint(msg.sender, tokenQuantity);
    }


    function buy(uint256 tokenQuantity) external payable callerIsUser {
        require(saleLive, "SALE_CLOSED");
        require(!presaleLive, "ONLY_PRESALE");
        require(totalSupply() < DRUID_MAX, "OUT_OF_DRUIDS"); // All druids have already been purchased
        require(totalSupply() + tokenQuantity <= DRUID_MAX, "EXCEED_TOTAL_DRUIDS"); // Amount requested to mint will exceed total druids
        require(publicListPurchased[msg.sender] + tokenQuantity <= DRUID_PUBLIC_MAX, "EXCEED_ALLOCATION"); // Too many druids requested to mint
        require(druidPublicPrice * tokenQuantity <= msg.value, "INSUFFICIENT_ETH"); // Not enough ETH for transaction

        publicAmountMinted = publicAmountMinted + tokenQuantity;
        publicListPurchased[msg.sender] += tokenQuantity;
        _safeMint(msg.sender, tokenQuantity);
    }

    function airdrop(address[] calldata wallets) external onlyOwner {
        require(totalSupply() + wallets.length <= DRUID_MAX, "EXCEED_TOTAL_DRUIDS");
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            require(wallet != address(0), "NULL_ADDRESS");
            airdropAmountMinted++;
            _safeMint(wallet, 1);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        if (revealed) {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        }
        else{
            return
                bytes(currentBaseURI).length > 0
                    ? string(abi.encodePacked(currentBaseURI, "metadata.json"
                        )
                    )
                    : "";
        }

    }
}
