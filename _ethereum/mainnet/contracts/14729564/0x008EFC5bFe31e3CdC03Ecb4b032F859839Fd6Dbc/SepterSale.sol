// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./IERC20.sol";

contract SepterSale is Ownable {
    address public erc1155Address;

    address public lvmhAddress;

    address public septerAddress;

    address public masterAddress;

    // Define if sale is active
    bool public saleIsActive = false;

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    uint256 public LVMH_PRICE = 1800000 * 10**18;

    uint256 public SEPTER_PRICE = 120 * 10**18;

    constructor(address _erc1155Address, address _lvmhAddress,address _septerAddress) {
        erc1155Address = _erc1155Address;
        lvmhAddress = _lvmhAddress;
        septerAddress= _septerAddress;
    }

    event BuyLandAsset(address bullieverAsset, uint256 amount);
    event ChangeERC1155Address(
        address indexed oldAddress,
        address indexed newAddress
    );

    event ChangeLvmhAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    // Buy SepterSale
    function buySepterSale(uint256 amount, uint256 collectionId)
        public
        payable
    {   
        require(saleIsActive, "Mint is not available right now");
        require(amount <= MAX_PURCHASE, "Can only mint 20 tokens at a time");

        IERC20(lvmhAddress).transferFrom(
            msg.sender,
            masterAddress,
            amount * LVMH_PRICE
        );

        IERC20(septerAddress).transferFrom(
            msg.sender,
            masterAddress,
            amount * SEPTER_PRICE
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

    function changeLvmhAddress(address newlvmhAddress) public onlyOwner {
        lvmhAddress = newlvmhAddress;
    }

    function changeSepterAddress(address newSepterAddress) public onlyOwner {
        septerAddress = newSepterAddress;
    }

    function changeSaleState(bool newSaleState) public onlyOwner {
        saleIsActive = newSaleState;
    }

    function changeMasterAddress(address newMasterAddress) public onlyOwner {
        masterAddress = newMasterAddress;
    }
}
