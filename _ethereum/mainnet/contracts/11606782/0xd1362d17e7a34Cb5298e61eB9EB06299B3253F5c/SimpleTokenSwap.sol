// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw() external;
}

// Demo contract that swaps its ERC20 balance for another ERC20.
// NOT to be used in production.
contract SimpleTokenSwap {

    struct Swap {
        // The `sellTokenAddress` field from the API response.
        IERC20 sellToken;
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken;
        // The `allowanceTarget` field from the API response.
        address spender;
        // The `to` field from the API response.
        address payable swapTarget;
        // The `data` field from the API response.
        bytes swapCallData;
    }

    event BoughtTokens(IERC20 sellToken, IERC20 buyToken, uint256 boughtAmount);

    // The WETH contract.
    IWETH public immutable WETH;
    // Creator of this contract.
    address public owner;

    constructor(IWETH weth) {
        WETH = weth;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(IERC20 token, uint256 amount)
    external
    onlyOwner
    {
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH(uint256 amount)
    external
    onlyOwner
    {
        msg.sender.transfer(amount);
    }

    // Transfer ETH into this contract and wrap it into WETH.
    function depositETH()
    external
    payable
    {
        WETH.deposit{value: msg.value}();
    }

    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.



    function fillMultiQuote(Swap memory swap1, Swap memory swap2)
    external
    onlyOwner
    payable // Must attach ETH equal to the `value` field from the API response.
    {
        
        require(swap1.sellToken.approve(swap1.spender, uint256(-1)), 'Approve call failed 1');
        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success,) = swap1.swapTarget.call{value: msg.value}(swap1.swapCallData);
        require(success, 'SWAP_CALL_FAILED');
        // Refund any unspent protocol fees to the sender.
        // msg.sender.transfer(address(this).balance);
        
        
        // Give `spender` an infinite allowance to spend this contract's `sellToken`.
        // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
        // allowance to 0 before being able to update it.
        require(swap2.sellToken.approve(swap2.spender, uint256(-1)), 'Approve call failed 2');
        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success1,) = swap2.swapTarget.call{value: address(this).balance}(swap2.swapCallData);
        require(success1, 'SWAP_CALL_FAILED_2');
        // Refund any unspent protocol fees to the sender.

        msg.sender.transfer(address(this).balance);
        
        
    }
    
    function fillQuote(Swap memory swap)
    external
    onlyOwner
    payable // Must attach ETH equal to the `value` field from the API response.
    {
        // Give `spender` an infinite allowance to spend this contract's `sellToken`.
        // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
        // allowance to 0 before being able to update it.
        require(swap.sellToken.approve(swap.spender, uint256(-1)), 'Approve call failed 1');
        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success,) = swap.swapTarget.call{value: msg.value}(swap.swapCallData);
        require(success, 'SWAP_CALL_FAILED');
        // Refund any unspent protocol fees to the sender.
        msg.sender.transfer(address(this).balance);
    }
}