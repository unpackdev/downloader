// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

//    _   _ _____ _____ ____  ____  ____  ___ _   _ _____
//   | \ | |  ___|_   _|___ \|  _ \|  _ \|_ _| \ | |_   _|
//   |  \| | |_    | |   __) | |_) | |_) || ||  \| | | |
//   | |\  |  _|   | |  / __/|  __/|  _ < | || |\  | | |
//   |_| \_|_|     |_| |_____|_|   |_| \_\___|_| \_| |_|
//

contract ToyNFTContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

contract NFT2PrintLegendaryPass {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

contract NFT2PRINT_LL is AccessControl, ReentrancyGuard {
    bytes32 public constant REGISTER_ROLE = keccak256("REGISTER_ROLE");

    struct ToyID {
        uint256 data;
        address toyCreatorAddres;
    }

    struct TokenInfo{
        IERC20 paytoken;
        uint256 priceStandard;
        uint256 priceLarge;
    }

    mapping (uint256 => TokenInfo) public AllowedCrypto;
    mapping (uint256 => ToyID) public toyData;

    bool public isProductionEnabled = true;
    uint256 public standard_ToyPrice = 0.08 ether;
    uint256 public large_ToyPrice = 0.4 ether;
    uint256 public legendary_Discount = 40;
    uint256 public totalToysCreated = 0;
    uint256 public maxLegendaryUsage = 5;

    mapping(uint256 => uint256) public legendaryID;

    ToyNFTContract private immutable toyaddr;
    NFT2PrintLegendaryPass private immutable legendPass;

    constructor(address ToyAddress, address PassAddress) {
        toyaddr = ToyNFTContract(ToyAddress);
        legendPass = NFT2PrintLegendaryPass(PassAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function toggleToyProductionEnabled() external  onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isProductionEnabled = !isProductionEnabled;
    }

    function setProductionPrice(uint256 _standardPrice, uint256 _largePrice) external onlyRole(DEFAULT_ADMIN_ROLE)   {
        standard_ToyPrice = _standardPrice;
        large_ToyPrice = _largePrice;
    }

    function setLegendaryDiscount(uint256 _discount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        legendary_Discount = _discount;
    }

    function setLegendaryMaxUsage(uint256 _usage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxLegendaryUsage = _usage;
    }

    function addPayToken (uint256 _pid, IERC20 _paytoken, uint256 _priceStandard, uint256 _priceLarge) public onlyRole(DEFAULT_ADMIN_ROLE) {
        
            TokenInfo storage token = AllowedCrypto[_pid];
                token.paytoken = _paytoken;
                token.priceStandard = _priceStandard;
                token.priceLarge = _priceLarge;
     }

    function createToy(uint256[] memory _tokenIdsStandard, uint256[] memory _tokenIdsLarge) public payable {
         
        uint256 totaltokenIdsStd = _tokenIdsStandard.length;
        uint256 totaltokenIdsLrg = _tokenIdsLarge.length;
        require(isProductionEnabled, "Production is disabled");
        require(msg.value >= (standard_ToyPrice * totaltokenIdsStd) + (large_ToyPrice * totaltokenIdsLrg) , "Ether value sent is not correct");

        for (uint256 i = 0; i < totaltokenIdsStd; i++) {
            require(toyaddr.ownerOf(_tokenIdsStandard[i]) == msg.sender, "You must own the orignal NFT");
        }

        for (uint256 i = 0; i < totaltokenIdsLrg; i++) {
            require(toyaddr.ownerOf(_tokenIdsLarge[i]) == msg.sender, "You must own the orignal NFT");
        }

        totalToysCreated += (totaltokenIdsStd + totaltokenIdsLrg) ;
    }

    function createToy_ERC20(uint256[] memory _tokenIdsStandard, uint256[] memory _tokenIdsLarge, uint256 _pid) public nonReentrant {
        
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        
        
        uint256 totaltokenIdsStd = _tokenIdsStandard.length;
        uint256 totaltokenIdsLrg = _tokenIdsLarge.length;
       
        require(isProductionEnabled, "Production is disabled");
        
        for (uint256 i = 0; i < totaltokenIdsStd; i++) {
            require(toyaddr.ownerOf(_tokenIdsStandard[i]) == msg.sender, "You must own the orignal NFT");
        }

        for (uint256 i = 0; i < totaltokenIdsLrg; i++) {
            require(toyaddr.ownerOf(_tokenIdsLarge[i]) == msg.sender, "You must own the orignal NFT");
        }

        require(paytoken.transferFrom(msg.sender, address(this), (tokens.priceStandard * totaltokenIdsStd) + (tokens.priceLarge * totaltokenIdsLrg)));
        
        totalToysCreated += totaltokenIdsStd + totaltokenIdsLrg;
    }

    function createToyLP_ERC20(uint256[] memory _tokenIdsStandard, uint256[] memory _tokenIdsLarge, uint256 _pid, uint256 _legendaryPassId) public nonReentrant {
        
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        
        uint256 totaltokenIdsStd = _tokenIdsStandard.length;
        uint256 totaltokenIdsLrg = _tokenIdsLarge.length;
        uint256 priceStandard = (((100 - legendary_Discount) * tokens.priceStandard) / 100);
        uint256 priceLarge = (((100 - legendary_Discount) * tokens.priceLarge) / 100);

        require(isProductionEnabled, "Production is disabled");
        require(legendPass.ownerOf(_legendaryPassId) == msg.sender, "You must own the NFT2Print Legendary Pass");
        require(legendaryID[_legendaryPassId] + totaltokenIdsStd + totaltokenIdsLrg <= maxLegendaryUsage, "Out of Legendary pass usage");

        for (uint256 i = 0; i < totaltokenIdsStd; i++) {
            require(toyaddr.ownerOf(_tokenIdsStandard[i]) == msg.sender, "You must own the orignal NFT");
        }

        for (uint256 i = 0; i < totaltokenIdsLrg; i++) {
            require(toyaddr.ownerOf(_tokenIdsLarge[i]) == msg.sender, "You must own the orignal NFT");
        }

        require(paytoken.transferFrom(msg.sender, address(this), (priceStandard * totaltokenIdsStd) + (priceLarge * totaltokenIdsLrg)));

        totalToysCreated += totaltokenIdsStd + totaltokenIdsLrg;
        legendaryID[_legendaryPassId] += totaltokenIdsStd + totaltokenIdsLrg;
    }
    
    
    function createToyLP(uint256[] memory _tokenIdsStandard, uint256[] memory _tokenIdsLarge, uint256 _legendaryPassId) public payable nonReentrant
    {
        uint256 totaltokenIdsStd = _tokenIdsStandard.length;
        uint256 totaltokenIdsLrg = _tokenIdsLarge.length;
        uint256 priceStandard = (((100 - legendary_Discount) * standard_ToyPrice) / 100);
        uint256 priceLarge = (((100 - legendary_Discount) * large_ToyPrice) / 100);
        
        require(isProductionEnabled, "Production is disabled");
        require(legendPass.ownerOf(_legendaryPassId) == msg.sender, "You must own the NFT2Print Legendary Pass");
        require(legendaryID[_legendaryPassId] + totaltokenIdsStd + totaltokenIdsLrg <= maxLegendaryUsage, "Out of Legendary pass usage");
        require(msg.value >= (priceStandard * totaltokenIdsStd) + (priceLarge * totaltokenIdsLrg), "Ether value sent is not correct");

        for (uint256 i = 0; i < totaltokenIdsStd; i++) {
            require(toyaddr.ownerOf(_tokenIdsStandard[i]) == msg.sender, "You must own the orignal NFT");
        }

        for (uint256 i = 0; i < totaltokenIdsLrg; i++) {
            require(toyaddr.ownerOf(_tokenIdsLarge[i]) == msg.sender, "You must own the orignal NFT");
        }

        totalToysCreated += totaltokenIdsStd + totaltokenIdsLrg;
        legendaryID[_legendaryPassId] += totaltokenIdsStd + totaltokenIdsLrg;
    }

    function registerToy(uint256 _uidToy, uint256 _data, address _toyCreatorAddress) external onlyRole(REGISTER_ROLE) {
        ToyID storage toy = toyData[_uidToy];

        toy.data = _data;
        toy.toyCreatorAddres = _toyCreatorAddress;
    }

    function registerToyBatch(uint256[] memory _uidToy, uint256[] memory _data, address[] memory _toyCreatorAddress
    ) external onlyRole(REGISTER_ROLE) {
        uint256 uidLenght = _uidToy.length;
        uint256 dataLenght = _data.length;
        uint256 addressLenght = _toyCreatorAddress.length;

        require((uidLenght == dataLenght) && (addressLenght == dataLenght), "Arrays not the same size");

        for (uint256 i = 0; i < uidLenght; i++) {
           
            ToyID storage toy = toyData[_uidToy[i]];
            toy.data = _data[i];
            toy.toyCreatorAddres = _toyCreatorAddress[i];
        }
    }

     function getERC20_token(uint256 _pid) public view virtual returns(IERC20, uint256, uint256) {
            TokenInfo storage token = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = token.paytoken;
            uint256 priceStandard = token.priceStandard;
            uint256 priceLarge = token.priceLarge;
            return (paytoken, priceStandard, priceLarge);
        }

    function getLegendaryPassUsages(uint256 _tokenID) public view returns (uint256) {
        return legendaryID[_tokenID];
    }


    function withdraw() external  onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 contractBalance = address(this).balance;
        bool success = true;

        (success, ) = payable(0x0108E1348D42192a749Ae029fa2Ad7b5c2E6F210).call{
            value: (95 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0x4B8229Db7bBd5901FfbB387A0E7c67E3fb90fC61).call{
            value: (5 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");
    }

    function withdrawERC20(uint256 _pid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }

}
