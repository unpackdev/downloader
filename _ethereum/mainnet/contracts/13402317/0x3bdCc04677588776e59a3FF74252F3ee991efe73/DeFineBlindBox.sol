// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./DeFineBlindNFT.sol";

contract DeFineBlindBox is Ownable {
    uint256 private _counter;
    
    struct Pool {
        bool saleIsActive;
        uint256 mintPrice;
        uint256 remainingAmount;
        address acceptCurrency;
        uint256 startTime;
        uint256 endTime;
        uint256 nonce;
        uint256 levels;
        uint256 feeRate; // 10000 for max
        uint256 fee;
        address beneficiary;
        uint256 benefits;
        address nftAddress;
        uint256 benefitUnit;
        uint256 feeUnit;
    }

    mapping (string => Pool) Pools;
    
    mapping (string => mapping (uint256 => uint256)) level_count;
    address ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    
    event Mint(address minter, uint256 tokenId, uint256 level, string name, address nftAddress);


    modifier whenSaleActive(string memory name) {
        require(Pools[name].saleIsActive == true, "Sale is not active");
        _;
    }
    
    modifier onlyBeneficiary(string memory name) {
        require(msg.sender == Pools[name].beneficiary, 'forbidden to withdraw');
        _;
    }
    
    modifier updateFeeAndBenefit(string memory name) {
        _;
        require(Pools[name].remainingAmount > 0, 'pool not exist');
        uint256 feeUnit = Pools[name].mintPrice * Pools[name].feeRate / 10000;
        Pools[name].benefitUnit = Pools[name].mintPrice - feeUnit;
        Pools[name].feeUnit = feeUnit;
    }
    
    constructor(){}
    
    function createPool(
        string memory name,
        uint256 mintPrice,
        uint256 remainingAmount,
        address acceptCurrency,
        uint256 startTime,
        uint256 endTime,
        uint256 nonce,
        uint256 levels,
        uint256 feeRate,
        address beneficiary,
        address nftAddress) external onlyOwner {
            uint256 feeUnit = mintPrice * feeRate / 10000;
            
            Pool memory pool = Pool(
            true,
            mintPrice,
            remainingAmount,
            acceptCurrency,
            startTime,
            endTime,
            nonce,
            levels,
            feeRate,
            0,
            beneficiary,
            0,
            nftAddress,
            mintPrice - feeUnit,
            feeUnit);
            
            Pools[name] = pool;
        }
    
    function updateLevel(string memory name, uint256 _level, uint256 _count) external onlyOwner {
        require(_level <= Pools[name].levels - 1, 'level invalid');
        level_count[name][_level] = _count;
    }

    // Mint
    function mintBox(string memory name) external payable whenSaleActive(name) returns (uint256, uint256, address) {
        require(Pools[name].nftAddress != ZERO_ADDRESS, 'Nft address not set.');
        require(Pools[name].startTime <= block.timestamp, "Mint not started.");
        require(Pools[name].endTime >= block.timestamp, "Mint closed.");
        require(Pools[name].remainingAmount > 0, 'max cap reached');
        
        if (Pools[name].acceptCurrency == ZERO_ADDRESS) {
            require(msg.value >= Pools[name].mintPrice, "Insufficient funds.");
        } else {
            IERC20(Pools[name].acceptCurrency).transferFrom(msg.sender, address(this), Pools[name].mintPrice);
        }
        
        Pools[name].fee += Pools[name].feeUnit;
        Pools[name].benefits += Pools[name].benefitUnit;

        uint256 level = defineRarity(name, rand(Pools[name].remainingAmount, name));
        Pools[name].remainingAmount = Pools[name].remainingAmount - 1;
        uint256 tokenId = DeFineBlindNFT(Pools[name].nftAddress).mint(msg.sender);
        emit Mint(msg.sender, tokenId, level, name, Pools[name].nftAddress);
        return (level, tokenId, Pools[name].nftAddress);
    }
    
    
    function rand(uint256 _range, string memory name) internal returns (uint256) {
        uint256 _random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, Pools[name].nonce))) % _range;
        Pools[name].nonce = Pools[name].nonce + 1;
        return _random + 1;
    }
    
    function defineRarity(string memory name, uint256 random) internal returns (uint256) {
        for (uint i = 0; i < Pools[name].levels - 1; i++) {
            if (random < level_count[name][i]) {
                level_count[name][i] = level_count[name][i] - 1;
                return i;
            } else {
                random = random - level_count[name][i];
            }
        }
    }

    function setStartTime(string memory name, uint256 _time) external onlyOwner {
        Pools[name].startTime = _time;
    }

    function setEndTime(string memory name, uint256 _time) external onlyOwner {
       Pools[name].endTime = _time;
    }
    
    function setMintPrice(string memory name, uint256 _mintPrice) external onlyOwner updateFeeAndBenefit(name) {
        Pools[name].mintPrice = _mintPrice;
    }
    
    function setNftAddress(string memory name, address _address) external onlyOwner {
        Pools[name].nftAddress = _address;
    }
    
    function setAcceptCurrency(string memory name, address _currency) external onlyOwner {
        Pools[name].acceptCurrency = _currency;
    }
    
    function setNonce(string memory name, uint256 _nonce) external onlyOwner {
        Pools[name].nonce = _nonce;
    }
    
    function setFeeRate(string memory name, uint256 _rate) external onlyOwner updateFeeAndBenefit(name) {
        Pools[name].feeRate = _rate;
        
        uint256 feeUnit = Pools[name].mintPrice * Pools[name].feeRate / 10000;
        Pools[name].benefitUnit = Pools[name].mintPrice - feeUnit;
        Pools[name].feeUnit = feeUnit;
    }
    
    function setBeneficary(string memory name, address _beneficiary) external onlyOwner {
        Pools[name].beneficiary = _beneficiary;
    }
    
    function setLevels(string memory name, uint256 _levels) external onlyOwner {
        Pools[name].levels = _levels;
    }

    function toggleSaleState(string memory name) external onlyOwner {
        Pools[name].saleIsActive = !Pools[name].saleIsActive;
    }
    
    function distribution(string memory name, address _payee) external onlyOwner {
        require(Pools[name].benefits > 0 || Pools[name].fee > 0, 'no money to dist.');
        uint256 benefits = Pools[name].benefits;
        uint256 fee = Pools[name].fee;
        Pools[name].benefits = 0;
        Pools[name].fee = 0;
        if (Pools[name].acceptCurrency == ZERO_ADDRESS) {
            payable(_payee).transfer(fee);
            payable(Pools[name].beneficiary).transfer(benefits);
        } else {
            IERC20(Pools[name].acceptCurrency).transfer(_payee, fee);
            IERC20(Pools[name].acceptCurrency).transfer(Pools[name].beneficiary, benefits);
        }
        
    }

    function claimBenefits(string memory name) external onlyBeneficiary(name) {
        require(Pools[name].benefits > 0, 'no money to claim.');
        address currency = Pools[name].acceptCurrency;
        uint256 amount = Pools[name].benefits;
        Pools[name].benefits = 0;
        if (currency == ZERO_ADDRESS) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(currency).transfer(msg.sender, amount);
        }
    }
    
    function emergencyWithdraw(address _payee, uint256 _amount, address _currency) external onlyOwner {
        if (_currency == ZERO_ADDRESS) {
            payable(_payee).transfer(_amount);
        } else {
            IERC20(_currency).transfer(_payee, _amount);
        }
    }
}
