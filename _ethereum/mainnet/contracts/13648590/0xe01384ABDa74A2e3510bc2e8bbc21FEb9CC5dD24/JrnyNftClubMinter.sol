pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./JrnyNftClub.sol";

contract JrnyNftClubMinter is Ownable {
    using Strings for string;
    using SafeMath for uint256;

    address public nftAddress;
    uint256 public MAX_SUPPLY;
    uint256 public startingPrice;
    bool public public_minting;
    bool public whitelistMinting;
    bool public dogeWhitelistMinting;
    uint256 public currentPrice;
    uint256 starting_block;
    uint256 public decrease_interval;
    uint256 public decrease_per_interval;
    uint256 public ending_price;
    uint256 public counter;

    mapping(address => bool) whiteList;
    mapping(address => bool) dogeWhiteList;
    mapping(address => bool) alreadyMinted;
    uint256 public dogeMintCounter;

    
    constructor(address _nftAddress) {
        MAX_SUPPLY = 9990;
        startingPrice = 3000000000000000000;
        ending_price = 1000000000000000000;
        nftAddress = _nftAddress;
        public_minting = false;
        whitelistMinting = false;
        dogeWhitelistMinting = false;


        decrease_interval = 600;
        decrease_per_interval = 28000000000000000;
        counter = 0;
        dogeMintCounter = 0;
    }

    modifier onlyOwnerOrDev() {
        require(owner() == _msgSender() || _msgSender() == 0xCd1B5613E06A6d66F5106cF13E103C9B98253B0c, "Ownable: caller is not the owner");
        _;
    }

    function getCurrentPrice() public view returns(uint256) {
        uint256 passed_intervals = (block.timestamp.sub(starting_block)).div(decrease_interval);
        if (passed_intervals >= 72) {
            return ending_price;
        } else {
            return startingPrice.sub(passed_intervals.mul(decrease_per_interval));
        }
        
    }

    function mint(address _toAddress) external payable {
        require(public_minting, "Public minting isn't allowed yet");

        uint256 passed_intervals = (block.timestamp.sub(starting_block)).div(decrease_interval);
        require(passed_intervals <= 144, "Sale has ended");
        if (passed_intervals < 24) {
            require(!alreadyMinted[_msgSender()], "Sender already minted one token");
        }
    
        require(counter + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");

        uint256 currentMintPrice = getCurrentPrice();
        require(currentMintPrice <= msg.value, "Ether value sent is not correct");

        JrnyNftClub jrnyClub = JrnyNftClub(nftAddress);
        jrnyClub.factoryMint(_toAddress);
        alreadyMinted[_msgSender()] = true;
        counter++;
    }

    function whitelistMint(address _toAddress) external payable {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(whiteList[_msgSender()], "Sender is not whitelisted!");
        require(!alreadyMinted[_msgSender()], "Sender already minted one token");
        require(counter + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(ending_price <= msg.value, "Ether value sent is not correct");

        JrnyNftClub jrnyClub = JrnyNftClub(nftAddress);
        jrnyClub.factoryMint(_toAddress);
        alreadyMinted[_msgSender()] = true;
        counter++;
    }

    function dogeWhitelistMint(address _toAddress) external payable {
        require(dogeWhitelistMinting, "Whitelist minting isn't allowed yet");
        require(dogeWhiteList[_msgSender()], "Sender is not whitelisted!");
        require(!alreadyMinted[_msgSender()], "Sender already minted one token");
        require(counter + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(ending_price <= msg.value, "Ether value sent is not correct");

        JrnyNftClub jrnyClub = JrnyNftClub(nftAddress);
        jrnyClub.factoryMint(_toAddress);
        alreadyMinted[_msgSender()] = true;
        counter++;
        dogeMintCounter++;
    }

    function ownerMint(address _toAddress, uint256 amount) external onlyOwner {
        require(counter + amount <= MAX_SUPPLY, "Purchase would exceed max supply for owner");
        JrnyNftClub jrnyClub = JrnyNftClub(nftAddress);

        for (uint256 i = 0; i < amount; i++) {
            jrnyClub.factoryMint(_toAddress);
            counter++;
        }
        
    }

    function addToWhitelist(address[] calldata addressToAdd) external onlyOwnerOrDev {
        for (uint i=0; i<addressToAdd.length; i++) {
            whiteList[addressToAdd[i]] = true;
        }
    }

    function addToDogeWhitelist(address[] calldata addressToAdd) external onlyOwnerOrDev {
        for (uint i=0; i<addressToAdd.length; i++) {
            dogeWhiteList[addressToAdd[i]] = true;
        }
    }

    function privateDogeWhitelistMint(uint256 amount) external payable {
        require(_msgSender() == 0x697e931a9AeF56dEaB9D3C61E6C347847D817c31);
        require(ending_price * amount <= msg.value, "Ether value sent is not correct");
        require(dogeMintCounter + amount <= 3000);
        require(counter + amount <= MAX_SUPPLY);

        JrnyNftClub jrnyClub = JrnyNftClub(nftAddress);
        for (uint256 i = 0; i < amount; i++) {
            jrnyClub.factoryMint(_msgSender());
            counter++;
            dogeMintCounter++;
        }

    }

    function startPublicSale() external onlyOwnerOrDev {
        public_minting = true;
        starting_block = block.timestamp;
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
        address wallet = 0x4DF6152f1aB6F653446DAAa21036493C4D61c0F9;
        payable(wallet).transfer(balance);
    }
}