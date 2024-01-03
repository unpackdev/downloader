//SPDX-License-Identifier: SEE LICENSE FILE
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

/*
 * AlpacaBreeder: stake Alpaca to earn fees from the AlpacaPool
 * Fees can be paid out in PACA or ALPs, but breeder only accepts PACA for now.
 */
contract AlpacaBreeder is ERC20("AlpacaFeeder", "xPACA"){
    using SafeMath for uint256;
    IERC20 public alpaca;   // PACA governance token
    // Warning: alp currently not supported - DO NOT SEND
    IERC20 public alp;      // AlpacaPool shares
    // Period is in blocks. 175,000 blocks ~ 30 days
    // fixed for now, if community wants to change then they can do so through governance
    uint256 public lockBlocks;
    mapping(address => uint256) public timelock;

    constructor (
        IERC20 _alpaca,
        // ,IERC20 _alp
        uint256 _lockBlocks
    )
        public
    {
        alpaca = _alpaca;
        // alp = _alp;
        lockBlocks = _lockBlocks;
    }

    // Bring your Alpaca to the breeder to earn your share of fees
    // Stake PACA and receive shares in the breeder
    function enter(uint256 _amount) public {
        uint256 totalAlpaca = alpaca.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalAlpaca == 0) {
            // initialize share base
            _mint(msg.sender, _amount);
        } else {
            // issue new shares pro rata to existing Alpacas at breeder
            uint256 sharesOut = _amount.mul(totalShares).div(totalAlpaca);
            _mint(msg.sender, sharesOut);
        }
        alpaca.transferFrom(msg.sender, address(this), _amount);

        // set timelock
        // resets every time you deposit, so use a different address if you don't want that
        // timelock[msg.sender] = block.timestamp + lockTime;
        timelock[msg.sender] = block.number.add(lockBlocks);
    }

    // Leave the breeder, exchanging your breeder shares for PACA
    function leave(uint256 _shares) public {
        require(block.number >= timelock[msg.sender],
                "error: cannot leave breeder until end of breeding period");
        uint256 totalShares = totalSupply();
        // redeem shares for Alpacas pro rata to breeder Alpaca holdings
        uint256 alpacaOut = _shares.mul(alpaca.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _shares);
        alpaca.transfer(msg.sender, alpacaOut);
    }

    // convenience function to get unlock block for a particular address
    function getUnlockBlock(address _addr)
        external
        view
        returns (uint256)
    {
        return timelock[_addr];
    }
}