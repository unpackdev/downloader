pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";

contract AmadeusVault is Ownable {

    struct Price{
        uint256 export;
        uint256 IPFS;
        uint256 contractWithoutRoyalty;
    }

    mapping(address => Price) private priceOfToken;

    address private vaultAddr;
    event Recharge(string indexed collectionID, uint256 indexed rechargeType);

    constructor(address _vaultAddr) {
        address usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        priceOfToken[usdt] = Price(200 * 1000000, 50 * 1000000,300 * 1000000);
        vaultAddr = _vaultAddr;
    }

    function setVaultAddress(address _vaultAddr) external onlyOwner {
        vaultAddr = _vaultAddr;
    }

    function addRechargeToken(address tokenAddr, Price calldata price) external onlyOwner {
        priceOfToken[tokenAddr] = price;
    }

    function recharge(string calldata collectionID, address tokenAddr, uint256 rechargeType) public {
        uint256 price = getPriceByType(tokenAddr, rechargeType);
        require(price != 0, "Token Not Support.");
        IERC20 token = IERC20(tokenAddr);
        token.transferFrom(msg.sender, vaultAddr, price);
        emit Recharge(collectionID, rechargeType);
    }

    function getPriceByType(address tokenAddr, uint256 rechargeType) public view returns(uint256) {
        require(rechargeType < 8, "Type Not Valid");
        Price memory price = priceOfToken[tokenAddr];
        uint256 totalPrice = 0;
        if (rechargeType % 2 == 1) {
            totalPrice += price.export;
        }
        rechargeType /= 2;
        if (rechargeType % 2 == 1) {
            totalPrice += price.IPFS;
        }
        rechargeType /= 2;
        if (rechargeType % 2 == 1) {
            totalPrice += price.contractWithoutRoyalty;
        }
        return totalPrice;
    }

}
