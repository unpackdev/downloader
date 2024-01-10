// SPDX-License-Identifier: Copyright 2021 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface ClipperContractInterface {
    function burnToWithdraw(uint256 amount) external;
    function tokenAt(uint i) external view returns (address);
    function nTokens() external view returns (uint);
    function deposit(address sender, uint256[] calldata depositAmounts, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) external;
}

contract OwnedCollectionContract is Ownable {
    using SafeERC20 for IERC20;
    
    address public immutable WRAPPER_CONTRACT;
    address public clipperExchange;

    constructor(address clipperAddress, address wrapperContractAddress) {
        WRAPPER_CONTRACT = wrapperContractAddress;
        clipperExchange = clipperAddress;
    }

    // We want to be able to receive ETH
    receive() external payable {
    }

    function safeEthSend(address recipient, uint256 howMuch) internal {
        (bool success, ) = payable(recipient).call{value: howMuch}("");
        require(success, "Call with value failed");
    }

    function wrapAll() external onlyOwner {
        safeEthSend(WRAPPER_CONTRACT, address(this).balance);
    }

    // Can do:
    // withdrawIntoTokens
    // modifyClipperAddress
    // deposit
    // to move tokens from one pool to another
    function modifyClipperAddress(address newAddress) external onlyOwner {
        clipperExchange = newAddress;
    }

    function deposit(uint256[] calldata depositAmounts, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) external onlyOwner {
        uint i = 0;

        uint n = depositAmounts.length;
        assert(n==ClipperContractInterface(clipperExchange).nTokens());

        while(i < n){
            IERC20(ClipperContractInterface(clipperExchange).tokenAt(i)).safeTransfer(clipperExchange, depositAmounts[i]);
            i++;
        }

        ClipperContractInterface(clipperExchange).deposit(address(this), depositAmounts, nDays, poolTokens, goodUntil, theSignature);
    }

    function withdrawIntoTokens() external onlyOwner {
        uint256 myPoolTokens = IERC20(clipperExchange).balanceOf(address(this));
        ClipperContractInterface(clipperExchange).burnToWithdraw(myPoolTokens);
    }

    // Move my tokens over to specified addresses in specified amounts
    function transfer(address to, uint256 amount) external onlyOwner {
        IERC20(clipperExchange).safeTransfer(to, amount);
    }

    function bulkTransfer(address[] calldata recipients, uint[] calldata amounts) external onlyOwner {
        assert(recipients.length==amounts.length);
        uint i;
        for (i = 0; i < recipients.length; i++) {
            IERC20(clipperExchange).safeTransfer(recipients[i], amounts[i]);
        }
    }

    function tokenEscape(address theToken, address to, uint256 amount) external onlyOwner {
        IERC20(theToken).safeTransfer(to, amount);
    }

}