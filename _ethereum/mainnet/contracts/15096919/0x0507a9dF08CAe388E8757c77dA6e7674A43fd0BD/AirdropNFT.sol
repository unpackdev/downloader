// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract AirdropNFT is Ownable {
    using SafeMath for uint256;

    uint256 public commission = 0.00089 ether;
    uint256 public commissionLimit = 3 ether;
    uint256 public maxTxLimit = 200;

    /* options for 50% discount */
    address[] private tokensForDiscount;

    /* list of addresses for no fee */
    address[] private whitelist;

    address public feeAddress = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;

    /* events */
    event AddedToWhitelist(address addr);
    event RemovedFromWhitelist(address addr);

    event AddedToDicountList(address token);
    event RemovedFromDicountList(address token);

    event FeeAddressUpdated(address addr);

    event CommissionUpdated(uint256 amount);
    event CommissionLimitUpdated(uint256 amount);
    event CommissionTxLimitUpdated(uint256 amount);

    constructor() {}

    /* Airdrop Begins */
    function multiTransfer(
        address token,
        address[] calldata addresses,
        uint256[] calldata tokenIds
    ) external payable {
        require(token != address(0x0), "Invalid token");
        require(
            addresses.length <= maxTxLimit,
            "GAS Error: max airdrop limit is 200 addresses"
        );
        require(
            addresses.length == tokenIds.length,
            "Mismatch between address and tokenId"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC721(token).safeTransferFrom(
                msg.sender,
                addresses[i],
                tokenIds[i]
            );
        }

        uint256 fee = estimateServiceFee(token, addresses.length);
        if (fee > 0) {
            require(msg.value == fee, "must send correct fee");

            payable(feeAddress).transfer(fee);
        }
    }

    function estimateServiceFee(address token, uint256 count)
        public
        view
        returns (uint256)
    {
        if (isInWhitelist(msg.sender)) return 0;

        uint256 fee = commission.mul(count);
        if (fee > commissionLimit) fee = commissionLimit;

        if (isInDiscountList(token)) return fee.div(2);

        return fee;
    }

    function addToDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(
            isInDiscountList(token) == false,
            "Already added to token list for discount"
        );

        tokensForDiscount.push(token);

        emit AddedToDicountList(token);
    }

    function removeFromDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(
            isInDiscountList(token) == true,
            "Not exist in token list for discount"
        );

        for (uint256 i = 0; i < tokensForDiscount.length; i++) {
            if (tokensForDiscount[i] == token) {
                tokensForDiscount[i] = tokensForDiscount[
                    tokensForDiscount.length - 1
                ];
                tokensForDiscount[tokensForDiscount.length - 1] = address(0x0);
                tokensForDiscount.pop();
                break;
            }
        }

        emit RemovedFromDicountList(token);
    }

    function isInDiscountList(address token) public view returns (bool) {
        for (uint256 i = 0; i < tokensForDiscount.length; i++) {
            if (tokensForDiscount[i] == token) {
                return true;
            }
        }

        return false;
    }

    function addToWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == false, "Already added to whitelsit");

        whitelist.push(addr);

        emit AddedToWhitelist(addr);
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == true, "Not exist in whitelist");

        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == addr) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist[whitelist.length - 1] = address(0x0);
                whitelist.pop();
                break;
            }
        }

        emit RemovedFromWhitelist(addr);
    }

    function isInWhitelist(address addr) public view returns (bool) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == addr) {
                return true;
            }
        }

        return false;
    }

    function setFeeAddress(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");

        feeAddress = addr;

        emit FeeAddressUpdated(addr);
    }

    function setCommission(uint256 _commission) external onlyOwner {
        require(_commission > 0, "Invalid amount");
        commission = _commission;

        emit CommissionUpdated(_commission);
    }

    function setCommissionLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid amount");
        commissionLimit = _limit;

        emit CommissionLimitUpdated(_limit);
    }

    function setMaxTxLimit(uint256 _txLimit) external onlyOwner {
        require(_txLimit > 0, "Invalid amount");
        maxTxLimit = _txLimit;

        emit CommissionTxLimitUpdated(_txLimit);
    }
}
