pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./PlayersOnlyNFT.sol";


contract PlayersOnlyNFTMinter is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public nftAddress;
    uint256 public MAX_SUPPLY;
    uint256 public price;

    bool public public_minting;

    PlayersOnlyNFT playersOnlyNFT;

    uint256 public counter;
    
    constructor(address _nftAddress) {
        MAX_SUPPLY = 9990;
        price = 80000000000000000;
        playersOnlyNFT = PlayersOnlyNFT(_nftAddress);
        nftAddress = _nftAddress;
        public_minting = true;
        counter = 3688;
    }

    modifier onlyOwnerOrDev() {
        require(owner() == _msgSender() || _msgSender() == 0xCd1B5613E06A6d66F5106cF13E103C9B98253B0c, "Ownable: caller is not the owner");
        _;
    }

    function publicMint(address _toAddress, uint256 amount) external payable nonReentrant {
        require(public_minting, "Public minting isn't allowed yet");
        require(playersOnlyNFT.totalSupply().add(amount) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(price.mul(amount) <= msg.value, "Ether value sent is not correct");


        for (uint256 i = 0; i < amount; i++) {
            playersOnlyNFT.factoryMint(_toAddress);
            counter++;
        }
    }

    function startPublicSale() external onlyOwnerOrDev {
        public_minting = true;
    }

    struct PayoutTable {
        address walletTen1;
        address walletTen2;
        address walletTen3;
        address walletTen4;
        address walletTen5;
        address walletTen6;
        address walletTen7;
        address walletEight;
        address walletSeven;
        address walletFive1;
        address walletFive2;
        address walletThree;
        address walletTwo;
    }

    function withdraw() external onlyOwner {
        PayoutTable memory payoutTable;
        uint256 balance = address(this).balance;

        uint256 tenPercent = balance.mul(10).div(100);
        uint256 eightPercent = balance.mul(8).div(100);
        uint256 sevenPercent = balance.mul(7).div(100);
        uint256 fivePercent = balance.mul(5).div(100);
        uint256 threePecent = balance.mul(3).div(100);
        uint256 twoPercent = balance.mul(2).div(100);

        payoutTable.walletTen1 = 0x366E3CE88b92c3973F3522Ec91d6fcD11BDa8CdC;
        payoutTable.walletTen2 = 0x405aff472b8EAC6a9541707D78e6F192d90B4c2C;
        payoutTable.walletTen3 = 0x8d1985967282c1019fCd42B46F18bE6CC597989B;
        payoutTable.walletTen4 = 0xfeF05cf80913F1d1E970F9587b0a884106D9e909;
        payoutTable.walletTen5 = 0x4dC3BD8918c18cf778c5b67Da7DB58D28880Fe73;
        payoutTable.walletTen6 = 0xEf72D8793Ab32d20358aa0303ae1405E8B695DA6;
        payoutTable.walletTen7 = 0x74893b849076135FceC3Baf0FF571640f6c1e038;
        payoutTable.walletEight = 0xE990519dd9DCdd085360D1C7C54520Fd85ddBeD4;
        payoutTable.walletSeven = 0x697bf1008D142A8D8251C03471384216e760e97e;
        payoutTable.walletFive1 = 0x144b30e857Dcf819419f41A0202AF9df85694509;
        payoutTable.walletFive2 = 0x465fFE2077D5a8911b7dDd6f2f8D46f7d9769362;
        payoutTable.walletThree = 0xA629B8793F2A8D20744a166f5B0F7193fc0f713e;
        payoutTable.walletTwo = 0xb110D64D0c791199FA0dA809E8DcDa1Aeea2D0a9;
    
        payable(payoutTable.walletTen1).transfer(tenPercent);
        payable(payoutTable.walletTen2).transfer(tenPercent);
        payable(payoutTable.walletTen3).transfer(tenPercent);
        payable(payoutTable.walletTen4).transfer(tenPercent);
        payable(payoutTable.walletTen5).transfer(tenPercent);
        payable(payoutTable.walletEight).transfer(eightPercent);
        payable(payoutTable.walletSeven).transfer(sevenPercent);
        payable(payoutTable.walletFive1).transfer(fivePercent);
        payable(payoutTable.walletFive2).transfer(fivePercent);
        payable(payoutTable.walletThree).transfer(threePecent);
        payable(payoutTable.walletTwo).transfer(twoPercent);
        payable(payoutTable.walletTen6).transfer(tenPercent);
        payable(payoutTable.walletTen7).transfer(tenPercent);

    }

}
