// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721PresetMinterPauserAutoId.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract NFTYninjasV1 is ERC721PresetMinterPauserAutoId, ERC721URIStorage, ReentrancyGuard, Ownable, PaymentSplitter {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct PresaleWindow {
        uint256 startTime;
        uint256 saleWindow;
    }

    struct SaleWindow {
        uint256 startTime;
    }

    uint256 public constant maxTokens = 9333;
    uint256 public totalTokenCounter;
    uint256 public maxPresaleTokens = 500;
    uint256 public presaleTokenCounter;
    uint256 public presaleTokenPrice;
    uint256 public presaleTokenLimit = 2;
    uint256 public maxPromoTokens = 167;
    uint256 public promoTokenCounter;
    uint256 public bulkPurchaseLimit = 10;
    uint256 public unitTokenPrice;
    string public baseURI;
    string public notRevealedURI;
    string public baseExtension = ".json";
    bool public revealed = false;
    bool public burnStatus = false;
    
    PresaleWindow public presaleWindow;
    SaleWindow public saleWindow;

    mapping(address => bool) private _presaleAddressList;
    mapping(address => uint256) public _presaleRedeemed;
    mapping(address => uint256) public _saleRedeemed;
    mapping(address => uint256) public _totalRedeemed;

    uint256[] private _teamBreakdown = [9000, 400, 400, 200];
    address[] private _team = [
        0x32721619293a48A7f7Ee276C68F89E4fc43CA2B5,
        0x242A97e0Da438735Fba475A6466B649f773585E1,
        0xDD97cB40A8c7194E74881F6453E82b764E5e8756,
        0x98e5942d4fC4fE129325e255F912a19cF424DAe1
    ];

    enum ContractState {
        BeforePresale,
        Presale,
        Sale,
        SoldOut
    }

    ContractState public contractState;

    event unitTokenPriceChanged(uint256 newUnitTokenPrice);
    event presaleTokenPriceChanged(uint256 newPresaleTokenPrice);
    event tokenMinted(address indexed sender, uint256 indexed tokenId);
    event presaleTokenMinted(address indexed _minter, uint256 _amount, uint256 _price);
    event ChangeBaseURI(string _newBaseURI);
    event ChangeBurnStatus(bool _newBurnStatus);
    event ContractStateChanged(ContractState lastState, ContractState newState);
    event PresaleWindowChanged(uint256 startTime, uint256 saleWindow);
    event SaleWindowChanged(uint256 startTime);

    constructor() 
    ERC721PresetMinterPauserAutoId("NFTYninjasV1", "NFTYNV1", "")
    PaymentSplitter(_team, _teamBreakdown)
    ReentrancyGuard() 
    {

        promoTokenCounter = 0;
        presaleTokenCounter = 0;
        totalTokenCounter = 0;
        presaleTokenPrice = 0.07 ether;
        unitTokenPrice = 0.1 ether;
    }

    function setBaseURI(string calldata _newBaseURI) public virtual onlyOwner {
        baseURI = _newBaseURI;
        emit ChangeBaseURI(_newBaseURI);
    }

    function _baseURI() internal view virtual override (ERC721, ERC721PresetMinterPauserAutoId) returns (string memory) {
        return baseURI;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setNewBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function getContractState() public view returns (uint256) {
        uint256 _state;
        if (contractState == ContractState.BeforePresale) {
            _state = 1;
        }
        if (contractState == ContractState.Presale) {
            _state = 2;
        }
        if (contractState == ContractState.Sale) {
            _state = 3;
        }
        if (contractState == ContractState.SoldOut) {
            _state = 4;
        }
        return _state;
    }

    function addAddressToPresaleList (address[] calldata _addresses) external onlyOwner {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(_addresses[ind] != address(0), "Address is a zero address.");
            if (_presaleAddressList[_addresses[ind]] == false) {
                _presaleAddressList[_addresses[ind]] = true;
            }
        }
    }

    function removeAddressFromPresaleList(address[] calldata _addresses) external onlyOwner {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(_addresses[ind] != address(0), "Address is a zero address.");
            if (_presaleAddressList[_addresses[ind]] == true) {
                _presaleAddressList[_addresses[ind]] = false;
            }
        }
    }

    function addressIsOnPresaleList(address _address) external view returns (bool) {
        return _presaleAddressList[_address];
    }

    function initiatePresaleWindow(uint256 _saleWindow) external onlyOwner {
        uint256 _startTime = block.timestamp;
        presaleWindow = PresaleWindow(_startTime, _saleWindow);
        contractState = ContractState.Presale;
        emit PresaleWindowChanged(_startTime, _saleWindow);
        emit ContractStateChanged(ContractState.BeforePresale, ContractState.Presale);
    }

    function setBulkPurchaseLimit(uint256 newBulkPurchaseLimit) public onlyOwner {
        bulkPurchaseLimit = newBulkPurchaseLimit;
    }

    function setBurnStatus (bool _newBurnStatus) external onlyOwner {
        burnStatus = _newBurnStatus;
        emit ChangeBurnStatus(_newBurnStatus);
    }

    function setUnitTokenPrice(uint256 newUnitTokenPrice) public onlyOwner {
        unitTokenPrice = newUnitTokenPrice;
        emit unitTokenPriceChanged(newUnitTokenPrice);
    }

    function setPresaleTokenLimit(uint256 newPresaleTokenLimit) public onlyOwner {
        presaleTokenLimit = newPresaleTokenLimit;
    }

    function setPresaleTokenPrice(uint256 newPresaleTokenPrice) public onlyOwner {
        presaleTokenPrice = newPresaleTokenPrice;
        emit presaleTokenPriceChanged(newPresaleTokenPrice);
    }

    function initiateSaleWindow() external onlyOwner {
        require(contractState == ContractState.Presale, "Contract state is not Presale which is required.");
        PresaleWindow memory _presaleWindow = presaleWindow;
        uint256 _presaleWindowEndTime = _presaleWindow.startTime + _presaleWindow.saleWindow;
        require(block.timestamp > _presaleWindowEndTime, "Presale has not yet ended.");
        uint256 _startTime = block.timestamp;
        saleWindow = SaleWindow(_startTime);
        contractState = ContractState.Sale;
        emit SaleWindowChanged(_startTime);
        emit ContractStateChanged(ContractState.Presale, ContractState.Sale);
    }

    function mintForPromo(uint256 _amount, address _to) external onlyOwner {
        require(_amount > 0, "Cannot promo mint less than 1.");
        require(promoTokenCounter + _amount <= maxPromoTokens, "No more available promo tokens.");
        require(totalTokenCounter + _amount <= maxTokens, "Max tokens minted.");
        require(_to != address(0), "Address is a zero address.");

        uint256 _newTokenId;
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIdCounter.increment();
            _newTokenId = _tokenIdCounter.current();
            _safeMint(_to, _newTokenId);
            totalTokenCounter = totalTokenCounter + 1;

            emit tokenMinted(_to, _newTokenId);
        }

        promoTokenCounter += _amount;
        _totalRedeemed[_to] = _totalRedeemed[_to] + _amount;
    }

    function presaleMint(uint256 _amount) external payable nonReentrant {
        PresaleWindow memory _presaleWindow = presaleWindow;
        require(_presaleAddressList[msg.sender] == true, "Caller is not on the presale address list.");
        require(_amount <= presaleTokenLimit, "Cannot presale mint that many tokens.");
        require(_presaleRedeemed[msg.sender] + _amount <= presaleTokenLimit, "Caller has exhausted their presale token supply.");
        require(_presaleWindow.startTime > 0, "Presale has not started yet.");
        require(block.timestamp >= _presaleWindow.startTime, "Presale has not started yet.");
        require(block.timestamp <= _presaleWindow.startTime + _presaleWindow.saleWindow, "Presale has ended.");
        require(presaleTokenCounter + _amount <= maxPresaleTokens, "Presale token supply has been exhausted.");
        require(totalTokenCounter + _amount <= maxTokens, "Total token supply has been exhausted.");
        require(presaleTokenPrice * _amount <= msg.value, "Ether value sent is not correct.");
        require(paused() == false, "Contract is paused.");

        uint256 _newTokenId;
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIdCounter.increment();
            _newTokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, _newTokenId);
            _presaleRedeemed[msg.sender] = _presaleRedeemed[msg.sender] + 1;
            _totalRedeemed[msg.sender] = _totalRedeemed[msg.sender] + 1;
            presaleTokenCounter = presaleTokenCounter + 1;
            totalTokenCounter = totalTokenCounter + 1;

            emit tokenMinted(msg.sender, _newTokenId);
        }

        emit presaleTokenMinted(msg.sender, _amount, presaleTokenPrice);
    }

    function publicMint(uint256 amount) external payable nonReentrant {
        SaleWindow memory _saleWindow = saleWindow;
        require(totalTokenCounter + amount <= maxTokens, "Total token supply has been exhausted.");
        require(_saleWindow.startTime > 0, "Public sale has not started yet.");
        require(block.timestamp >= _saleWindow.startTime, "Public sale has not started yet.");
        require(amount > 0, "Cannot mint less than 1.");
        require(amount <= bulkPurchaseLimit, "Cannot mint more than 10.");
        require(unitTokenPrice * amount <= msg.value, "Ether value sent is not correct.");
        require(paused() == false, "Contract is paused.");

        uint256 _newTokenId;
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            _newTokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, _newTokenId);
            _saleRedeemed[msg.sender] = _saleRedeemed[msg.sender] + 1;
            _totalRedeemed[msg.sender] = _totalRedeemed[msg.sender] + 1;
            totalTokenCounter = totalTokenCounter + 1;

            emit tokenMinted(msg.sender, _newTokenId);
        }

        if (totalTokenCounter + amount == maxTokens) {
            contractState = ContractState.SoldOut;
            emit ContractStateChanged(ContractState.Sale, ContractState.SoldOut);
        }
    }

    function payoutBalance() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function changePresaleMaxTokens(uint256 _newMaxPresaleTokens) public onlyOwner {
        maxPresaleTokens = _newMaxPresaleTokens;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721PresetMinterPauserAutoId)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) public virtual override(ERC721Burnable) {
        require(burnStatus == true, "Burning disabled.");
        super.burn(tokenId);
    } 

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        if (revealed == false) {
            return notRevealedURI;
        }
        string memory activeBaseURI = _baseURI();
        return bytes(activeBaseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension)) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721PresetMinterPauserAutoId)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}
