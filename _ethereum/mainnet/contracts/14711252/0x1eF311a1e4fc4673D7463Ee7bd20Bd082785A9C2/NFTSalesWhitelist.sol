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

contract NFTSalesWhitelist is Ownable, ERC721Min, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    address public immutable proxyRegistryAddress; // opensea proxy
    mapping(address => bool) proxyToApproved; // proxy allowance for interaction with future contract
    string private _contractURI;
    string private _tokenBaseURI = ""; // SET TO THE METADATA URI
    address public treasuryAddress; 
    bool public useBaseUriOnly = true;
    mapping(uint256 => string) public TokenURIMap; // allows for assigning individual/unique metada per token

    uint16 public maxPerAddress;
    uint16 public maxPerMint;
    uint16 maxPerAddressForFive;
    uint16 maxMint;
    uint16 public maxMintForOne;
    uint16 maxMintForFive;
    bool public saleActive;
    uint256 public price;
    uint256 priceForFive;

    struct FeeRecipient {
        address recipient;
        uint256 basisPoints;
    }

    mapping(uint256 => FeeRecipient) public FeeRecipients;
    uint256 feeRecipientCount;
    uint256 totalFeeBasisPoints;
    bool public transferDisabled;
    enum SalesState {
        WHITELIST,
        BRIGHTLIST,
        PUBLIC
    }
    SalesState public currentSalesState = SalesState.WHITELIST;
    
    // whitelist
    mapping(address => bool) public Whitelist;
    mapping(address => uint256) public WhitelistMints;
    uint256 public whitelistMax = 3;
    // brightlist
    mapping(address => bool) public Brightlist;
    mapping(address => uint256) public BrightlistMints;
    uint256 public brightlistMax = 3;
    uint256 public brightlistPrice;
    uint256 brightlistPriceForFive;

    constructor(string memory name_, string memory symbol_, address treasury_) ERC721Min(name_, symbol_) {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        treasuryAddress = treasury_;
    }

    function totalSupply() external view returns(uint256) {
        return _owners.length;
    }

    // ** - CORE - ** //

    function buyOne() external payable {
        require(saleActive, "SALE_CLOSED");
        if (currentSalesState == SalesState.PUBLIC || currentSalesState == SalesState.WHITELIST) {
            require(msg.value == price, "INCORRECT_ETH");
        }
        if (currentSalesState == SalesState.WHITELIST) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(WhitelistMints[_msgSender()] < whitelistMax, "MAX_WL_MINTED");
            WhitelistMints[_msgSender()]++;
        } else if (currentSalesState == SalesState.BRIGHTLIST) {
            require(Brightlist[_msgSender()], "NOT_ON_BRIGHTLIST");
            require(BrightlistMints[_msgSender()] < brightlistMax, "MAX_BL_MINTED");
            require(msg.value == brightlistPrice, "INCORRECT_ETH");
            BrightlistMints[_msgSender()]++;
        }
        require(maxMintForOne > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(maxPerAddress == 0 || balanceOf(_msgSender()) < maxPerAddress, "EXCEED_MAX_PER_USER");
        _mintMin();
        emit BuyOne(_msgSender(), msg.value);
    }     

    function buyFive() external payable {
        require(saleActive, "SALE_CLOSED");
        require(maxMintForOne > 4, "MAXMINT<5");
        if (currentSalesState == SalesState.PUBLIC || currentSalesState == SalesState.WHITELIST) {
            require(msg.value == priceForFive, "INCORRECT_ETH");
        }
        if (currentSalesState == SalesState.WHITELIST) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(WhitelistMints[_msgSender()] + 4 < whitelistMax, "MAX_WL_MINTED");
            WhitelistMints[_msgSender()] += 5;
        } else if (currentSalesState == SalesState.BRIGHTLIST) {
            require(Brightlist[_msgSender()], "NOT_ON_BRIGHTLIST");
            require(BrightlistMints[_msgSender()] + 4 < brightlistMax, "MAX_BL_MINTED");
            require(msg.value == brightlistPriceForFive, "INCORRECT_ETH");
            BrightlistMints[_msgSender()] += 5;
        }
        require(maxMintForFive > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(maxPerAddress == 0 || balanceOf(_msgSender()) < maxPerAddressForFive, "EXCEED_MAX_PER_USER");
        _mintMin();
        _mintMin();
        _mintMin();
        _mintMin();
        _mintMin();
        emit BuyFive(_msgSender(), msg.value);
    }

    function buy(uint8 amount) external payable {
        require(saleActive, "SALE_CLOSED");
        if (currentSalesState == SalesState.PUBLIC || currentSalesState == SalesState.WHITELIST) {
            require(msg.value == price * amount, "INCORRECT_ETH");
        }
        if (currentSalesState == SalesState.WHITELIST) {
            require(Whitelist[_msgSender()], "NOT_ON_WHITELIST");
            require(WhitelistMints[_msgSender()] + amount - 1 < whitelistMax, "MAX_WL_MINTED");
            WhitelistMints[_msgSender()] += amount;
        } else if (currentSalesState == SalesState.BRIGHTLIST) {
            require(Brightlist[_msgSender()], "NOT_ON_BRIGHTLIST");
            require(BrightlistMints[_msgSender()] + amount -1 < brightlistMax, "MAX_BL_MINTED");
            require(msg.value == brightlistPrice * amount, "INCORRECT_ETH");
            BrightlistMints[_msgSender()] += amount;
        }
        require(maxMint > _owners.length + amount, "EXCEED_MAX_SALE_SUPPLY");
        require(maxPerAddress == 0 || balanceOf(_msgSender()) + amount - 1 < maxPerAddress, "EXCEED_MAX_PER_USER");
        for (uint256 i = 0; i < amount; i++) {
            _mintMin();
        }
        emit Buy(_msgSender(), amount, msg.value);
    }

    // ** - PROXY - ** //

    function mintOne(address receiver) external onlyProxy {
        require(maxMintForOne > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(maxPerAddress == 0 || balanceOf(receiver) < maxPerAddress, "EXCEED_MAX_PER_USER");
        _mintMin2(receiver);
        emit MintOne(_msgSender(), receiver);
    }

    function mintFive(address receiver) external onlyProxy {
        require(maxMintForOne > 4, "MAXMINT<5");
        require(maxMintForFive > _owners.length, "EXCEED_MAX_SALE_SUPPLY");
        require(maxPerAddress == 0 || balanceOf(receiver) < maxPerAddressForFive, "EXCEED_MAX_PER_USER");
        _mintMin2(receiver);
        _mintMin2(receiver);
        _mintMin2(receiver);
        _mintMin2(receiver);
        _mintMin2(receiver);
        emit MintFive(_msgSender(), receiver);
    }   

    function mint(address receiver, uint16 amount) external onlyProxy {
        require(maxMint > _owners.length + amount, "EXCEED_MAX_SALE_SUPPLY");
        require(amount < maxPerMint, "EXCEED_MAX_PER_MINT");
        require(maxPerAddress == 0 || balanceOf(receiver) + amount - 1 < maxPerAddress, "EXCEED_MAX_PER_USER");
        for (uint256 i = 0; i < amount; i++) {
            _mintMin2(receiver);
        }
        emit Mint(_msgSender(), receiver, amount);
    }    

    // ** - ADMIN - ** //

    function setSalesState(uint256 state) external onlyOwner {
        currentSalesState = SalesState(state);
    }

    /**** WHITELIST ****/

    function whitelistAdd(address[] calldata addresses) external onlyOwner {
        for(uint256 x; x < addresses.length; x++) {
            Whitelist[addresses[x]] = true;
        }
        emit WhitelistAdd(_msgSender(), addresses);
    }

    function whitelistRemove(address[] calldata addresses) external onlyOwner {
        for(uint256 x; x < addresses.length; x++) {
            Whitelist[addresses[x]] = false;
        }
        emit WhitelistRemove(_msgSender(), addresses);
    }
    
    function setWhitelistMax(uint256 value) external onlyOwner {
        require(value > 0, "AMOUNT=0");
        whitelistMax = value;
    }

    /**** BRIGHTLIST ****/

    function brightlistAdd(address[] calldata addresses) external onlyOwner {
        for(uint256 x; x < addresses.length; x++) {
            Brightlist[addresses[x]] = true;
        }
        emit BrightlistAdd(_msgSender(), addresses);
    }

    function brightlistRemove(address[] calldata addresses) external onlyOwner {
        for(uint256 x; x < addresses.length; x++) {
            Brightlist[addresses[x]] = false;
        }
        emit BrightlistRemove(_msgSender(), addresses);
    }
    
    function setBrightlistMax(uint256 value) external onlyOwner {
        require(value > 0, "AMOUNT=0");
        brightlistMax = value;
    }

    function setBrightlistPrice(uint256 value) external onlyOwner {
        brightlistPrice = value;
        brightlistPriceForFive = value * 5;
    }       

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

    function distributeETH() external nonReentrant onlyOwner {
        require(feeRecipientCount > 0, "RECIPIENTS_NOT_SET");
        uint256 bal = address(this).balance;
        for(uint256 x = 1; x <= feeRecipientCount; x++) {
            uint256 amount = bal * FeeRecipients[x].basisPoints / totalFeeBasisPoints;
            amount = amount > address(this).balance ? address(this).balance : amount;
            (bool sent, ) = FeeRecipients[x].recipient.call{value: amount}("");
            require(sent, "FAILED_SENDING_FUNDS");
        }
        emit DistributeETH(_msgSender(), bal);
    }

    function withdrawETH() external nonReentrant onlyOwner {
        require(_msgSender() == owner() || _msgSender() == treasuryAddress || proxyToApproved[_msgSender()], "NOT_ALLOWED");
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        (bool sent, ) = treasuryAddress.call{value: bal}("");
        require(sent, "FAILED_SENDING_FUNDS");
        emit WithdrawETH(_msgSender(), bal);
    }

    function withdrawTokens(address _token) external nonReentrant onlyOwner {
        require(_msgSender() == owner() || _msgSender() == treasuryAddress || proxyToApproved[_msgSender()], "NOT_ALLOWED");
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        IERC20(_token).safeTransfer(
            treasuryAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function gift(address[] calldata receivers, uint256[] memory amounts) external onlyOwner {
        for (uint256 x = 0; x < receivers.length; x++) {
            for (uint256 i = 0; i < amounts[x]; i++) {
                _mintMin2(receivers[x]);
            }
        }
    }

    function updateConfig(uint16 _maxMint, uint16 _maxPerMint, uint256 _price, 
        uint16 _maxPerAddress, bool _saleActive, string calldata _uri) external onlyOwner
    {
        maxMint = _maxMint+1;
        maxMintForOne = _maxMint;
        maxMintForFive = _maxMint > 4 ? _maxMint - 4 : 0;
        maxPerMint = _maxPerMint + 1;
        price = _price;
        priceForFive = _price * 5;
        maxPerAddress = _maxPerAddress > 0 ? _maxPerAddress : 0;
        maxPerAddressForFive = _maxPerAddress > 1 ? _maxPerAddress - 4 : 0;
        saleActive = _saleActive;
        _tokenBaseURI = _uri;
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }    

    function setMaxPerMint(uint16 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setMaxMint(uint16 maxMint_) external onlyOwner {
        maxMint = maxMint_ + 1;
        maxMintForOne = maxMint_;
        maxMintForFive = maxMint_ > 4 ? maxMint_ - 4 : 0;
    }

    function setMaxPerAddress(uint16 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress > 0 ? _maxPerAddress : 0;
        maxPerAddressForFive = _maxPerAddress > 1 ? _maxPerAddress - 4 : maxPerAddress;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        priceForFive = _price * 5;
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

    function isProxyToApproved(address proxyAddress) external view onlyOwner returns(bool) {
        return proxyToApproved[proxyAddress];
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
        if (useBaseUriOnly) return _tokenBaseURI;
        return bytes(_tokenBaseURI).length > 0
                ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString()))
                : "";
    }

    function setTokenUri(uint256 tokenId, string calldata _uri) external onlyOwner {
        TokenURIMap[tokenId] = _uri;
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool) {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }
        return true;
    }

    function setTransferDisabled(bool _transferDisabled) external onlyOwner {
        transferDisabled = _transferDisabled;
    }

    function setStakingContract(address stakingContract) external onlyOwner {
        _setStakingContract(stakingContract);
    }

    function unStake(uint256 tokenId) external onlyOwner {
        _unstake(tokenId);
    } 

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public override {
        require(!transferDisabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.batchSafeTransferFrom(_from, _to, _tokenIds, data_);
    }   

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public override {
        require(!transferDisabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.batchTransferFrom(_from, _to, _tokenIds);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(!transferDisabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!transferDisabled || _msgSender() == owner() || proxyToApproved[_msgSender()], "TRANSFER_DISABLED");
        super.transferFrom(from, to, tokenId);
    }    

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()] == true, "onlyProxy");
        _;
    }    

    event DistributeETH(address indexed sender, uint256 indexed balance);
    event DistributeTokens(address indexed sender, uint256 indexed balance);
    event WithdrawETH(address indexed sender, uint256 indexed balance);
    event BuyOne(address indexed user, uint256 indexed eth);
    event BuyFive(address indexed user, uint256 indexed eth);
    event Buy(address indexed user, uint256 indexed amount, uint256 indexed eth);
    event MintOne(address indexed user, address indexed receiver);
    event MintFive(address indexed user, address indexed receiver);
    event Mint(address indexed user, address indexed receiver, uint256 indexed amount);
    event WhitelistAdd(address indexed user, address[] indexed addresses);
    event WhitelistRemove(address indexed user, address[] indexed addresses);
    event BrightlistAdd(address indexed user, address[] indexed addresses);
    event BrightlistRemove(address indexed user, address[] indexed addresses);
}
