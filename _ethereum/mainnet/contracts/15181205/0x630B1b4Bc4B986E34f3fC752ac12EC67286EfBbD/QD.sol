// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; 
// pragma experimental SMTChecker;

import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "IERC721.sol";
import "ERC20.sol";
import "Ownable.sol";
interface ICollection is IERC721 { 
    function latestTokenId() external view returns (uint256);
} 
contract QD is Ownable, ERC20, ReentrancyGuard {
    using SafeERC20 for ERC20;
    uint public sale_start;
    uint public minted;
    uint public raised;
    uint public _VERSION; 

    uint constant internal _USDT_DECIMALS = 6;
    uint constant public PRECISION = 1e18;
    
    uint constant public SALE_LENGTH = 54 days; 
    uint constant public MAX_QD_PER_DAY = 777_777;
    uint constant public delta = 101_010_000_000_000_18;
    uint constant public start_price = 44 * PRECISION / 100; // not 44B, Elon
    uint constant public slice = 1_111_111_000_000_000_000_000_018; // pie 🍕 
    
    address constant public SUKC_ETH = 0x42cc020Ef5e9681364ABB5aba26F39626F1874A4;
    address constant public F8N = 0x13B09CBc96aA378A04D4AFfBdF2116cEab14056b;
    address constant public UA = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
    // twitter.com/Ukraine/status/1497594592438497282
    address immutable public tether; // never changes
    
    mapping (uint => address) public redeemed;
    mapping (uint => Outcome) private _outcomes; 
    mapping (uint => mapping(address => uint)) private _qd;
    mapping (uint => mapping(address => uint)) private _spent;

    event Withdraw (address indexed reciever, uint amt_usd, uint qd_amt);
    event Mint (address indexed reciever, uint cost_in_usd, uint qd_amt);
    enum Outcome { IDK, SUKCETH, FAILT }

    constructor(address _usdt) ERC20("QU!D", "QD") {
        sale_start = 1658777777; // July 25th, 2022 
        // in 1658, New Amsterdam police force forms
        _mint(SUKC_ETH, slice); // for...mirror (QP) 
        _outcomes[1] = Outcome.IDK; // we'll see 🤞
        _VERSION = 1;
        tether = _usdt;
    }
    function withdraw() external nonReentrant {
        if (block.timestamp > sale_start + SALE_LENGTH) {
            if (_outcomes[_VERSION] == Outcome.IDK) { 
                if (owner() != SUKC_ETH) {
                    if (owner() != address(0)) { // clementine...misbehaviour
                        ERC20(tether).safeTransfer(owner(), 10_000_000_000);
                    } // thank you, cum again...
                    _transferOwnership(SUKC_ETH); // elect Dr. Schleppr 
                }
                if (raised > 23_000_000_000_000) { // 23 flavors 🌶
                    ERC20(tether).safeTransfer(owner(), raised);
                    _outcomes[_VERSION] = Outcome.SUKCETH;
                } else {
                    _outcomes[_VERSION] = Outcome.FAILT;
                }
                minted = 0;
                raised = 0;
            }
        }
        uint total_refund;
        uint total_mint;
        for (uint i = 1; i <= _VERSION; i++) {
            if (_outcomes[i] == Outcome.SUKCETH) { // land the rebates
                uint amount = _qd[i][_msgSender()];
                if (amount > 0) {
                    total_mint += amount;
                    delete(_qd[i][_msgSender()]);
                }
                uint spent = _spent[i][_msgSender()];
                if (spent > 0) {
                    delete(_spent[i][_msgSender()]);
                }
            } 
            else if (_outcomes[i] == Outcome.FAILT) { // like Kickstarter
                uint refund = _spent[i][_msgSender()];
                if (refund > 0) {
                    total_refund += refund;
                    delete(_spent[i][_msgSender()]);
                }
                uint amount = _qd[i][_msgSender()];
                if (amount > 0) {
                    delete(_qd[i][_msgSender()]);
                }
            }
        }
        if (total_refund > 0) {
            ERC20(tether).safeTransfer(_msgSender(), total_refund);
        }
        if (total_mint > 0) {
            _mint(_msgSender(), total_mint);
        }
    }
    function mint(uint qd_amt, address beneficiary) external nonReentrant returns (uint cost, uint paid, uint aid) {  
        if (qd_amt == slice) {
            qd_amt = 0;
            if (_msgSender() == SUKC_ETH) {
                cost = 466_666 * 10 ** _USDT_DECIMALS; // call pops on money phone
                ERC20(tether).safeTransferFrom(_msgSender(), address(this), cost);
                
                qd_amt = slice;
                raised += cost;

                sale_start = block.timestamp;
                _VERSION += 1;
            } else if (beneficiary != SUKC_ETH) {
                uint latest = ICollection(F8N).latestTokenId();
                for (uint i = 1; i <= latest; i++) {
                    if (beneficiary == ICollection(F8N).ownerOf(i)) {
                        if (redeemed[i] == address(0)) {
                            redeemed[i] = beneficiary;
                            qd_amt += slice;
                        }
                    }
                }
            }
            _mint(beneficiary, qd_amt);
        } 
        else {
            require(block.timestamp >= sale_start, "QD: MINT_R2"); 
            require(beneficiary != address(0), "ERC20: mint to the zero address");
            require(qd_amt >= 1_000_000_000_000_000_000_000, "QD: MINT_R1"); // 1 rack minimum...for a t-shirt
            require(get_total_supply_cap(block.timestamp) >= qd_amt, "QD: MINT_R3"); // supply cap for minting
            
            cost = qd_amt_to_usdt_amt(qd_amt, block.timestamp); 
            aid = cost * 22 / 100; // 🇺🇦,🇺🇦
            paid = cost - aid;
            
            ERC20(tether).safeTransferFrom(_msgSender(), address(this), cost);
            ERC20(tether).safeTransfer(UA, aid); // must happen after above
                
            minted += qd_amt;
            raised += paid;

            _qd[_VERSION][beneficiary] += qd_amt;
            _spent[_VERSION][_msgSender()] += paid;
        }
        if (qd_amt > 0) {
            emit Mint(beneficiary, cost, qd_amt);
            emit Transfer(address(0), beneficiary, qd_amt);
        }
    }
    function get_total_supply_cap(uint block_timestamp) public view returns (uint total_supply_cap) {
        uint in_days = ((block_timestamp - sale_start) / 1 days) + 1; // off by one due to rounding
        total_supply_cap = in_days * MAX_QD_PER_DAY * PRECISION;
        if (block_timestamp <= sale_start + SALE_LENGTH) {
            return total_supply_cap - minted;
        }   return 0;
    }
    function qd_amt_to_usdt_amt(uint qd_amt, uint block_timestamp) public view returns (uint usdt_amount) {
        uint price = (qd_amt / PRECISION) * calculate_price(block_timestamp);
        usdt_amount = (price * 10 ** _USDT_DECIMALS) / PRECISION ;
    }
    function calculate_price( uint block_timestamp) public view returns (uint price) {
        uint in_days = ((block_timestamp - sale_start) / 1 days) + 1;
        price = in_days * delta + start_price;
    }
    function balanceOf(address account, uint version) public view returns (uint256) {
        return _qd[_VERSION][account];
    }
    function totalSupply(uint version) public view returns (uint256) {
        return minted;
    }
}
