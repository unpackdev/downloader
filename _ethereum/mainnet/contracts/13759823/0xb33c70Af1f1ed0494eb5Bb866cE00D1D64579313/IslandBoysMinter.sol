pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./IslandBoys.sol";

contract IslandBoysMinter is Ownable, ReentrancyGuard {
    using Strings for string;
    using SafeMath for uint256;

    address public nftAddress;
    uint256 public MAX_SUPPLY;
    uint256 public price;

    bool public public_minting;
    bool public whitelistMinting;
    bool public dogeWhitelistMinting;

    mapping(address => uint256) public whitelistMints;
    mapping(address => uint256) public dogeWhitelistMints;
    mapping(address => uint256) public publicSale;

    mapping(address => bool) public whiteList;

    IslandBoys islandBoys;

    uint256 public reserveCounter;
    uint256 public dogeReserveCounter;
    uint256 public counter;
    
    constructor(address _nftAddress) {
        MAX_SUPPLY = 10000;
        price = 35000000000000000;
        nftAddress = _nftAddress;
        public_minting = false;
        whitelistMinting = false;
        dogeWhitelistMinting = false;
        islandBoys = IslandBoys(nftAddress);
        reserveCounter = 0;
        dogeReserveCounter = 0;
        counter = 0;
    }

    modifier onlyOwnerOrDev() {
        require(owner() == _msgSender() || _msgSender() == 0xCd1B5613E06A6d66F5106cF13E103C9B98253B0c, "Ownable: caller is not the owner");
        _;
    }

    function addToWhitelist(address[] calldata addressToAdd) external onlyOwnerOrDev {
        for (uint i=0; i<addressToAdd.length; i++) {
            whiteList[addressToAdd[i]] = true;
        }
    }


    function publicMint(address _toAddress, uint256 amount) external payable nonReentrant {
        require(amount <= 10, "10 mints max per transaction");
        require(public_minting, "Public minting isn't allowed yet");
        require(counter.add(amount) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(price.mul(amount) <= msg.value, "Ether value sent is not correct");

        uint256 currentMints = publicSale[_toAddress];
        require(currentMints.add(amount) <= 10);

        for (uint256 i = 0; i < amount; i++) {
            islandBoys.factoryMint(_toAddress);
            counter++;
            currentMints++;
        }
        publicSale[_toAddress] = currentMints;
        
    }

    function whitelistMint(address _toAddress, uint256 amount) external payable nonReentrant {
        require(amount <= 10, "10 mints max per transaction");
        require(whiteList[_msgSender()], "Sender is not whitelisted!");
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(counter.add(amount) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(price.mul(amount) <= msg.value, "Ether value sent is not correct");

        uint256 currentMints = whitelistMints[_toAddress];
        require(currentMints.add(amount) <= 10);

        for (uint256 i = 0; i < amount; i++) {
            islandBoys.factoryMint(_toAddress);
            counter++;
            currentMints++;
        }
        whitelistMints[_toAddress] = currentMints;
    }

    function dogeWhitelistMint(address _toAddress, uint256 amount) external payable nonReentrant {
        require(amount <= 10, "10 mints max per transaction");
        require(dogeWhitelistMinting, "Doge whitelist minting isn't allowed yet");
        require(counter.add(amount) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(price.mul(amount) <= msg.value, "Ether value sent is not correct");

        uint256 currentMints = dogeWhitelistMints[_toAddress];
        require(currentMints.add(amount) <= 10);

        for (uint256 i = 0; i < amount; i++) {
            islandBoys.factoryMint(_toAddress);
            counter++;
            currentMints++;
        }
        dogeWhitelistMints[_toAddress] = currentMints;
    }

    function ownerMint(address _toAddress, uint256 amount) external onlyOwner {
        require(counter.add(amount) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(reserveCounter.add(amount) <= 100, "Purchase would exceed max supply for owner");

        for (uint256 i = 0; i < amount; i++) {
            islandBoys.factoryMint(_toAddress);
            reserveCounter++;
            counter++;
        }
        
    }

    function dogeReserveMint(address _toAddress, uint256 amount) external {
        require(msg.sender == 0xEf72D8793Ab32d20358aa0303ae1405E8B695DA6, "Only ment for doge address");
        require(counter.add(amount) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(dogeReserveCounter.add(amount) <= 20, "Purchase would exceed max supply for owner");

        for (uint256 i = 0; i < amount; i++) {
            islandBoys.factoryMint(_toAddress);
            dogeReserveCounter++;
            counter++;
        }
        
    }

    function startPublicSale() external onlyOwnerOrDev {
        public_minting = true;
    }

    function enableWhitelistMinting() external onlyOwnerOrDev {
        whitelistMinting = true;
    }

    function disableWhitelistMinting() external onlyOwnerOrDev {
        whitelistMinting = false;
    }

    function enableDogeWhitelistMinting() external onlyOwnerOrDev {
        dogeWhitelistMinting = true;
    }

    function disableDogeWhitelistMinting() external onlyOwnerOrDev {
        dogeWhitelistMinting = false;
    }


    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 tenPercent = balance.mul(10).div(100);
        uint256 sixtyPercent = balance.mul(60).div(100);
        uint256 twentyPercent = balance.mul(20).div(100);

        address wallet60 = 0xB8641ACDc5CdF16434472357B607880274BBFa01;
        address wallet20 = 0x475c685519ec553f9dc526280362050575D50406;
        address dogeFirst10 = 0xEf72D8793Ab32d20358aa0303ae1405E8B695DA6;
        address dogeSecond10 = 0x74893b849076135FceC3Baf0FF571640f6c1e038;

        payable(wallet60).transfer(sixtyPercent);
        payable(wallet20).transfer(twentyPercent);
        payable(dogeFirst10).transfer(tenPercent);
        payable(dogeSecond10).transfer(tenPercent);

    }
}
