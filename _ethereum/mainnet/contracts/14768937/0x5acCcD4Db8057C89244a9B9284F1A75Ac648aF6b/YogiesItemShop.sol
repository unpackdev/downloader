// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */

import "./IERC20.sol";
import "./IERC721.sol";
import "./OwnableUpgradeable.sol";

abstract contract IGemies is IERC20 {
    function getEcoSystemBalance(address user) external view returns (uint256) {}
    function spendEcosystemBalance(uint256 amount, address user) external {}
}

abstract contract IYogies is IERC721 {
    function vaultStartPoint() external view returns (uint256) {}
    function viyStartPoint() external view returns (uint256) {}
    function getTotalStakedYogies(address user) external view returns (uint256) {}
    function getYogiesRealOwner(uint256 yogie) external view returns (address) {}
}

abstract contract IYogieItem is IERC721 {
    function mint(address recipient, uint256 amount) external {}   
    function totalSupply() external view returns (uint256) {}
    function balanceOf(address user) external view returns (uint256) {}
}

contract YogiesItemShop is OwnableUpgradeable {

    /** === External contracts === */
    address public openseaProxyRegistryAddress;
    
    IGemies public gemies;
    IYogies public yogies;
    IERC721 public gYogies;

    IYogieItem public houseNFT; // 0
    IYogieItem public carNFT; // 1
    IYogieItem public petsNFT; // 2

    /** === Items data === */
    uint256 public housePrice;
    uint256 public carPrice;
    uint256 public petPrice;

    uint256 public houseSupply;
    uint256 public carSupply;
    uint256 public petSupply;

    /** === Discount === */
    uint256 public gYogieDiscount;
    uint256 public VIYDiscount;
    
    /** EVENTS */
    event PurchaseItem(address indexed buyer, uint256 indexed itemId);

    constructor(
        address _gemies,
        address _yogies,
        address _gYogies,
        address _house,
        address _car,
        address _pet
    ) {}

    function initialize(
        address _gemies,
        address _yogies,
        address _gYogies,
        address _house,
        address _car,
        address _pet
    ) public initializer {
        __Ownable_init();            

        gemies = IGemies(_gemies);
        yogies = IYogies(_yogies);
        gYogies = IERC721(_gYogies);

        houseNFT = IYogieItem(_house);
        carNFT = IYogieItem(_car);
        petsNFT = IYogieItem(_pet);

        housePrice = 60 ether;
        carPrice = 450 ether;
        petPrice = 450 ether;

        houseSupply = 100;
        carSupply = 0;
        petSupply= 22;

        gYogieDiscount = 25;
        VIYDiscount = 25;
    }

    /** === Purchasing === */

    function _validateVIY(uint256 yogieId) internal view returns (bool) {
        return yogieId >= yogies.viyStartPoint();
    }

    function _getDiscountRate(bool isPets, uint256 providedYogie, bool isGenesis)
        internal
        view
        returns (uint256) {
            if (isGenesis && gYogies.balanceOf(msg.sender) > 0) {
                return gYogieDiscount;
            }

            if (_validateVIY(providedYogie) && yogies.getYogiesRealOwner(providedYogie) == msg.sender && isPets) {
                return VIYDiscount;
            }

            return 0;
        }

    function buyHouse(uint256 amount, uint256 providedYogie, bool isGenesis) external {
        require(houseNFT.totalSupply() < houseSupply, "Max houses sold");
        
        uint256 discountRate = _getDiscountRate(false, providedYogie, isGenesis);
        uint256 basePrice = housePrice * (100 - discountRate) / 100;
        uint256 price = basePrice * amount;

        require(gemies.getEcoSystemBalance(msg.sender) >= price, "Gemies balance too low for item");

        gemies.spendEcosystemBalance(price, msg.sender);
        houseNFT.mint(msg.sender, amount);

        emit PurchaseItem(msg.sender, 0);
    }

    function buyCar(uint256 amount, uint256 providedYogie, bool isGenesis) external {
        require(carNFT.totalSupply() < carSupply, "Max cars sold");
        
        uint256 discountRate = _getDiscountRate(false, providedYogie, isGenesis);
        uint256 basePrice = carPrice * (100 - discountRate) / 100;
        uint256 price = basePrice * amount;

        require(gemies.getEcoSystemBalance(msg.sender) >= price, "Gemies balance too low for item");

        gemies.spendEcosystemBalance(price, msg.sender);
        carNFT.mint(msg.sender, amount);

        emit PurchaseItem(msg.sender, 1);
    }

    function buyPets(uint256 amount, uint256 providedYogie, bool isGenesis) external {
        require(petsNFT.totalSupply() < petSupply, "Max pets sold");
        require(houseNFT.balanceOf(msg.sender) > 0, "Need to have at least 1 house to buy pets");
        
        uint256 discountRate = _getDiscountRate(true, providedYogie, isGenesis);
        uint256 basePrice = petPrice * (100 - discountRate) / 100;
        uint256 price = basePrice * amount;

        require(gemies.getEcoSystemBalance(msg.sender) >= price, "Gemies balance too low for item");

        gemies.spendEcosystemBalance(price, msg.sender);
        petsNFT.mint(msg.sender, amount);

        emit PurchaseItem(msg.sender, 2);
    }

    function housesLeft() external view returns (uint256) {
        uint256 totalSupply = houseNFT.totalSupply();
        if (totalSupply > houseSupply)
            return 0;
        else
            return houseSupply - totalSupply;
    }

    function carsLeft() external view returns (uint256) {
        uint256 totalSupply = carNFT.totalSupply();
        if (totalSupply > carSupply)
            return 0;
        else
            return carSupply - totalSupply;
    }

    function petsLeft() external view returns (uint256) {
        uint256 totalSupply = petsNFT.totalSupply();
        if (totalSupply > petSupply)
            return 0;
        else
            return petSupply - totalSupply;
    }
    
    /** === OWNER  ONLY === */

    function setGemies(address _addr) external onlyOwner {
        gemies = IGemies(_addr);
    }

    function setYogies(address _addr) external onlyOwner {
        yogies = IYogies(_addr);
    }

    function setGYogies(address _addr) external onlyOwner {
        gYogies = IERC721(_addr);
    }

    function setGYogieDiscount(uint256 newDiscount) external onlyOwner {
        gYogieDiscount = newDiscount;
    }

    function setVIYDiscount(uint256 newDiscount) external onlyOwner {
        VIYDiscount = newDiscount;
    }

    function setHouseNFT(address _new) external onlyOwner {
        houseNFT = IYogieItem(_new);
    }

    function setCarNFT(address _new) external onlyOwner {
        carNFT = IYogieItem(_new);
    }

    function setPetNFT(address _new) external onlyOwner {
        petsNFT = IYogieItem(_new);
    }

    function setPrices(uint256 _housePrice, uint256 _carPrice, uint256 _petsPrice) external onlyOwner {
        housePrice = _housePrice;
        carPrice = _carPrice;
        petPrice = _petsPrice;
    }

    function setSupplies(uint256 _houseSupply, uint256 _carSupply, uint256 _petsSupply) external onlyOwner {
        houseSupply = _houseSupply;
        carSupply = _carSupply;
        petSupply = _petsSupply;
    }

    receive() external payable {}
}