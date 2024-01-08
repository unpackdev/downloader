pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./BrokeBoyz.sol";

contract BrokeBoyzMinterUpgrade is Ownable {
    using Strings for string;
    using SafeMath for uint256;

    address public nftAddress;
    uint256 public MAX_SUPPLY;
    uint256 public publicMintPrice;
    uint256 public presaleMintPrice;



    bool public public_pass_minting;
    bool public holders_mint_pass; 
    bool public free_mint_pass; 

    uint256[] public usedBboyz;
    mapping(uint256 => bool) public usedBboyzMapping;



    constructor(address _nftAddress) {
        MAX_SUPPLY = 5000;
        publicMintPrice = 69000000000000000; // 0.069 ETH
        presaleMintPrice = 33000000000000000; // 0.033 ETH
        nftAddress = _nftAddress;
        public_pass_minting = false;
        free_mint_pass = false;
        holders_mint_pass = false;

    }

    function getUsedBboyz() public view returns (uint256[] memory) {
        return usedBboyz;
    }

    function setHoldersMintPass(bool isEnabled) public onlyOwner {
        holders_mint_pass = isEnabled;
    }

    function setPublicMintPass(bool isEnabled) public onlyOwner {
        public_pass_minting = isEnabled;
    }

    function setFreeMintPass(bool isEnabled) public onlyOwner {
        free_mint_pass = isEnabled;
    }

    function name() external pure returns (string memory) {
        return "Broke Boyz minter";
    }

    function symbol() external pure returns (string memory) {
        return "BBZ";
    }

    function freeMintPass(address _toAddress, uint256[] calldata boyzToUse) external {
        require(boyzToUse.length == 6, "6 bboyz are needed to mint a free token");
        require(free_mint_pass, "Minting hasn't started yet");

        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.passSupply();


        for (uint i=0; i < boyzToUse.length; i++) {
            require(brokeBoyz.ownerOf(boyzToUse[i]) == _msgSender(), "sender is not the owner of sent bboy");
            require(!usedBboyzMapping[boyzToUse[i]], "Some or all bboyz already used for free mint");
        }

        for (uint i=0; i < boyzToUse.length; i++) {
            usedBboyzMapping[boyzToUse[i]] = true;
        }

        
        require(currentSupply + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        brokeBoyz.factoryMintMintPass(_toAddress);
        
    }


    function privateMintBblock(uint256 amount, address _toAddress) external onlyOwner {
        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.bBlockSupply();
        require(currentSupply + amount <= 250, "Purchase would exceed allocated private sale");

        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintBblock(_toAddress);
        }

    }

    function holdersMintPass(uint256 amount, address _toAddress) external payable {

        require(holders_mint_pass, "Minting hasn't started yet");
        
        require(presaleMintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");

        BrokeBoyz brokeBoyz = BrokeBoyz(nftAddress);
        uint256 currentSupply = brokeBoyz.passSupply();

        require(brokeBoyz.balanceOf(_msgSender()) > 0, "Sender is not a holder");
        require(currentSupply + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        for (uint256 i = 0; i < amount; i++) {
            brokeBoyz.factoryMintMintPass(_toAddress);
        }
    }


    function publicMintPass(uint256 amount, address _toAddress) external payable {
        require(public_pass_minting, "Public minting isn't allowed yet");
        require(publicMintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");

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


}

//    Deploying 'BrokeBoyzMinterUpgrade'
//    ----------------------------------
//    > transaction hash:    0x3c79de1ba9de010f47eb8b5753ef51fa1a0bc7dc321bc1eb42a7f83bcff4a0d3
//    > Blocks: 4            Seconds: 92
//    > contract address:    0xa5A61AA88d07E55812dFB8B113b8eadb132601c9
//    > block number:        13595430
//    > block timestamp:     1636640568
//    > account:             0xCd1B5613E06A6d66F5106cF13E103C9B98253B0c
//    > balance:             0.23921547270528375
//    > gas used:            1353690 (0x14a7da)
//    > gas price:           130 gwei
//    > value sent:          0 ETH
//    > total cost:          0.1759797 ETH

//    Pausing for 2 confirmations...
//    ------------------------------
//    > confirmation number: 1 (block: 13595432)
//    > confirmation number: 3 (block: 13595434)
//    > Saving artifacts
//    -------------------------------------
//    > Total cost:           0.1759797 ETH