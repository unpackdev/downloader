// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./IERC20.sol";

contract LandAssestSale is Ownable {
    address public erc1155Address;

    address public erc20Address;

    address public masterAddress;

    // Define if sale is active
    bool public saleIsActive = false;

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    uint256 public CURRENT_PRICE = 1000000 * 10**18;

    constructor(address _erc1155Address, address _erc20Address) {
        erc1155Address = _erc1155Address;
        erc20Address = _erc20Address;
    }

    event BuyLandAsset(address bullieverAsset, uint256 amount);
    event ChangeERC1155Address(
        address indexed oldAddress,
        address indexed newAddress
    );

    event ChangeERC20Address(
        address indexed oldAddress,
        address indexed newAddress
    );

    // Buy LandAssestSale
    function buyLandAssestSale(uint256 amount, uint256 collectionId)
        public
        payable
    {   
        require(saleIsActive, "Mint is not available right now");
        require(amount <= MAX_PURCHASE, "Can only mint 20 tokens at a time");

        IERC20(erc20Address).transferFrom(
            msg.sender,
            masterAddress,
            amount * CURRENT_PRICE
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

    function changeERC20Address(address newErc20Address) public onlyOwner {
        address oldErc20Address = erc20Address;
        erc20Address = newErc20Address;
        emit ChangeERC1155Address(oldErc20Address, newErc20Address);
    }

    function changeSaleState(bool newSaleState) public onlyOwner {
        saleIsActive = newSaleState;
    }

    function changeMasterAddress(address newMasterAddress) public onlyOwner {
        masterAddress = newMasterAddress;
    }
}
