// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC721Min.sol";

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFTSales is Ownable, ERC721Min, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    address public immutable proxyRegistryAddress; // opensea proxy
    mapping(address => bool) proxyToApproved; // proxy allowance for interaction with future contract
    string private _contractURI;
    string private _tokenBaseURI = ""; // SET TO THE METADATA URI
    address private treasuryAddress = 0x5aD1Cdf35d8c2486787ba121f133FE4C776a0BFB; 
    bool useBaseUriOnly = true;
    mapping(uint256 => string) public TokenURIMap; // allows for assigning individual/unique metada per token

    struct NftType {
        uint16 purchaseCount;
        uint16 maxPerAddress;
        uint16 maxPerMint;
        uint16 maxPerAddressForThree;
        uint16 maxMint;
        uint16 maxMintForOne;
        uint16 maxMintForThree;
        bool saleActive;
        uint256 price;
        uint256 priceForThree;
        mapping(address => uint256) PurchasesByAddress; 
        string uri; 
    }

    struct FeeRecipient {
        address recipient;
        uint256 basisPoints;
    }

    mapping(uint256 => FeeRecipient) public FeeRecipients;
    uint256 feeRecipientCount;
    uint256 totalFeeBasisPoints;

    mapping(uint256 => NftType) public NftTypes;
    uint256 public nftTypeCount;
    bool public transferEnabled;
    mapping(uint256 => uint256) public NftIdToNftType;

    constructor() ERC721Min("ASSASSIN-8 UTILITY NFT", "ASS8U") {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }

    function totalSupply() external view returns(uint256) {
        return _owners.length;
    }

    // ** - CORE - ** //

    function buyOne(uint256 nftTypeId) external payable {
        require(NftTypes[nftTypeId].saleActive, "SALE_CLOSED");
        require(NftTypes[nftTypeId].price == msg.value, "INCORRECT_ETH");
        require(NftTypes[nftTypeId].maxMintForOne > NftTypes[nftTypeId].purchaseCount, "EXCEED_MAX_SALE_SUPPLY");
        require(NftTypes[nftTypeId].maxPerAddress == 0 || 
            NftTypes[nftTypeId].PurchasesByAddress[_msgSender()] < NftTypes[nftTypeId].maxPerAddress, "EXCEED_MAX_PER_USER");
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin();
        if (NftTypes[nftTypeId].maxPerAddress > 0) NftTypes[nftTypeId].PurchasesByAddress[_msgSender()]++;
        NftTypes[nftTypeId].purchaseCount++;
    }     

    function buyThree(uint256 nftTypeId) external payable {
        require(NftTypes[nftTypeId].saleActive, "SALE_CLOSED");
        require(NftTypes[nftTypeId].priceForThree == msg.value, "INCORRECT_ETH");
        require(NftTypes[nftTypeId].maxMintForThree > NftTypes[nftTypeId].purchaseCount, "EXCEED_MAX_SALE_SUPPLY");
        require(NftTypes[nftTypeId].maxPerAddress == 0 || 
            NftTypes[nftTypeId].PurchasesByAddress[_msgSender()] < NftTypes[nftTypeId].maxPerAddressForThree, "EXCEED_MAX_PER_USER");
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin();
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin();
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin();
        if (NftTypes[nftTypeId].maxPerAddress > 0) {
            NftTypes[nftTypeId].PurchasesByAddress[_msgSender()] += 3;
        } 
        NftTypes[nftTypeId].purchaseCount += 3;
    }

    function buy(uint256 nftTypeId, uint16 amount) external payable {
        require(NftTypes[nftTypeId].saleActive, "SALE_CLOSED");
        require(NftTypes[nftTypeId].price * amount == msg.value, "INCORRECT_ETH");
        require(NftTypes[nftTypeId].maxMint > NftTypes[nftTypeId].purchaseCount + amount, "EXCEED_MAX_SALE_SUPPLY");
        require(amount < NftTypes[nftTypeId].maxPerMint, "EXCEED_MAX_PER_MINT");
        require(NftTypes[nftTypeId].maxPerAddress > 0 || 
            NftTypes[nftTypeId].PurchasesByAddress[_msgSender()] + amount - 1 < NftTypes[nftTypeId].maxPerAddress, "EXCEED_MAX_PER_USER");
        for (uint256 i = 0; i < amount; i++) {
            NftIdToNftType[_owners.length] = nftTypeId;
            _mintMin();
        }
        NftTypes[nftTypeId].purchaseCount += amount;
    }

    // ** - PROXY - ** //

    function mintOne(address receiver, uint256 nftTypeId) external onlyProxy {
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin2(receiver);
    }

    function mintThree(address receiver, uint256 nftTypeId) external onlyProxy {
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin2(receiver);
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin2(receiver);
        NftIdToNftType[_owners.length] = nftTypeId;
        _mintMin2(receiver);
    }   

    function mint(address receiver, uint256 nftTypeId, uint256 tokenQuantity) external onlyProxy {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            NftIdToNftType[_owners.length] = nftTypeId;
            _mintMin2(receiver);
        }
    }    

    function getNftTokenIdForUserForNftType(address user, uint nftType) external view returns(uint) {
        uint result;
        uint bal = balanceOf(user);
        for (uint x = 0; x < bal; x++) {
            uint id = tokenOfOwnerByIndex(user, x);
            if (NftIdToNftType[id] == nftType) {
                return id;
            }
        }
        return result;        
    }     

    function userHasNftType(address user, uint nftType) external view returns(bool) {
        uint bal = balanceOf(user);
        for (uint x = 0; x < bal; x++) {
            uint id = tokenOfOwnerByIndex(user, x);
            if (NftIdToNftType[id] == nftType) return true; 
        }
        return false;        
    }    

    // ** - ADMIN - ** //

    function addFeeRecipient(address recipient, uint256 basisPoints) external onlyOwner {
        feeRecipientCount++;
        FeeRecipients[feeRecipientCount].recipient = recipient;
        FeeRecipients[feeRecipientCount].basisPoints = basisPoints;
        totalFeeBasisPoints += basisPoints;
    }

    function editFeeRecipient(uint256 id, address recipient, uint256 basisPoints) external onlyOwner {
        require(id <= feeRecipientCount, "INVALID_ID");
        totalFeeBasisPoints = totalFeeBasisPoints - FeeRecipients[feeRecipientCount].basisPoints + basisPoints;
        FeeRecipients[feeRecipientCount].recipient = recipient;
        FeeRecipients[feeRecipientCount].basisPoints = basisPoints;
    }

    function distributeETH() public {
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        for(uint256 x = 1; x <= feeRecipientCount; x++) {
            uint256 amount = bal * FeeRecipients[x].basisPoints / totalFeeBasisPoints;
            amount = amount > address(this).balance ? address(this).balance : amount;
            (bool sent, ) = FeeRecipients[x].recipient.call{value: amount}("");
            require(sent, "FAILED_SENDING_FUNDS");
        }
        emit DistributeETH(_msgSender(), bal);
    }

    function withdrawETH() public {
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        (bool sent, ) = treasuryAddress.call{value: bal}("");
        require(sent, "FAILED_SENDING_FUNDS");
        emit WithdrawETH(_msgSender(), bal);
    }

    function withdraw(address _token) external nonReentrant {
        require(_msgSender() == owner() || _msgSender() == treasuryAddress, "NOT_ALLOWED");
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        IERC20(_token).safeTransfer(
            treasuryAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function gift(uint256 nftTypeId, address[] calldata receivers, uint256[] memory amounts) external onlyOwner {
        for (uint256 x = 0; x < receivers.length; x++) {
            for (uint256 i = 0; i < amounts[x]; i++) {
                NftIdToNftType[_owners.length] = nftTypeId;
                _mintMin2(receivers[x]);
            }
        }
    }

    // ** - NFT Types - ** //
    function addNftType(uint16 _maxMint, uint16 _maxPerMint, uint256 _price, 
        uint16 _maxPerAddress, bool _saleActive, string calldata _uri) external onlyOwner
    {
        nftTypeCount++;
        NftTypes[nftTypeCount].maxMint = _maxMint+1;
        NftTypes[nftTypeCount].maxMintForOne = _maxMint;
        NftTypes[nftTypeCount].maxMintForThree = _maxMint-2;
        NftTypes[nftTypeCount].maxPerMint = _maxPerMint;
        NftTypes[nftTypeCount].price = _price;
        NftTypes[nftTypeCount].priceForThree = _price * 3;
        NftTypes[nftTypeCount].maxPerAddress = _maxPerAddress > 0 ? _maxPerAddress : NftTypes[nftTypeCount].maxPerAddress;
        NftTypes[nftTypeCount].maxPerAddressForThree = _maxPerAddress > 1 ? _maxPerAddress - 2 : NftTypes[nftTypeCount].maxPerAddress;
        NftTypes[nftTypeCount].saleActive = _saleActive;
        NftTypes[nftTypeCount].uri = _uri;
    }

    function toggleSaleActive(uint256 nftTypeId) external onlyOwner {
        NftTypes[nftTypeId].saleActive = !NftTypes[nftTypeId].saleActive;
    }    

    function setMaxPerMint(uint256 nftTypeId, uint16 maxPerMint) external onlyOwner {
        NftTypes[nftTypeId].maxPerMint = maxPerMint;
    }

    function setMaxMint(uint256 nftTypeId, uint16 maxMint_) external onlyOwner {
        NftTypes[nftTypeId].maxMint = maxMint_ + 1;
        NftTypes[nftTypeId].maxMintForOne = maxMint_;
        NftTypes[nftTypeId].maxMintForThree = maxMint_ - 2;
    }

    function setMaxPerAddress(uint256 nftTypeId, uint16 _maxPerAddress) external onlyOwner {
        NftTypes[nftTypeId].maxPerAddress = _maxPerAddress > 0 ? _maxPerAddress : 0;
        NftTypes[nftTypeId].maxPerAddressForThree = _maxPerAddress > 1 ? _maxPerAddress - 2 : NftTypes[nftTypeCount].maxPerAddress;
    }

    function setPrice(uint256 nftTypeId, uint256 _price) external onlyOwner {
        NftTypes[nftTypeId].price = _price;
        NftTypes[nftTypeId].priceForThree = _price * 3;
    }    

    function setNftTypeUri(uint256 nftTypeId, string calldata uri) external onlyOwner {
        NftTypes[nftTypeId].uri = uri;
    }

    // to avoid opensea listing costs
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            proxyToApproved[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    // ** - SETTERS - ** //

    function setVaultAddress(address addr) external onlyOwner {
        treasuryAddress = addr;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // ** - MISC - ** //

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function toggleUseBaseUri() external onlyOwner {
        useBaseUriOnly = !useBaseUriOnly;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (bytes(TokenURIMap[tokenId]).length > 0) return TokenURIMap[tokenId];        
        if (bytes(NftTypes[NftIdToNftType[tokenId]].uri).length > 0) return NftTypes[NftIdToNftType[tokenId]].uri;
        if (useBaseUriOnly) return _tokenBaseURI;
        return bytes(_tokenBaseURI).length > 0
                ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString()))
                : "";
    }

    function setTokenUri(uint256 tokenId, string calldata uri) external onlyOwner {
        TokenURIMap[tokenId] = uri;
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool) {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }
        return true;
    }

    function setTransferEnabled(bool enabled) external onlyOwner {
        transferEnabled = enabled;
    }

    function setStakingContract(address stakingContract) external onlyOwner {
        _setStakingContract(stakingContract);
    }

    function unStake(uint256 tokenId) external onlyOwner {
        _unstake(tokenId);
    } 

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public override {
        require(transferEnabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.batchSafeTransferFrom(_from, _to, _tokenIds, data_);
    }   

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public override {
        require(transferEnabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.batchTransferFrom(_from, _to, _tokenIds);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(transferEnabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(transferEnabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.transferFrom(from, to, tokenId);
    }    

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()] == true, "onlyProxy");
        _;
    }    

    event DistributeETH(address indexed sender, uint256 indexed balance);
    event WithdrawETH(address indexed sender, uint256 indexed balance);
}
