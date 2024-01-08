// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
███████╗ ██████╗  ██████╗ ██╗     ███████╗     ██████╗  ██████╗ ██╗     ██████╗ 
██╔════╝██╔═══██╗██╔═══██╗██║     ██╔════╝    ██╔════╝ ██╔═══██╗██║     ██╔══██╗
█████╗  ██║   ██║██║   ██║██║     ███████╗    ██║  ███╗██║   ██║██║     ██║  ██║
██╔══╝  ██║   ██║██║   ██║██║     ╚════██║    ██║   ██║██║   ██║██║     ██║  ██║
██║     ╚██████╔╝╚██████╔╝███████╗███████║    ╚██████╔╝╚██████╔╝███████╗██████╔╝
╚═╝      ╚═════╝  ╚═════╝ ╚══════╝╚══════╝     ╚═════╝  ╚═════╝ ╚══════╝╚═════╝ 
                                                                                
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣶⣿⣿⣿⣿⣶⣦⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⢣⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠸⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡿⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣿⡇ ⠀⠀⠀⠀⠀ ⠀ ⠀   ⠀⠀ ⠀⠀⢀⣼⠂
⠀ ⢿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⢱⣿⡿⠿⠿⣿⣿⣿⣿⣿⡿⠿⠿⢿⣷⡜⣿⠀⠀⠀⠀ ⠀⠀⠀ ⠀ ⠀ ⠀⠀⠀⣠⣾⡟⠀
 ⠀⠈⢿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣯⢸⣿⠀⠀⠀⠀⢸⣿⣿⡁⠀⠀⠀⠈⣿⡇⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⢀⣴⣿⡟⠀⠀
⠀ ⠀⠈⢻⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⣺⣿⡆⠀⢀⣤⣾⡇⢹⣷⣄⡀⠀⣸⣿⡇⠋⠀⠀⠀⠀ ⠀⠀   ⠀⠀⠀⣠⣾⣿⡟⠀⠀⠀
⠀⠀ ⠀⠀⠻⣿⣿⣧⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⡟⠁⠘⢿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀ ⠀⠀ ⠀⠀⣠⣾⣿⣿⠏⠀⠀⠀⠀
⠀⠀⠀ ⠀⠀⠙⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⡉⠙⣿⣿⣷⣾⣷⣾⣿⣿⠉⢉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⡿⠃⠀⠀⠀⠀⠀
⠀⠀⠀⠀ ⠀⠀⠈⠻⣿⣿⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⠀⠸⣿⠀⢻⢿⡿⣿⡿⣿⡿⡏⢀⣿⠃⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀ ⠀⠀⠀⠈⢿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀⠀⢀⣿⡀⠉⠸⠇⠿⠇⠸⠇⠏⢸⣿⠀⠀⠀⠀⠀⠀⣀⣾⣿⣿⣿⣿⠿⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠈⠻⣿⣿⣬⡙⢷⣤⡀⠀⠀⠈⢿⣷⣤⣷⣰⣇⣼⣀⣷⣠⣾⠟⠀⠀⠀⣀⣴⡾⢋⣴⣿⡿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠙⢿⣿⣶⣝⠻⣷⣦⣄⡀⠙⠻⣿⣿⣿⣿⣿⣿⠟⠁⢀⣠⣴⡿⢟⣩⣾⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣷⣦⣉⠻⣿⣶⣤⣀⠀⠀⠀⠀⣠⣴⣾⡿⠟⣩⣶⣿⡿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⣀⣀⣀⠀⠀⠀⠀⠀⠙⠻⢿⣿⣦⣌⣛⠿⢿⣷⣾⣿⣟⣛⣡⣶⣿⠿⠛⠉⠀⠀⠀⠀⠀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣷⣆⠀⠀⠀⠀⢀⣀⣬⣿⣿⣿⣷⣶⣭⣙⠻⠿⣿⣿⣿⣥⣀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠘⠻⠟⠉⠻⣿⣧⡲⣾⣿⠿⢟⣛⣫⣵⣶⣿⡿⠟⠻⢿⣿⣶⣬⣝⣛⡻⠿⣿⣷⢖⣾⣿⠏⠙⠻⠟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀ ⠀⢠⣶⣿⣷⣞⣿⣦⢺⣦⢿⣦⢹⣿⣿⢢⣶⣿⣿⠿⠛⠋⠉⠀⠀⠀⠀⠀⠈⠉⠙⠻⠿⣿⣿⣶⡐⣿⣿⢇⣾⣟⣶⣆⣴⣿⣷⣾⣿⣶⡀⠀⠀⠀
⠀⠀⠀ ⠸⣿⣿⡿⢃⡹⠿⠿⠿⠿⠿⠇⢿⣿⠘⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠃⣿⡟⠸⠿⠿⠿⠿⠿⣃⡙⢿⣿⣿⠃⠀⠀⠀
⠀⠀⠀⠀ ⠉⠛⠛⠋⠀⠀⠀⠀⠀⠀⠀⠸⣿⣶⣶⣶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣶⣶⣾⣿⠃⠀⠀⠀⠀⠀⠀⠈⠙⠛⠛⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⡿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

website: https://foolsgold.money
telegram: https://t.me/FoolsGoldVerify
twitter: https://twiter.com/FoolsGoldERC
discord: https://discord.gg/uEbTCCeF8F
TikTok: https://www.tiktok.com/@foolsgolderc?lang=en
*/

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract FoolsGold is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    
    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    uint256 private _totalSupply = 500_000_000_000_000 * 10 ** decimals();
    uint256 public maxWalletLimit = 15_000_000_000_000 * 10 ** decimals();
    uint256 public Fee = 3;

    mapping(address => bool) _isExempt;  

    address public feeReceiver = _msgSender();
    address public pair;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor()
        ERC20("FoolsGold", "FGOLD")
        ERC20Permit("FoolsGold")
        Ownable(_msgSender()) {	
        _mint(_msgSender(), 500_000_000_000_000 * 10 ** decimals());
        _isExempt[address(this)] = true;
        _isExempt[_msgSender()] = true;
        _isExempt[DEAD] = true;
        _isExempt[ZERO] = true;
        _approve(address(_msgSender()), address(router), type(uint256).max);
    }

    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */
    function transfer(address to, uint256 value) public override returns (bool) {
        address from = _msgSender();
        _fees(from, to, value);
	    return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _fees(from, to, value);
        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function isExempt(address account) public view returns (bool) {
        return _isExempt[account];
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function updateFeeReceiver(address newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
        _approve(address(msg.sender), address(feeReceiver), type(uint256).max);
        _isExempt[feeReceiver] = true;
    }

    function setIsExempt(address account) external onlyOwner {
        _isExempt[account] = true;
    }

    function setPair(address pairAddress) external onlyOwner {
        pair = pairAddress;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */
    function _fees(address from, address to, uint256 value) private {
        if (from == pair && !_isExempt[to]) {
            require(balanceOf(to) + value <= maxWalletLimit, "You are exceeding maxWalletLimit");
        }
        if (from != pair && !_isExempt[to] && !_isExempt[from]) {
            if (from != feeReceiver) {
                if (to != pair) {
                    require(balanceOf(to) + value <= maxWalletLimit, "You are exceeding maxWalletLimit");
                }
            }
        }     
        uint256 feeAmount;
        if (_isExempt[from] || _isExempt[to]) {
            feeAmount = 0;
        } else {
            feeAmount = (value * Fee) / 100;
        }
        super._transfer(from, to, value-feeAmount);
        if (feeAmount > 0) {
            super._transfer(from, feeReceiver, feeAmount);
        }     
    }
}
