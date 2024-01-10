// SPDX-License-Identifier: MIT

pragma solidity 0.8.3; 

import "Ownable.sol";
import "ERC20.sol";
import "SafeERC20.sol";

interface Locker { // github.com/aurora-is-near/rainbow-token-connector/blob/master/erc20-connector/contracts/ERC20Locker.sol
    function lockToken(address ethToken, uint256 amount, string memory accountId) external;
} 

contract QD is Ownable, ERC20 {
    using SafeERC20 for ERC20;
    
    // NEAR NEP-141s have this precision...
    uint constant internal _QD_DECIMALS = 24;
    uint constant internal _USDT_DECIMALS = 6;

    uint constant public SALE_START = 1646690400; // March 8, midnight GMT +2
    uint constant public MINT_QD_PER_DAY_MAX = 500_000; // half a mil
    uint constant public SALE_LENGTH = 54 days; // '54 - '15, RIP
    
    uint constant public start_price = 22; // in cents
    uint constant public final_price = 96; // 9x6 = 54
    
    // twitter.com/Ukraine/status/1497594592438497282
    address constant public UA = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
    address constant public locker = 0x23Ddd3e3692d1861Ed57EDE224608875809e127f;

    uint private_deposited; uint deposited;
    uint private_price; uint private_minted;

    // Set in constructor and never changed
    address immutable public usdt;

    event Mint (address indexed reciever, uint cost_in_usd, uint qd_amt);
    constructor(address _usdt) ERC20("QuiD", "QD") {
        private_price = 2; // 2 cents
        usdt = _usdt;
    }

    function mint(uint qd_amt, address beneficiary) external returns (uint cost_in_usdt, uint charity) { 
        require(qd_amt >= 100_000_000_000_000_000_000_000_000, "QD: MINT_R1"); // $100 minimum
        require(block.timestamp > SALE_START && block.timestamp < SALE_START + SALE_LENGTH, "QD: MINT_R2");
        if (_msgSender() == owner()) {
            require(private_price < start_price, "Can't allocate any more");
            require(qd_amt == 2_700_000_000_000_000_000_000_000_000_000, "Wrong QD amount entered"); 
            // owner can mint 2.7M ten times to mirror the total (500k * 54d) that public may mint
            cost_in_usdt = qd_amt * 10 ** _USDT_DECIMALS * private_price / 10 ** _QD_DECIMALS / 100; 
            private_deposited += cost_in_usdt;
            private_minted += qd_amt;
            private_price += 2;
        } 
        else { // Calculate cost in USDT based on current price
            cost_in_usdt = qd_amt_to_usdt_amt(qd_amt, block.timestamp);
            charity = cost_in_usdt * 22 / 100;
            deposited += cost_in_usdt - charity;
        }
        // Will revert on failure (namely insufficient allowance)
        ERC20(usdt).safeTransferFrom(_msgSender(), address(this), cost_in_usdt);
        // Optimistically mint
        _mint(beneficiary, qd_amt);
        if (charity > 0) {
            require(totalSupply() - private_minted <= get_total_supply_cap(), "QD: MINT_R3"); // Cap minting
            ERC20(usdt).safeTransfer(UA, charity);
        }
        emit Mint(beneficiary, cost_in_usdt, qd_amt);
    }

    function withdraw() external { // callable by anyone, and only once, after the QD offering ends
        require(deposited > 0 && block.timestamp > SALE_START + SALE_LENGTH, "QD: MINT_R2");
        ERC20(usdt).safeTransfer(owner(), private_deposited);
        ERC20(usdt).approve(locker, deposited);
        Locker(locker).lockToken(usdt, deposited, "quid.near");
        deposited = 0; 
    }

    function decimals() public view override(ERC20) returns (uint8) {
        return uint8(_QD_DECIMALS);
    }

    function get_total_supply_cap() public view returns (uint total_supply_cap) {
        uint time_elapsed = block.timestamp - SALE_START;
        total_supply_cap = MINT_QD_PER_DAY_MAX * 10 ** _QD_DECIMALS * time_elapsed / 1 days;
    }

    function qd_amt_to_usdt_amt(
        uint qd_amt,
        uint block_timestamp
    ) public view returns (uint usdt_amount) 
    {
        uint time_elapsed = block_timestamp - SALE_START;

        // price = ((now - sale_start) // SALE_LENGTH) * (final_price - start_price) + start_price
        uint price = (final_price - start_price) * time_elapsed / SALE_LENGTH + start_price;

        // cost = amount / qd_multiplier * usdt_multipler * price / 100
        usdt_amount = qd_amt * 10 ** _USDT_DECIMALS * price / 10 ** _QD_DECIMALS / 100;
    }
}
