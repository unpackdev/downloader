pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./BrokeBoyz.sol";

contract BrokeBoyzMinter is Ownable {
    using Strings for string;
    using SafeMath for uint256;

    address public nftAddress;
    uint256 public MAX_SUPPLY;
    uint256 public mintPrice;
    bool public public_bblock_minting;
    bool public public_pass_minting;

    uint256 public whitelistCap;
    uint256 public whitelistAmount;
    mapping(address => bool) public whitelist;
    bool public whitelistOpened; 

    bool public whitelistBblockMinting;
    bool public whitelistMintPassMinting; 


    constructor(address _nftAddress) {
        MAX_SUPPLY = 5000;
        mintPrice = 69000000000000000; // 0.069 ETH
        nftAddress = _nftAddress;
        public_bblock_minting = false;
        public_pass_minting = false;
        whitelistCap = 1000;
        whitelistAmount = 0;
    }

    function setWhitelistCap(uint256 _amount) public onlyOwner {
        whitelistCap = _amount;
    }

    function setWhitelistOpened(bool isOpened) public onlyOwner {
        whitelistOpened = isOpened;
    }

    function setWhitelistBblockMinting(bool isEnabled) public onlyOwner {
        whitelistBblockMinting = isEnabled;
    }

    function setWhitelistMintPassMinting(bool isEnabled) public onlyOwner {
        whitelistMintPassMinting = isEnabled;
    }

    function checkWhitelsitaddress() public view returns (bool) {
        return whitelist[_msgSender()];
    }

    function whitelistAddress(address _addy) public {
        require(whitelistOpened, "Whitelisting hasn't started yet");
        require(whitelistAmount + 1 <= whitelistCap, "Whitelist is full!");
        whitelist[_addy] = true;
        whitelistAmount++;
    }

    function name() external pure returns (string memory) {
        return "Broke Boyz minter";
    }

    function symbol() external pure returns (string memory) {
        return "BBZ";
    }

    function whitelistMintBblock(uint256 amount, address _toAddress) external payable {
        require(whitelistBblockMinting, "Minting hasn't started yet");
        require(whitelist[_msgSender()], "Address is not whitelisted");
        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(amount <= 5, "Too many mints! Max is 5.");

        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.bBlockSupply();

        require(currentSupply + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintBblock(_toAddress);
        }
    }

    function whitelistMintPass(uint256 amount, address _toAddress) external payable {
        require(whitelistMintPassMinting, "Minting hasn't started yet");
        require(whitelist[_msgSender()], "Address is not whitelisted");
        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(amount <= 5, "Too many mints! Max is 5.");

        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.passSupply();

        require(currentSupply + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintMintPass(_toAddress);
        }
    }

    function mintBblock(uint256 amount, address _toAddress) external payable {
        require(public_bblock_minting, "Public minting isn't allowed yet");
        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(amount <= 5, "Too many mints! Max is 5.");

        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.bBlockSupply();

        require(currentSupply + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintBblock(_toAddress);
        }
    }

    function privateMintBblock(uint256 amount, address _toAddress) external onlyOwner {
        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.bBlockSupply();
        require(currentSupply + amount <= 250, "Purchase would exceed allocated private sale");

        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintBblock(_toAddress);
        }

    }

    function mintPass(uint256 amount, address _toAddress) external payable {
        require(public_pass_minting, "Public minting isn't allowed yet");
        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(amount <= 5, "Too many mints! Max is 5.");

        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.passSupply();

        require(currentSupply + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintMintPass(_toAddress);
        }
    }

    function privateMintMintPass(uint256 amount, address _toAddress) external onlyOwner {
        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.passSupply();
        require(currentSupply + amount <= 250, "Purchase would exceed allocated private sale");

        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintMintPass(_toAddress);
        }

    }

    

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        address wallet = 0x3B6Abe1cF8A608632228dFC7395591020D47474D;
        payable(wallet).transfer(balance);
    }

    function setBblockPublicMinting(bool isEnabled) public onlyOwner {
        public_bblock_minting = isEnabled;
    }

    function setPassPublicMinting(bool isEnabled) public onlyOwner {
        public_pass_minting = isEnabled;
    }


}