// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Errors.sol";
import "./DataType.sol";
import "./LibLaunchpadStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./FixinTokenSpender.sol";


contract LaunchpadFeature is Ownable, ReentrancyGuard, FixinTokenSpender {

    function launchpadBuy(
        bytes4 /* proxyId */,
        bytes4 launchpadId,
        uint256 slotId,
        uint256 quantity,
        uint256[] calldata additional,
        bytes calldata data
    ) external payable nonReentrant {
        require(tx.origin == msg.sender, "contract call not allowed");
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        uint256 maxWhitelistBuy;
        uint256 simulationBuy;
        if (additional.length > DataType.BUY_ADDITIONAL_IDX_WL_MAX_BUY_NUM) {
            maxWhitelistBuy = additional[DataType.BUY_ADDITIONAL_IDX_WL_MAX_BUY_NUM];
        }
        if (additional.length > DataType.BUY_ADDITIONAL_IDX_SIMULATION) {
            simulationBuy = additional[DataType.BUY_ADDITIONAL_IDX_SIMULATION];
        }

        uint256 payableValue = _launchpadBuy(
            launchpadId, slotId, quantity, maxWhitelistBuy, simulationBuy, data
        );
        require(msg.value == payableValue, Errors.LPAD_SLOT_PAY_VALUE_NOT_ENOUGH);

        // simulate buy ok, then revert
        if (simulationBuy > DataType.SIMULATION_NONE) {
            revert(Errors.LPAD_SIMULATE_BUY_OK);
        }
        require(address(this).balance >= ethBalanceBefore, "refund error.");
    }

    function launchpadBuys(DataType.BuyParameter[] calldata parameters) external payable nonReentrant {
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        unchecked {
            uint256 payableValue;
            for (uint256 i; i < parameters.length; i++) {
                payableValue += _launchpadBuy(
                    parameters[i].launchpadId,
                    parameters[i].slotId,
                    parameters[i].quantity,
                    parameters[i].maxWhitelistBuy,
                    DataType.SIMULATION_NONE,
                    parameters[i].data
                );
            }
            require(msg.value == payableValue, Errors.LPAD_SLOT_PAY_VALUE_NOT_ENOUGH);
        }

        require(address(this).balance >= ethBalanceBefore, "refund error.");
    }

    function _launchpadBuy(
        bytes4 launchpadId,
        uint256 slotId,
        uint256 quantity,
        uint256 maxWhitelistBuy,
        uint256 simulationBuy,
        bytes calldata data
    ) internal returns(uint256) {
        require(quantity > 0, "quantity must gt 0");
        require(quantity < type(uint16).max, Errors.LPAD_SLOT_MAX_BUY_QTY_PER_TX_LIMIT);

        DataType.LaunchpadSlot memory slot = _getLaunchpadSlot(launchpadId, slotId);

        (bool success, uint256 alreadyBuyBty) = _getAlreadyBuyBty(slot, msg.sender);
        require(success, "_getAlreadyBuyBty failed");

        // check input param
        if (simulationBuy < DataType.SIMULATION_NO_CHECK_PROCESS_REVERT) {
            _checkLaunchpadBuy(slot, alreadyBuyBty, quantity, maxWhitelistBuy, data, simulationBuy);

            if (simulationBuy == DataType.SIMULATION_CHECK_REVERT) {
                revert(Errors.LPAD_SIMULATE_BUY_OK);
            }
        }

        // Update total sale quantity if needed.
        if (slot.storeSaleQtyFlag) {
            bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
            LibLaunchpadStorage.getStorage().launchpadSlots[key].saleQty += uint32(quantity);
        }

        // Update user buy quantity if needed.
        if (slot.storeAccountQtyFlag) {
            bytes32 key = _getAccountStatKey(launchpadId, slotId, msg.sender);
            LibLaunchpadStorage.getStorage().accountSlotStats[key].totalBuyQty += uint16(quantity);
        }

        uint256 currentPrice = _getCurrentPrice(slot);
        uint256 payableValue = _transferFees(slot, quantity, currentPrice);
        _callLaunchpadBuy(slot, quantity, currentPrice, data);

        return payableValue;
    }

    function _getLaunchpadSlot(bytes4 launchpadId, uint256 slotId) internal view returns(DataType.LaunchpadSlot memory slot) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];

        require(slot.launchpadId == launchpadId, Errors.LPAD_INVALID_ID);
        require(slot.enable, Errors.LPAD_NOT_ENABLE);
        require(uint256(slot.slotId) == slotId, Errors.LPAD_SLOT_IDX_INVALID);
        require(slot.targetContract != address(0), Errors.LPAD_SLOT_TARGET_CONTRACT_INVALID);
        require(slot.mintSelector != bytes4(0), Errors.LPAD_SLOT_ABI_NOT_FOUND);
        if (!slot.storeAccountQtyFlag) {
            require(slot.queryAccountMintedQtySelector != bytes4(0), Errors.LPAD_SLOT_ABI_NOT_FOUND);
        }
    }

    function _getLaunchpadSlotKey(bytes4 launchpadId, uint256 slotId) internal pure returns(bytes32 key) {
        assembly {
            // bytes4(launchpadId) + bytes1(slotId) + bytes27(0)
            key := or(launchpadId, shl(216, and(slotId, 0xff)))
        }
    }

    function _getAccountStatKey(bytes4 launchpadId, uint256 slotId, address account) internal pure returns(bytes32 key) {
        assembly {
            // bytes4(launchpadId) + bytes1(slotId) + bytes7(0) + bytes20(accountAddress)
            key := or(or(launchpadId, shl(216, and(slotId, 0xff))), account)
        }
    }

    function _transferFees(DataType.LaunchpadSlot memory slot, uint256 buyQty, uint256 currentPrice) internal returns(uint256) {
        uint256 shouldPay;
        unchecked {
            shouldPay = buyQty * currentPrice;
        }

        if (slot.paymentToken == address(0)) {
            if (shouldPay > 0) {
                if (slot.feeType == 0 && slot.feeReceipt != address(0)) {
                    _transferEth(slot.feeReceipt, shouldPay);
                }
            }
            return shouldPay;
        } else {
            if (shouldPay > 0) {
                require(slot.feeType == 0, "feeType error");
                require(slot.feeReceipt != address(0), "feeReceipt error");
                _transferERC20From(slot.paymentToken, msg.sender, slot.feeReceipt, shouldPay);
            }
            return 0;
        }
    }

    function _callLaunchpadBuy(DataType.LaunchpadSlot memory slot, uint256 buyQty, uint256 currentPrice, bytes calldata data) internal {
        uint256 price;
        // if paymentToken == ETH and need pay to targetContract, set pay price.
        if (slot.paymentToken == address(0) && slot.feeType != 0) {
            price = currentPrice;
        }

        // Get extraData
        uint256 extraOffset;
        // Skip whiteList signData if on whiteList stage
        if (
            slot.whiteListModel != DataType.WhiteListModel.NONE &&
            (slot.whiteListSaleStart == 0 || block.timestamp < slot.saleStart)
        ) {
            extraOffset = 65;
        }
        if (data.length < extraOffset) {
            revert("extra_data error");
        }

        bytes4 selector = slot.mintSelector;
        address targetContract = slot.targetContract;

        // mintParams
        //      0: mint(address to, extra_data)
        //      1: mint(address to, uint256 quantity, extra_data)
        if (slot.mintParams == 0) {
            assembly {
                let extraLength := sub(data.length, extraOffset)
                let calldataLength := add(0x24, extraLength)
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), caller())
                if extraLength {
                    calldatacopy(add(ptr, 0x24), add(data.offset, extraOffset), extraLength)
                }

                for { let i } lt(i, buyQty) { i := add(i, 1) } {
                    if iszero(call(gas(), targetContract, price, ptr, calldataLength, ptr, 0)) {
                        // Failed, copy the returned data and revert.
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        } else if (slot.mintParams == 1) {
            assembly {
                let extraLength := sub(data.length, extraOffset)
                let calldataLength := add(0x44, extraLength)
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), buyQty)
                if extraLength {
                    calldatacopy(add(ptr, 0x44), add(data.offset, extraOffset), extraLength)
                }

                if iszero(call(gas(), targetContract, mul(buyQty, price), ptr, calldataLength, ptr, 0)) {
                    // Failed, copy the returned data and revert.
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        } else {
            revert(Errors.LPAD_SLOT_ABI_NOT_FOUND);
        }
    }

    function _getAlreadyBuyBty(
        DataType.LaunchpadSlot memory slot,
        address account
    ) internal view returns(
        bool success,
        uint256 alreadyBuyBty
    ) {
        if (slot.storeAccountQtyFlag) {
            bytes32 key = _getAccountStatKey(slot.launchpadId, slot.slotId, account);
            return (true, LibLaunchpadStorage.getStorage().accountSlotStats[key].totalBuyQty);
        } else {
            bytes4 selector = slot.queryAccountMintedQtySelector;
            address targetContract = slot.targetContract;
            assembly {
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), account)

                if staticcall(gas(), targetContract, ptr, 0x24, ptr, 0x20) {
                    if eq(returndatasize(), 0x20) {
                        success := 1
                        alreadyBuyBty := mload(ptr)
                    }
                }
            }
            return (success, alreadyBuyBty);
        }
    }

    function _getCurrentPrice(DataType.LaunchpadSlot memory slot) internal view returns(uint256) {
        unchecked {
            if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
                return slot.price * (10 ** slot.priceUint);
            } else if (slot.whiteListSaleStart > 0) { // first whiteList sale, then public sale
                uint256 price = (block.timestamp < slot.saleStart) ? slot.pricePresale : slot.price;
                return price * (10 ** slot.priceUint);
            } else { // whiteList sale
                uint256 price = slot.price > 0 ? slot.price : slot.pricePresale;
                return price * (10 ** slot.priceUint);
            }
        }
    }

    function _checkLaunchpadBuy(
        DataType.LaunchpadSlot memory slot,
        uint256 alreadyBuyBty,
        uint256 buyQty,
        uint256 maxWhitelistBuy,
        bytes calldata data,
        uint256 simulateBuy
    ) internal view {
        unchecked {
            if (slot.storeSaleQtyFlag) {
                // max supply check
                if (slot.saleQty + buyQty > uint256(slot.maxSupply)) {
                    revert(Errors.LPAD_SLOT_QTY_NOT_ENOUGH_TO_BUY);
                }
            }

            // endTime check
            require(block.timestamp < slot.saleEnd, Errors.LPAD_SLOT_SALE_END);

            if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
                // startTime check
                if (block.timestamp < slot.saleStart) {
                    if (simulateBuy != DataType.SIMULATION_CHECK_SKIP_START_PROCESS_REVERT) {
                        revert(Errors.LPAD_SLOT_SALE_NOT_START);
                    }
                }
                // buy num check
                if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                    revert(Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT);
                }
            } else {
                // whitelist check
                if (simulateBuy == DataType.SIMULATION_CHECK_SKIP_WHITELIST_PROCESS_REVERT) {
                    return;
                }

                if (slot.whiteListSaleStart > 0) { // first whiteList sale, then public sale
                    // check startTime
                    if (block.timestamp < slot.whiteListSaleStart) {
                        if (simulateBuy != DataType.SIMULATION_CHECK_SKIP_START_PROCESS_REVERT) {
                            revert(Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START);
                        }
                    }
                    if (block.timestamp < slot.saleStart) { // on whiteList sale
                        // buy num check
                        if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                            revert(Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT);
                        }
                    } else { // on public sale
                        // buy num check
                        if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                            revert(Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT);
                        }
                        return;
                    }
                } else { // whiteList sale
                    // startTime check
                    if (block.timestamp < slot.saleStart) {
                        if (simulateBuy != DataType.SIMULATION_CHECK_SKIP_START_PROCESS_REVERT) {
                            revert(Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START);
                        }
                    }
                    // buy num check
                    if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                        revert(Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT);
                    }
                }

                // off chain sign model, check the signature and max buy num
                require(_offChainSignCheck(slot, msg.sender, maxWhitelistBuy, data), Errors.LPAD_SLOT_ACCOUNT_NOT_IN_WHITELIST);
            }
        }
    }

    // off-chain sign check
    function _offChainSignCheck(
        DataType.LaunchpadSlot memory slot,
        address account,
        uint256 maxBuyNum,
        bytes calldata signature
    ) internal view returns (bool success) {
        if (signature.length >= 65) {
            if (slot.signer == address(0)) {
                return false;
            }

            uint256 slotId = uint256(slot.slotId);
            bytes32 hash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(account, address(this), slot.launchpadId, slotId, maxBuyNum))
                )
            );

            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := calldataload(signature.offset)
                s := calldataload(add(signature.offset, 0x20))
                v := byte(0, calldataload(add(signature.offset, 0x40)))
            }
            return (ecrecover(hash, v, r, s) == slot.signer);
        }
        return false;
    }

    function isInWhiteList(
        bytes4 launchpadId,
        uint256 slotId,
        address[] calldata accounts,
        uint256[] calldata offChainMaxBuy,
        bytes[] calldata offChainSign
    ) external view returns (uint8[] memory wln) {
        wln = new uint8[](accounts.length);

        // off-chain sign check
        if (offChainSign.length > 0) {
            require(accounts.length == offChainMaxBuy.length && accounts.length == offChainSign.length, Errors.LPAD_INPUT_ARRAY_LEN_NOT_MATCH);

            bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
            DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];

            for (uint256 i; i < accounts.length; i++) {
                if (_offChainSignCheck(slot, accounts[0], offChainMaxBuy[i], offChainSign[i])) {
                    wln[i] = uint8(offChainMaxBuy[i]);
                }
            }
        }
    }

    // hash for whitelist
    function hashForWhitelist(
        address account,
        bytes4 launchpadId,
        uint256 slot,
        uint256 maxBuy
    ) external view returns (bytes32) {
        return keccak256(abi.encodePacked(account, address(this), launchpadId, slot, maxBuy));
    }

    // get launchpad info
    function getLaunchpadInfo(bytes4 /* proxyId */, bytes4 launchpadId, uint256[] calldata /* params */) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        address[] memory addressData,
        bytes[] memory bytesData
    ) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, 0);
        DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];

        boolData = new bool[](2);
        boolData[0] = slot.enable;
        boolData[1] = slot.enable;

        bytesData = new bytes[](1);
        bytesData[0] = abi.encodePacked(slot.launchpadId);

        addressData = new address[](3);
        addressData[0] = address(0); // controllerAdmin
        addressData[1] = address(this); // AssetProxyAddress
        // feeReceipt
        if (slot.feeType == 0) {
            addressData[2] = slot.feeReceipt != address(0) ? slot.feeReceipt : address(this);
        } else {
            addressData[2] = slot.targetContract;
        }

        uint256 slotsNum = 1;
        uint256 feesNum = 1;
        intData = new uint256[](4 + feesNum + slotsNum * 2);
        intData[0] = slotsNum;
        intData[1] = feesNum;
        intData[2] = 0; // ctlPermission
        intData[3] = 0; // referralFeePct
        intData[4] = 10000; // feePercent

        // getLaunchpadInfo is override function, can't change returns value, so use fees uint256[] as saleQuantity, openNum
        for (uint256 i = 5; i < intData.length; i += 2) {
            intData[i] = slot.saleQty;
            intData[i + 1] = 0;
        }
    }

    // get launchpad slot info
    function getLaunchpadSlotInfo(bytes4 /* proxyId */, bytes4 launchpadId, uint256 slotId) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        address[] memory addressData,
        bytes4[] memory bytesData
    ) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];
        if (launchpadId == 0 || launchpadId != slot.launchpadId || slotId != slot.slotId) {
            return (boolData, intData, addressData, bytesData); // invalid id or idx, return nothing
        }

        boolData = new bool[](6);
        boolData[0] = slot.enable; // launchpad enable
        boolData[1] = true; // can buy

        intData = new uint256[](13);
        intData[0] = uint256(slot.saleStart); // sale start
        intData[1] = uint256(slot.whiteListModel); // whitelist model, 0-no whitelist; 2-whitelist
        intData[2] = uint256(slot.maxSupply); // max supply
        intData[3] = uint256(slot.saleQty); // sale quantity
        intData[4] = uint256(slot.maxBuyQtyPerAccount); // maxBuyQtyPerAccount
        intData[5]  = _getCurrentPrice(slot);
        intData[6] = 0; // boxOpenStart
        intData[7] = 0; // startTokenId
        intData[8] = 0; // openedNum
        intData[9] = uint256(slot.saleEnd); // saleEnd
        intData[10] = uint256(slot.whiteListSaleStart); // whiteListSaleStart
        intData[11] = uint256(slot.pricePresale * (10 ** slot.priceUint)); // presale price
        intData[12] = uint256(slot.price * (10 ** slot.priceUint)); // public sale price

        addressData = new address[](3);
        addressData[0] = slot.paymentToken; // buyToken
        addressData[1] = slot.targetContract; // targetContract
        addressData[2] = address(this); // Element ERC20AssetProxy

        bytesData = new bytes4[](2);
        bytesData[0] = slot.mintSelector;
        bytesData[1] = slot.queryAccountMintedQtySelector;
    }

    function getAlreadyBuyBty(
        address account,
        bytes4 launchpadId,
        uint256 slotId
    ) external view returns (uint256) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];
        if (launchpadId == 0 || launchpadId != slot.launchpadId || slotId != slot.slotId) {
            return 0;
        }

        (, uint256 alreadyBuyBty) = _getAlreadyBuyBty(slot, account);
        return alreadyBuyBty;
    }

    function getAccountInfoInLaunchpad(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 slotId,
        uint256 quantity
    ) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        bytes[] memory byteData
    ) {
        (
            boolData,
            intData,
            byteData
        ) = getAccountInfoInLaunchpadV2(msg.sender, proxyId, launchpadId, slotId, quantity);
        return (boolData, intData, byteData);
    }

    function getAccountInfoInLaunchpadV2(
        address account,
        bytes4 /* proxyId */,
        bytes4 launchpadId,
        uint256 slotId,
        uint256 quantity
    ) public view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        bytes[] memory byteData
    ) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];
        if (launchpadId == 0 || launchpadId != slot.launchpadId || slotId != slot.slotId) {
            return(boolData, intData, byteData); // invalid id or idx, return nothing
        }

        // launchpadId check
        boolData = new bool[](4);
        if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
            boolData[0] = false; // whitelist model or not
            boolData[3] = false; // whitelist model or not
        } else {
            boolData[0] = true; // whitelist model or not
            boolData[3] = !(slot.whiteListSaleStart != 0 && block.timestamp >= slot.saleStart); // whitelist model or not
        }

        intData = new uint256[](6);
        intData[0] = slot.saleQty; // totalBuyQty
        // intData[1] // left buy quantity
        intData[2] = 0; // next buy time of this address

        // this whitelist user max can buy quantity
        intData[3] = (slot.whiteListModel == DataType.WhiteListModel.NONE) ? 0 : (quantity >> 128);
        quantity = uint256(quantity & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF); // low 128bit is the quantity want to buy

        // intData[1] - left buy quantity
        (, uint256 alreadyBuyBty) = _getAlreadyBuyBty(slot, account);
        if (boolData[3]) {
            intData[1] = (intData[3] > alreadyBuyBty) ? (intData[3] - alreadyBuyBty) : 0;
        } else {
            intData[1] = uint256(slot.maxBuyQtyPerAccount) - alreadyBuyBty;
        }

        byteData = new bytes[](2);
        byteData[1] = bytes("Do not support openBox");
        if (account != address(0)) {
            if (quantity > 0) {
                // check buy param
                byteData[0] = bytes(
                    _checkLaunchpadBuyWithoutRevert(
                        slot, alreadyBuyBty, quantity, intData[3]
                    )
                );
            }

            uint256 paymentNeeded = quantity * _getCurrentPrice(slot);
            if (slot.paymentToken != address(0)) { // ERC20
                // user balance now
                intData[4] = IERC20(slot.paymentToken).balanceOf(account);
                // use balance is enough
                boolData[1] = intData[4] >= paymentNeeded;
                // user has approved
                boolData[2] = IERC20(slot.paymentToken).allowance(account, address(this)) >= paymentNeeded;
            } else { // ETH
                // user balance now
                intData[4] = account.balance;
                // use balance is enough
                boolData[1] = intData[4] > paymentNeeded;
                // user has approved
                boolData[2] = true;
            }

            if (account == slot.signer) {
                intData[5] = DataType.ROLE_LAUNCHPAD_SIGNER; // whitelist signer
            } else if (account == slot.feeReceipt) {
                intData[5] = DataType.ROLE_LAUNCHPAD_FEE_RECEIPTS; // whitelist signer
            } else if (
                account == owner() ||
                LibLaunchpadStorage.getStorage().administrators[account]
            ) {
                intData[5] = DataType.ROLE_PROXY_OWNER; // admin
            }
        } else {
            byteData[0] = bytes(Errors.OK);
        }
    }

    function _checkLaunchpadBuyWithoutRevert(
        DataType.LaunchpadSlot memory slot,
        uint256 alreadyBuyBty,
        uint256 buyQty,
        uint256 maxWhitelistBuy
    ) internal view returns(string memory errCode) {
        if (!slot.enable) {
            return Errors.LPAD_NOT_ENABLE;
        }
        if (slot.targetContract == address(0)) {
            return Errors.LPAD_SLOT_TARGET_CONTRACT_INVALID;
        }
        if (slot.mintSelector == bytes4(0)) {
            return Errors.LPAD_SLOT_ABI_NOT_FOUND;
        }
        if (!slot.storeAccountQtyFlag) {
            if (slot.queryAccountMintedQtySelector == bytes4(0)) {
                return Errors.LPAD_SLOT_ABI_NOT_FOUND;
            }
        }
        if (slot.storeSaleQtyFlag) {
            if ((slot.saleQty + buyQty) > uint256(slot.maxSupply)) {
                return Errors.LPAD_SLOT_QTY_NOT_ENOUGH_TO_BUY;
            }
        }
        if (block.timestamp >= slot.saleEnd) {
            return Errors.LPAD_SLOT_SALE_END;
        }
        if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
            if (block.timestamp < slot.saleStart) {
                return Errors.LPAD_SLOT_SALE_NOT_START;
            }
            if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                return Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT;
            }
        } else {
            if (slot.whiteListSaleStart > 0) { // first whiteList sale, then public sale
                if (block.timestamp < slot.whiteListSaleStart) {
                    return Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START;
                }
                if (block.timestamp < slot.saleStart) {
                    if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                        return Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT;
                    }
                } else {
                    if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                        return Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT;
                    }
                }
            } else {
                if (block.timestamp < slot.saleStart) {
                    return Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START;
                }
                if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                    return Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT;
                }
            }
        }
        return Errors.OK;
    }
}
