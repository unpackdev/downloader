// SPDX-License-Identifier: MIT

pragma solidity 0.8.3; 

import "Ownable.sol";
import "ERC20.sol";
import "SafeERC20.sol";

interface ILocker { // github.com/aurora-is-near/rainbow-token-connector/blob/master/erc20-connector/contracts/ERC20Locker.sol
    function lockToken(address ethToken, uint256 amount, string memory accountId) external;
} 

contract QD is Ownable, ERC20 {
    using SafeERC20 for ERC20;
    event Mint (address indexed reciever, uint cost_in_usd, uint qd_amt);
    // NEAR NEP-141s have this precision...
    uint constant internal _QD_DECIMALS = 24;
    uint constant internal _USDT_DECIMALS = 6;
    uint constant public PRICE_PRECISION = 1e18;
    uint constant public start_price = 22 * PRICE_PRECISION / 100;
    uint constant public final_price = 96 * PRICE_PRECISION / 100; // 9x6 = 54
    uint constant public SALE_START = 1647388800; // EOD Ides of March in GMT
    uint constant public SALE_LENGTH = 54 days;
    uint constant public MINT_QD_PER_DAY_MAX = 500_000; 
    // twitter.com/Ukraine/status/1497594592438497282
    address constant public UA = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
    uint public private_price = 6 * PRICE_PRECISION / 100; // 6th sense
    uint public private_deposited;
    uint public public_deposited;
    uint public private_minted;
    // Set in constructor and never changed
    address immutable public usdt;
    address immutable public locker;
    
    constructor(address _usdt, address _locker) ERC20("QuiD", "QD") {
        private_minted = 5_400_000_000_000_000_000_000_000_000_000;
        _mint(_msgSender(), private_minted);
        locker = _locker;
        usdt = _usdt;
    }

    function mint(uint qd_amt, address beneficiary) external returns (uint cost_in_usdt, uint charity) { 
        require(qd_amt >= 100_000_000_000_000_000_000_000_000, "QD: MINT_R1"); // $100 minimum
        require(block.timestamp >= SALE_START && block.timestamp < SALE_START + SALE_LENGTH, "QD: MINT_R2");
        if (_msgSender() == owner()) {
            require(private_price < start_price, "Can't allocate any more");
            require(qd_amt == 2_700_000_000_000_000_000_000_000_000_000, "Wrong QD amount entered"); 
            // owner can mint 2.7M ten times to mirror the total (500k * 54d) that public may mint
            cost_in_usdt = qd_amt * 10 ** _USDT_DECIMALS * private_price / PRICE_PRECISION / 10 ** _QD_DECIMALS; 
            private_deposited += cost_in_usdt;
            private_minted += qd_amt;
            private_price += 2 * PRICE_PRECISION / 100;
        } 
        else { // Calculate cost in USDT based on current price
            cost_in_usdt = qd_amt_to_usdt_amt(qd_amt, block.timestamp);
            charity = cost_in_usdt * 22 / 100;
            public_deposited += cost_in_usdt - charity;
        }
        _mint(beneficiary, qd_amt); // Optimistically mint
        require(totalSupply() - private_minted <= get_total_supply_cap(block.timestamp), "QD: MINT_R3"); // Cap minting
        ERC20(usdt).safeTransferFrom(_msgSender(), address(this), cost_in_usdt); // reverts on failure (e.g. allowance)
        if (charity > 0) {
            ERC20(usdt).safeTransfer(UA, charity);
        }
        emit Mint(beneficiary, cost_in_usdt, qd_amt);
    }

    function withdraw() external { // callable by anyone, and only once, after the QD offering ends
        require(public_deposited > 0 && block.timestamp >= SALE_START + SALE_LENGTH, "QD: WITHDRAW_R1");
        ERC20(usdt).safeTransfer(owner(), private_deposited);
        ERC20(usdt).approve(locker, public_deposited);
        ILocker(locker).lockToken(usdt, public_deposited, "quid.near");
        public_deposited = 0; 
    }

    function qd_amt_to_usdt_amt(uint qd_amt, uint block_timestamp) public pure returns (uint usdt_amount) {
        uint price = calculate_price(block_timestamp);
        // cost = amount / qd_multiplier * usdt_multipler * price
        usdt_amount = qd_amt * 10 ** _USDT_DECIMALS * price / PRICE_PRECISION / 10 ** _QD_DECIMALS;
    }

    function calculate_price( uint block_timestamp) public pure returns (uint price){
        uint time_elapsed = block_timestamp - SALE_START;
        // price = ((now - sale_start) // SALE_LENGTH) * (final_price - start_price) + start_price
        price = (final_price - start_price) * time_elapsed / SALE_LENGTH + start_price;
    }

    function get_total_supply_cap(uint block_timestamp) public pure returns (uint total_supply_cap) {
        uint time_elapsed = block_timestamp - SALE_START;
        total_supply_cap = MINT_QD_PER_DAY_MAX * 10 ** _QD_DECIMALS * time_elapsed / 1 days;
    }

    function decimals() public pure override(ERC20) returns (uint8) {
        return uint8(_QD_DECIMALS);
    }
}