// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./IERC20.sol";

contract ToolSale is Ownable {
    address public erc1155Address;

    address public lvmhToken;

    mapping(uint256 => address) public tokens;

    mapping(uint256 => uint256) public rates;

    address public masterAddress;

    uint256 MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // Define if sale is active
    bool public saleIsActive = false;

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    uint256 public CURRENT_PRICE = 1000000 * 10**18;

    constructor(address _erc1155Address) {
        erc1155Address = _erc1155Address;
    }

    event BuyLandAsset(address bullieverAsset, uint256 amount);
    event ChangeERC1155Address(
        address indexed oldAddress,
        address indexed newAddress
    );

    event ChangelvmhToken(
        address indexed oldAddress,
        address indexed newAddress
    );

    event ChangedRates(uint256 indexed collectionId, uint256 indexed rate);
    event ChangedBuyToken(uint256 indexed collectionId, address token);

    function changeRates(uint256 collectionId, uint256 rate) public onlyOwner {
        rates[collectionId] = rate;
        emit ChangedRates(collectionId, rate);
    }

    function changeBuyToken(uint256 collectionId, address buyToken)
        public
        onlyOwner
    {
        tokens[collectionId] = buyToken;
        emit ChangedBuyToken(collectionId, buyToken);
    }

    // Buy LandAssestSale
    function buyLandAssestSale(uint256 amount, uint256 collectionId)
        public
        payable
    {
        require(saleIsActive, "Mint is not available right now");
        require(amount <= MAX_PURCHASE, "Can only mint 20 tokens at a time");

        IERC20(lvmhToken).transferFrom(
            msg.sender,
            masterAddress,
            amount * CURRENT_PRICE
        );

        IERC20(tokens[collectionId]).transferFrom(
            msg.sender,
            masterAddress,
            amount * rates[collectionId]
        );

        IERC1155(erc1155Address).safeTransferFrom(
            masterAddress,
            msg.sender,
            collectionId,
            amount,
            ""
        );
        emit BuyLandAsset(erc1155Address, amount);
    }

    function changeERC1155Address(address newErc1155Address) public onlyOwner {
        address oldERC1155Address = erc1155Address;
        erc1155Address = newErc1155Address;
        emit ChangeERC1155Address(oldERC1155Address, newErc1155Address);
    }

    function changelvmhToken(address newlvmhToken) public onlyOwner {
        address oldlvmhToken = lvmhToken;
        lvmhToken = newlvmhToken;
        emit ChangeERC1155Address(oldlvmhToken, newlvmhToken);
    }

    function changeSaleState(bool newSaleState) public onlyOwner {
        saleIsActive = newSaleState;
    }

    function changeMasterAddress(address newMasterAddress) public onlyOwner {
        masterAddress = newMasterAddress;
    }

    function changelvmhTokenPrice(uint256 newAmount) public onlyOwner {
        CURRENT_PRICE = newAmount;
    }
}
