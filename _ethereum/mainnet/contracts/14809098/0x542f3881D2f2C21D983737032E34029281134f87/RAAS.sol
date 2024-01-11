// SPDX-License-Identifier: MIT LICENSE
// introduction: https://mirror.xyz/0x5301c4ae977126DB7f96F0CBE076606eEE2C2E08/xTp5t1u8W1MQotMNQSeXOcZ1bnEYxrr5_YPTKxcLM94
// Identify RAAS team leader by 55c43f7971252f59a1ad8405b2031350

pragma solidity 0.8.9;

import "./Counters.sol";
import "./ERC721A.sol";

interface contractModal {
    function owner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from,address to, uint256 tokenId) external;
    function transferOwnership(address _newOwner) external;
}

contract RAAS is ERC721A{
    using Counters for Counters.Counter;

    address public owner;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private reentrantStatus = _NOT_ENTERED;
    uint256 private constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    uint256 private constant minBuyPriceGlobalMin = 0.1 ether;
    uint256 private constant minBuyPriceGlobalMax = 1 ether;
    uint256 public currentMinBuyPrice = 0.1 ether;

    uint256 private constant minPlatformFee = 1;
    uint256 private constant maxPlatformFee = 10;
    uint256 public currentPlatformFee = 1;

    uint256 private constant durationUint = 1 days;
    uint256 private constant minDurationDays = 1 * durationUint;
    uint256 private constant maxDurationDays = 30 * durationUint;

    mapping(address => bool) private destroyContractMapping;
    mapping (address => DepositedOwnershipStruct) private depositedOwnershipMapping;
    uint256 public totalDepositsCount = 0;
    mapping (address => SoldRecordStruct) private SoldRecordMapping;
    uint256 public totalSoldCount = 0;

    string public baseTokenURI;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public AdminMinted = 0;
    uint256 private constant AdminMaxReserved = 200;
    uint256 public GiveawaysMinted = 0;
    uint256 private constant GiveawaysMaxReserved = 300;
    uint256 public constant walletMaxMinted = 3;
    mapping(address => uint256) private allowedMintCountMapping;

    enum ExpireOperations{
        TransferToSeller,
        Destroy,
        StayInRaasForever
    }

    struct DepositedOwnershipStruct{
        address callerAddress;
        address receiveETHAddress;
        address targetContract;
        uint256 minBuyPrice;
        uint256 maxBuyPrice;
        uint256 platformFee;
        uint256 durationDays;
        uint256 depositedTime;
        ExpireOperations expireOperation;
    }

    struct SoldRecordStruct{
        address sellerAddress;
        address receiveETHAddress;
        address buyerAddress;
        address targetContract;
        uint256 finalBuyPrice;
        uint256 platformFee;
        uint256 depositedTime;
        uint256 durationDays;
        uint256 soledTime;
        ExpireOperations expireOperation;
    }

    event transferETHLog(address indexed _from, address indexed _to, uint256 amount);
    event depositedOwnershipLog(address indexed seller, address indexed targetContract, uint256 durationDays);
    event buyOwnershipLog(address indexed seller, address indexed buyer, address indexed targetContract, uint256 buyPrice);
    event retrieveOwnershipLog(address indexed seller, address indexed targetContract, uint256 retrieveTime);
    event destroyOwnershipLog(address indexed seller, address indexed targetContract, uint256 destoryTime);

    constructor() ERC721A ("RescueProjectAsAService", "RAAS"){
        owner = msg.sender;
        baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmdtfBhk5WHck3gS7XW115VTh4JvRQMWgt5P6RYnvJAMY2/";
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not raas owner");
        _;
    }

    modifier nonReentrant() {
        require(reentrantStatus != _ENTERED, "forbidden reentrant call");
        reentrantStatus = _ENTERED;
        _;
        reentrantStatus = _NOT_ENTERED;
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead // Reemplazar URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function ownershipInRaas(address _targetContract) public view returns(bool){
        address _targetContractCurrentOwner = contractModal(_targetContract).owner();
        if(_targetContractCurrentOwner == address(this)){
            return true;
        }else{
            return false;
        }
    }

    function isTradeTimeout(DepositedOwnershipStruct memory dos) private view returns(bool){
        if(dos.depositedTime + dos.durationDays * durationUint >= block.timestamp){
            return false;
        }else{
            return true;
        }
    }

    function existsValidOwnershipTrade(address _targetContract) public view returns(bool){
        if(ownershipInRaas(_targetContract)){
            if(isTradeTimeout(depositedOwnershipMapping[_targetContract])){
                return false;
            }else{
                return true;
            }
        }else{
            return false;
        }
    }

    function isOwnershipTradeTimeout(address _targetContract) external view returns(bool){
        if(existsValidOwnershipTrade(_targetContract)){
            return isTradeTimeout(depositedOwnershipMapping[_targetContract]);
        }else{
            return true;
        }
    }

    function getTradeTimeLeft(address _targetContract) external view returns(uint256){
        if(existsValidOwnershipTrade(_targetContract)){
            DepositedOwnershipStruct memory dos = depositedOwnershipMapping[_targetContract];
            if(isTradeTimeout(dos)){
                return 0;
            }else{
                return (dos.depositedTime + dos.durationDays * durationUint) - block.timestamp;
            }
        }else{
            return 0;
        }
    }

    function getCurrentOwnershipPrice(address _targetContract) public view returns(uint256){
        if(existsValidOwnershipTrade(_targetContract)){
            DepositedOwnershipStruct memory dos = depositedOwnershipMapping[_targetContract];
            if(!isTradeTimeout(dos)){
                if(dos.minBuyPrice == dos.maxBuyPrice){
                    return dos.minBuyPrice;
                }else{
                    uint256 reducedPrice = ((block.timestamp - dos.depositedTime) * (dos.maxBuyPrice - dos.minBuyPrice)) / (dos.durationDays * durationUint);
                    return dos.maxBuyPrice - reducedPrice;
                }
            }
        }
        return MAX_INT;
    }

    function getDepositedOwnershipDetails(address _targetContract) external view returns(DepositedOwnershipStruct memory){
        return depositedOwnershipMapping[_targetContract];
    }

    function getSoldRecordDetails(address _targetContract) external view returns(SoldRecordStruct memory){
        return SoldRecordMapping[_targetContract];
    }

    function depositedOwnershipWithFixPrice(address _receiveETHAddress, address _targetContract, uint256 _fixBuyPrice, uint256 _durationDays, uint256 _expireOperation) external {
        depositedFullOwnershipInformation(_receiveETHAddress, _targetContract, _fixBuyPrice, _fixBuyPrice, _durationDays, _expireOperation);
    }

    function depositedOwnershipWithDutchAuction(address _receiveETHAddress, address _targetContract, uint256 _minBuyPrice, uint256 _maxBuyPrice, uint256 _durationDays, uint256 _expireOperation) external {
        depositedFullOwnershipInformation(_receiveETHAddress, _targetContract, _minBuyPrice, _maxBuyPrice, _durationDays, _expireOperation);
    }

    function depositedFullOwnershipInformation(address _receiveETHAddress, address _targetContract, uint256 _minBuyPrice, uint256 _maxBuyPrice, uint256 _durationDays, uint256 _expireOperation) nonReentrant private {
        address _currentTargetContractOwner = contractModal(_targetContract).owner();
        require(_currentTargetContractOwner == msg.sender, "you are not the target contract owner !");
        require(_targetContract != address(0x0), "target contract address cannot be 0x0 address !");
        require(_receiveETHAddress != address(0x0), "receive the ETH address cannot be 0x0 address !");
        require(_maxBuyPrice >= _minBuyPrice, "maxBuyPrice must greater or equal to minBuyPrice !");
        require(_minBuyPrice >= currentMinBuyPrice, "initial buy price too low !");
        require(_durationDays * durationUint >= minDurationDays && _durationDays * durationUint <= maxDurationDays, "durationDays must between 1 days and 30 days !");

        ExpireOperations _operation;
        if(_expireOperation == 0){
            _operation = ExpireOperations.TransferToSeller;
        }else if(_expireOperation == 1){
            _operation = ExpireOperations.Destroy;
        }else if(_expireOperation == 2){
            _operation = ExpireOperations.StayInRaasForever;
        }else{
            revert("expireOperation must between 0,1,2 !");
        }

        if(depositedOwnershipMapping[_targetContract].callerAddress == address(0x0)){
            totalDepositsCount += 1;
        }

        DepositedOwnershipStruct memory dos = DepositedOwnershipStruct({
        callerAddress: msg.sender,
        receiveETHAddress: _receiveETHAddress,
        targetContract: _targetContract,
        minBuyPrice: _minBuyPrice,
        maxBuyPrice: _maxBuyPrice,
        platformFee: currentPlatformFee,
        depositedTime: block.timestamp,
        durationDays: _durationDays,
        expireOperation: _operation
        });
        depositedOwnershipMapping[_targetContract] = dos;

        emit depositedOwnershipLog(msg.sender, _targetContract, _durationDays);
    }

    function sellerRetrieveOwnership(address _targetContract) nonReentrant external returns(bool){
        if(ownershipInRaas(_targetContract)){
            DepositedOwnershipStruct memory dos = depositedOwnershipMapping[_targetContract];
            require(msg.sender == dos.callerAddress, "caller is not original seller user !");
            if(isTradeTimeout(dos)){
                if(dos.expireOperation == ExpireOperations.TransferToSeller){
                    contractModal(_targetContract).transferOwnership(msg.sender);
                    emit retrieveOwnershipLog(msg.sender, _targetContract, block.timestamp);
                    return true;
                }else if(dos.expireOperation == ExpireOperations.Destroy){
                    contractModal(_targetContract).transferOwnership(0x000000000000000000000000000000000000dEaD);
                    emit destroyOwnershipLog(msg.sender, _targetContract, block.timestamp);
                    if(!destroyContractMapping[_targetContract]){
                        destroyContractMapping[_targetContract] = true;
                        raasUserMint(msg.sender);
                    }
                    return false;
                }else{
                    return false;
                }
            }else{
                revert("trade is not timeout yet !");
            }
        }else{
            revert("target contract Ownership not controlled by RAAS !");
        }
    }

    function buyOwnership(address _targetContract) nonReentrant payable external returns(bool){
        require(!isContract(msg.sender), "caller cannot be contract !");
        if(existsValidOwnershipTrade(_targetContract)){
            uint256 currentPrice = getCurrentOwnershipPrice(_targetContract);
            require(msg.value >= currentPrice, "buyer send ETH is not enough.");

            contractModal(_targetContract).transferOwnership(msg.sender);
            address _targetContractCurrentOwner = contractModal(_targetContract).owner();
            require(_targetContractCurrentOwner == msg.sender, "transfer Ownership to buyer failed.");

            DepositedOwnershipStruct memory dos = depositedOwnershipMapping[_targetContract];
            uint256 receiveETHValue = (currentPrice * (100 - dos.platformFee)) / 100;
            (bool s1, ) = payable(dos.receiveETHAddress).call{value: receiveETHValue}("");
            require(s1, "transfer ETH to seller failed.");
            emit transferETHLog(address(this), dos.receiveETHAddress, receiveETHValue);

            uint256 extraETH = msg.value - currentPrice;
            if(extraETH > 0){
                (bool s2, ) = payable(msg.sender).call{value: extraETH}("");
                require(s2, "transfer extra ETH to buyer failed.");
                emit transferETHLog(address(this), msg.sender, extraETH);
            }

            SoldRecordStruct memory sr = SoldRecordStruct({
            sellerAddress: dos.callerAddress,
            receiveETHAddress: dos.receiveETHAddress,
            buyerAddress: msg.sender,
            targetContract: _targetContract,
            finalBuyPrice: currentPrice,
            platformFee: dos.platformFee,
            depositedTime: dos.depositedTime,
            durationDays: dos.durationDays,
            soledTime: block.timestamp,
            expireOperation: dos.expireOperation
            });
            SoldRecordMapping[_targetContract] = sr;
            totalSoldCount += 1;

            raasUserMint(msg.sender);

            emit buyOwnershipLog(dos.callerAddress, msg.sender, _targetContract, currentPrice);
            return true;
        }else{
            revert("no valid ownership trade exists.");
        }
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function raasUserMint(address mintWallet) private{
        uint256 supply = totalSupply();
        if(supply + 1 <= MAX_SUPPLY){
            uint256 mintCount = allowedMintCountMapping[mintWallet];
            if(mintCount + 1 <= walletMaxMinted){
                allowedMintCountMapping[mintWallet] = mintCount + 1;
                _safeMint(mintWallet, 1);
            }
        }
    }

    function raasGiveawaysAirdrop(address[] calldata addresses) external onlyOwner{
        uint256 amount = addresses.length;
        uint256 supply = totalSupply();
        require(supply + amount <= MAX_SUPPLY, "Can't mint more than max supply !");
        require(GiveawaysMinted + amount <= GiveawaysMaxReserved, "Giveaways Can't mint more than Max Giveaways Reserved !");
        GiveawaysMinted += amount;
        for (uint i = 0; i < amount; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function raasAdminMint(uint amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + amount <= MAX_SUPPLY, "Can't mint more than max supply !");
        require(AdminMinted + amount <= AdminMaxReserved, "Admin Can't mint more than Max Admin Reserved !");
        AdminMinted += amount;
        _safeMint(msg.sender, amount);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0x0));
        owner = _newOwner;
    }

    function revelRAASNFT(string calldata baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function raasSetPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee >= minPlatformFee && _platformFee <= maxPlatformFee, "platform fee not in scope !");
        currentPlatformFee = _platformFee;
    }

    function raasSetMinBuyPrice(uint256 _minBuyPrice) external onlyOwner {
        require(_minBuyPrice >= minBuyPriceGlobalMin && _minBuyPrice <= minBuyPriceGlobalMax, "minBuyPrice not in scope!");
        currentMinBuyPrice = _minBuyPrice;
    }


    function raasWithdrawERC20(address tokenAddress) external onlyOwner{
        uint256 amount = contractModal(tokenAddress).balanceOf(address(this));
        contractModal(tokenAddress).transfer(msg.sender, amount);
    }

    function raasWithdrawNFT(address nftAddress, uint256[] calldata tokenIds) external onlyOwner{
        for (uint i = 0; i < tokenIds.length; i++) {
            contractModal(nftAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    function raasWithdrawETH() external onlyOwner{
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "withdraw ETH failed.");
        emit transferETHLog(address(this), msg.sender, address(this).balance);
    }

    receive() external payable {
    }

    fallback() external payable {
    }

}
