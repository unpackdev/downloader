//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IDropspaceSale.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./IDropspaceSaleFactory.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";


contract DropspaceSale is IDropspaceSale, ERC721A, ERC2981, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 MAX = 2**256 - 1;

    uint256 public override mintLimit;
    uint256 public override mintPrice;
    uint256 public override supplyLimit;

    string public override baseURI;

    bool public override smartContractAllowance = false;
    bool public override whitelistBuyOnce = false;

    address payable public override withdrawalWallet;
    address payable public override devWallet;
    address public override ticketAddress;
    address payable public override factory;

    uint256 public presaleTime = MAX;
    uint256 public whitelistSaleTime = MAX;
    uint256 public saleTime = MAX;

    uint256 devSaleShare;
    uint256 ownerSaleShare;

    mapping(uint256 => bool) public override usedTickets;
    bytes32 public override whitelistRoot;
    mapping(address => bool) public override whitelistClaimed;

    constructor(
        uint256 _supplyLimit, 
        uint256 _mintLimit,
        uint256 _mintPrice,
        uint256 _devSaleShare,
        address payable _withdrawalWallet,
        address payable _devWallet,
        address _ticketAddress,
        string memory _name,
        string memory _ticker,
        string memory _baseURI
    ) ERC721A(_name, _ticker) {
        supplyLimit = _supplyLimit;
        mintLimit = _mintLimit;
        mintPrice = _mintPrice;
        withdrawalWallet = _withdrawalWallet;
        devWallet = _devWallet;
        ticketAddress = _ticketAddress;
        baseURI = _baseURI;
        devSaleShare = _devSaleShare;
        ownerSaleShare = uint256(10000).sub(devSaleShare);
        factory = payable(_msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyFactory() {
        require(address(factory) == msg.sender, 
            "DropspaceSale: caller is not the factory");
        _;
    }

    modifier onlyFactoryOrOwner() {
        require(address(factory) == msg.sender || owner() == msg.sender, 
            "DropspaceSale: caller is not the factory");
        _;   
    }

    function setWhitelistBuyOnce(bool _whitelistBuyOnce) external onlyOwner override {
        whitelistBuyOnce = _whitelistBuyOnce;
        emit WhitelistBuyOnceChanged(whitelistBuyOnce);
    }

    function setRoyalties(address _reciever, uint96 _feeNumerator) external onlyOwner override {
        _setDefaultRoyalty(_reciever, _feeNumerator);
    }
    
    function changeSupplyLimit(uint256 _supplyLimit) external onlyOwner override {
        require(supplyLimit >= totalSupply(), "DropspaceSale::changeSupplyLimit: Supply Limit can't be reduced below total supply");
        supplyLimit = _supplyLimit;
        emit SupplyLimitChanged(_supplyLimit);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner override {
        mintPrice = _mintPrice;
        emit MintPriceChanged(_mintPrice);
    }

    function setWhitelistClaimStatus(address _user, bool _status) public onlyOwner override {
        _setWhitelistClaimStatus(_user, _status);
    }

    function _setWhitelistClaimStatus(address _user, bool _status) internal {
        whitelistClaimed[_user] = _status;
        emit WhitelistClaimStatusChanged(_user, _status);
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner override {
        whitelistRoot = _whitelistRoot;
        emit WhitelistRootChanged(whitelistRoot);   
    }

    function setDevSaleShare(uint256 _devSaleShare) external override onlyFactory {
        devSaleShare = _devSaleShare;
        ownerSaleShare = uint256(10000).sub(devSaleShare);
        emit DevShareSaleChanged(devSaleShare);
    }

    function setPresaleTime(uint256 _presaleTime) public override onlyOwner {
        presaleTime = _presaleTime;
        emit PresaleTimeChanged(presaleTime);
    }
    
    function setWhitelistSaleTime(uint256 _whitelistSaleTime) public override onlyOwner {
        whitelistSaleTime = _whitelistSaleTime;
        emit WhitelistSaleTimeChanged(whitelistSaleTime);
    }

    function setSaleTime(uint256 _saleTime) public override onlyOwner {
        saleTime = _saleTime;
        emit SaleTimeChanged(saleTime);
    }

    function presaleActive() public view override returns (bool) {
        return block.timestamp >= presaleTime;
    }

    function whitelistSaleActive() public view override returns (bool) {
        return block.timestamp >= whitelistSaleTime;
    }

    function saleActive() public view override returns (bool) {
        return block.timestamp >= saleTime;
    }
    
    function toggleSaleActive() external onlyOwner override {
        if (block.timestamp >= saleTime) {
            setSaleTime(MAX);
        } else {
            setSaleTime(0);
        }
    }

    function toggleWhitelistSaleActive() external onlyOwner override {
        if (block.timestamp >= whitelistSaleTime) {
            setWhitelistSaleTime(MAX);
        } else {
            setWhitelistSaleTime(0);
        }
    }

    function togglePresaleActive() external onlyOwner override {
        if (block.timestamp >= presaleTime) {
            setPresaleTime(MAX);
        } else {
            setPresaleTime(0);
        }
    }
    
    function setBaseURI(string memory _baseURI) external onlyOwner override {
        baseURI = _baseURI;
        emit BaseURIChanged(baseURI);
    }

    function setSmartContractAllowance(bool _smartContractAllowance) external onlyOwner override {
        smartContractAllowance = _smartContractAllowance;
        emit SmartContractAllowanceChanged(smartContractAllowance);
    }

    function setWithdrawalWallet(address payable _withdrawalWallet) external onlyOwner override {
        withdrawalWallet = _withdrawalWallet;
        emit WithdrawalWalletChanged(withdrawalWallet);
    }

    function setDevWallet(address payable _devWallet) external onlyFactory override {
        devWallet = _devWallet;
        emit DevWalletChanged(devWallet);
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner override {
        mintLimit = _mintLimit;
        emit MintLimitChanged(mintLimit);
    }

    function withdraw() external onlyFactoryOrOwner override  {
        _withdraw();
    }

    function _withdraw() internal {
        uint256 contractBalance = address(this).balance;
        devWallet.transfer(contractBalance.mul(devSaleShare).div(10000));
        withdrawalWallet.transfer(contractBalance.mul(ownerSaleShare).div(10000));
    }

    function reserve(uint256 _amount) external onlyOwner override {
        _mint(_amount);
        emit Reserve(_amount);
    }

    function buy(uint256 _amount) external override payable {
        require(saleActive(), "Dropspace::buy: Sale is not active.");
        require(_amount <= mintLimit, "Dropspace::buy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::buy: Insufficient payment.");

        if (!smartContractAllowance) {
            require(tx.origin == _msgSender(), "Dropspace::buy: Smart contracts are not allowed to buy.");
        }

        _mint(_amount);
        emit Buy(_msgSender(), _amount);

        if (IDropspaceSaleFactory(factory).autoWithdraw()) {
            _withdraw();
        }
    }

    function _mint(uint256 _amount) internal {
        require(totalSupply().add(_amount) <= supplyLimit, "Not enough tokens left.");
        
        _safeMint(_msgSender(), _amount);
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? 
            string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    function setTicketAddress(address _ticketAddress) external onlyFactory override {
        require(_ticketAddress != address(0), "DropSpaceSale::setTicketAddress: Invalid address.");
        ticketAddress = _ticketAddress;
        emit TicketAddressChanged(_ticketAddress);
    }

    function presaleBuy(uint256 _ticketId, uint _amount) external payable override {
        require(presaleActive(), "Dropspace::presaleBuy: Presale is not Active.");
        require(IERC721(ticketAddress).ownerOf(_ticketId) == _msgSender(), "Dropspace::presaleBuy: invalid ticket.");
        require(!usedTickets[_ticketId], "Dropspace::presaleBuy: Ticket already used.");
        require(_amount <= mintLimit, "Dropspace::presaleBuy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::presaleBuy: Insufficient payment.");

        usedTickets[_ticketId] = true;
        _mint(_amount);
        emit PresaleBuy(_msgSender(), _ticketId, _amount);
        
        if (IDropspaceSaleFactory(factory).autoWithdraw()) {
            _withdraw();
        }
    }

    function _verifyWhitelist(address _user, bytes32[] calldata _merkleProof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
    }

    function whitelistBuy(uint256 _amount, bytes32[] calldata _merkleProof) external payable override {
        require(whitelistSaleActive(), "DropSpaceSale::whitelistBuy: Whitelist Buy is not Active.");
        require(_amount <= mintLimit, "Dropspace::presaleBuy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::presaleBuy: Insufficient payment.");
        require(_verifyWhitelist(_msgSender(), _merkleProof), "Dropspace::whitelistBuy: User is not whitelisted");

        if (whitelistBuyOnce) {
            require(!whitelistClaimed[_msgSender()], "Dropspace::whitelistBuy: Already claimed");
            _setWhitelistClaimStatus(_msgSender(), true);
        }

        _mint(_amount);

        emit WhitelistBuy(_msgSender(), _amount);
        
        if (IDropspaceSaleFactory(factory).autoWithdraw()) {
            _withdraw();
        }
    }

    function clearTicket(uint256 _ticketId) external override onlyOwner{
        require(usedTickets[_ticketId], "Dropspace::clearTicket: Ticket is not used");
        usedTickets[_ticketId] = false;
        emit TicketCleared(_ticketId);
    }

    receive() external override payable {}
}