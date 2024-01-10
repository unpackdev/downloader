// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./IERC1155Receiver.sol";
import "./AccessControlEnumerable.sol";
import "./SafeMath.sol";
import "./RacerKey.sol";

contract RacerKeySale is IERC1155Receiver, AccessControlEnumerable {
    IERC1155 private RACER_KEY;
    mapping(address => uint256) private _keysPurchased;
    uint256 public constant KEY = 1;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 public salePrice;
    uint256 public maxPurchaseQuantity;
    mapping(address => uint256) public allowedMint;
    uint256 public keysSold = 0;

    constructor(
        address racerKey,
        uint256 price,
        uint256 maxQty
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        RACER_KEY = IERC1155(racerKey);
        salePrice = price;
        maxPurchaseQuantity = maxQty;
    }

    // Manager
    function setSalePrice(uint256 price) public onlyRole(MANAGER_ROLE) {
        salePrice = price;
    }

    function setMaxPurchaseQuantity(uint256 quantity)
        public
        onlyRole(MANAGER_ROLE)
    {
        maxPurchaseQuantity = quantity;
    }

    function burnUnsoldKeys() public onlyRole(MANAGER_ROLE) {
        RacerKey rk = RacerKey(address(RACER_KEY));
        rk.burnUnsoldKeys();
    }

    function withdrawTo(address payable withdrawAddress, uint256 amount)
        public
        onlyRole(MANAGER_ROLE)
    {
        withdrawAddress.transfer(amount);
    }

    function withdrawAllTo(address payable withdrawAddress)
        public
        onlyRole(MANAGER_ROLE)
    {
        withdrawAddress.transfer(address(this).balance);
    }

    function withdrawERC20To(
        address payable withdrawAddress,
        address tokenAddress,
        uint256 amount
    ) public onlyRole(MANAGER_ROLE) {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(withdrawAddress, amount);
    }

    function addToAllowList(address[] memory accounts, uint256[] memory amounts)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(
            accounts.length == amounts.length,
            "arrays must be same length"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            allowedMint[accounts[i]] = amounts[i];
        }
    }

    // Public
    function purchaseKeys(uint256 quantity) public payable {
        uint256 storeBalance = RACER_KEY.balanceOf(address(this), KEY);
        require(storeBalance > 0, "Sorry, all keys have been sold.");
        uint256 maxPurchaseAvailable = allowedMint[msg.sender] >
            maxPurchaseQuantity
            ? allowedMint[msg.sender]
            : maxPurchaseQuantity;
        require(
            _keysPurchased[msg.sender] < maxPurchaseAvailable ||
                allowedMint[msg.sender] > 0,
            "Maximum keys purchased for current sale."
        );

        uint256 availableQty = allowedMint[msg.sender] > 0 &&
            allowedMint[msg.sender] > maxPurchaseQuantity
            ? allowedMint[msg.sender]
            : SafeMath.sub(
                maxPurchaseQuantity,
                _keysPurchased[msg.sender],
                "Max quantity exceeded"
            );
        if (quantity < availableQty) {
            availableQty = quantity;
        }

        require(
            availableQty <= maxPurchaseAvailable ||
                availableQty <= allowedMint[msg.sender],
            "Max quantity exceeded"
        );
        require(
            msg.value >= salePrice * availableQty,
            "Value sent below sale price"
        );

        uint256 sellableQuantity = availableQty;
        uint256 refund = 0;

        if (storeBalance < availableQty) {
            sellableQuantity = storeBalance;
        }

        RACER_KEY.safeTransferFrom(
            address(this),
            msg.sender,
            KEY,
            sellableQuantity,
            ""
        );

        _keysPurchased[msg.sender] += sellableQuantity;
        keysSold += sellableQuantity;

        if (allowedMint[msg.sender] > sellableQuantity) {
            allowedMint[msg.sender] -= sellableQuantity;
        } else {
            allowedMint[msg.sender] = 0;
        }

        if (msg.value > salePrice * sellableQuantity) {
            refund = msg.value - (salePrice * sellableQuantity);
        }

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
