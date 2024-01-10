// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC20.sol";
import "./Ownable.sol";

contract GUMP is ERC20, Ownable {

    address private daoAddress = 0xD509AD2af3356cE1Df748cfd5BCA19Ad1b199f7c;
    address public swapPoolAddress;

    mapping(address => bool) public exemptFee;
    mapping(address => address) public inviter;

    address[] public shareHolders;
    mapping(address => bool) private inShareHolders;
    uint256 public shareHolderIndex;

    uint256 public dividendLimite = 1000 * 10 ** 9;


    //ERC20
    //=========================================================================
    constructor() ERC20("The Myth of America", "GUMP") {
        uint256 initialSupply = 7200 * 10**8 * 10**9;
        _mint(msg.sender, initialSupply);
        
        exemptFee[msg.sender] = true;
        exemptFee[daoAddress] = true;
        exemptFee[address(this)] = true;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }


    //Data Set
    //=========================================================================
    function setExemptFee(address account, bool isExempt) public onlyOwner {
        exemptFee[account] = isExempt;
    }

    function setSwapPool(address pool) public onlyOwner {
        swapPoolAddress = pool;
    }

    function setDividendLimite(uint256 limite) public onlyOwner {
        dividendLimite = limite;
    }

    function inviterUpdate(address from, address to, uint256 toBalance) private {
        if (toBalance != 0 || inviter[to] != address(0)) {
            return;
        }

        if (from.code.length == 0 && to.code.length == 0) {
            inviter[to] = from;
        }
    }

    function shareHoldersUpdate(address shareholder) private {
        if ((shareholder == address(this)) || (shareholder == swapPoolAddress)) {
            return;
        }

        if (inShareHolders[shareholder]) {
            return;
        }

        if (IERC20(swapPoolAddress).balanceOf(shareholder) > 0) {
            shareHolders.push(shareholder);
            inShareHolders[shareholder] = true;
        }
    }

    function shareHoldersLength() public view returns(uint256) {
        return shareHolders.length;
    }


    //Hook function
    //=========================================================================
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        //Calculate balance in advance
        uint256 toBalance = balanceOf(to);

        if (swapPoolAddress == address(0)) {
            super._transfer(from, to, amount);
            inviterUpdate(from, to, toBalance);
            return;
        }

        if (exemptFee[from] || exemptFee[to] || to == swapPoolAddress) {
            super._transfer(from, to, amount);
        } else {
            uint256 totalFee = amount / 10;
            uint256 arrivalAmount = amount - totalFee;
            super._transfer(from, to, arrivalAmount);

            //1.burn 1/10
            uint256 burnAmount = totalFee / 10;
            super._burn(from, burnAmount);

            //2.dao 1/10
            uint256 daoAmount = totalFee / 10;
            super._transfer(from, daoAddress, daoAmount);

            //3.inviter，Max 7/10
            uint256 inviterFee = 0;
            if (from == swapPoolAddress) {
                address cur = to;
                for(uint8 i = 0; i < 7; i++) {
                    cur = inviter[cur];
                    if (cur == address(0)) {
                        break;
                    }

                    if (i == 0) {
                        uint256 tmp = (totalFee / 10) * 3;
                        super._transfer(from, cur, tmp);
                        inviterFee += tmp;
                    } else if (i == 1 || i == 2) {
                        uint256 tmp = totalFee / 10;
                        super._transfer(from, cur, tmp);
                        inviterFee += tmp;
                    } else {
                        uint256 tmp = totalFee / 20;
                        super._transfer(from, cur, tmp);
                        inviterFee += tmp;
                    }
                }
            }

            //4.Dividend pool，1/10 —— 8/10
            super._transfer(from, address(this), (totalFee - burnAmount - daoAmount - inviterFee));
        }

        
        //Dividend
        IERC20 swapPool = IERC20(swapPoolAddress);
        uint256 poolTotalSupply = swapPool.totalSupply();
        if(balanceOf(address(this)) >= dividendLimite && from != address(this) && shareHolders.length > 0 && poolTotalSupply > 0) {
            for (int256 i = 0; i < 2; i++) {
                if (shareHolderIndex >= shareHolders.length) {
                    shareHolderIndex = 0;
                    break;
                }

                address shareHolder = shareHolders[shareHolderIndex];
                
                uint256 dividend = dividendLimite * swapPool.balanceOf(shareHolder) / poolTotalSupply;

                if (dividend >= 1 * 10**9 && balanceOf(address(this)) >= dividend) {
                    super._transfer(address(this), shareHolder, dividend);
                }

                shareHolderIndex++;
            }
        }

        //Update
        inviterUpdate(from, to, toBalance);
        shareHoldersUpdate(from);
        shareHoldersUpdate(to);
    }
}