// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./DepositInterface.sol";
import "./UniERC20.sol";

// Simple router
contract CollectionContract {
    using UniERC20 for ERC20;
    
    address public immutable clipperPool;
    address public immutable clipperDeposit;
    address constant CLIPPER_ETH_SIGIL = address(0);

    modifier poolOwnerOnly() {
        require(msg.sender == Ownable(clipperPool).owner(), "Only Clipper Pool owner");
        _;
    }

    constructor(address poolAddress, address depositAddress) {
        clipperPool = poolAddress;
        clipperDeposit = depositAddress;
    }
    
    // We want to be able to receive ETH
    receive() external payable {
    }

    // Deposit -> Transfer token percentage to Clipper Pool, then call deposit
    function deposit(uint256 percentageToDeposit, uint nDays) public poolOwnerOnly {
        require(percentageToDeposit <= 100, "Invalid percentage to transfer");
        
        ERC20 the_token;
        uint i = 0;
        uint n = PoolInterface(clipperPool).nTokens();
        uint256 toTransfer;

        while(i < n){
            the_token = ERC20(PoolInterface(clipperPool).tokenAt(i));
            toTransfer = (percentageToDeposit*the_token.uniBalanceOf(address(this)))/100;
            the_token.uniTransfer(clipperPool, toTransfer);
            i++;
        }

        the_token = ERC20(CLIPPER_ETH_SIGIL);
        toTransfer = (percentageToDeposit*the_token.uniBalanceOf(address(this)))/100;
        the_token.uniTransfer(clipperPool, toTransfer);

        DepositInterface(clipperDeposit).deposit(nDays);
    }

    // Can leave public
    function unlock() public {
        DepositInterface(clipperDeposit).unlockVestedDeposit();
    }

    // Move my tokens over to specified addresses in specified amounts
    function transfer(address to, uint256 amount) public poolOwnerOnly {
        ERC20(clipperPool).uniTransfer(to, amount);
    }

    function bulkTransfer(address[] calldata recipients, uint[] calldata amounts) public poolOwnerOnly {
        assert(recipients.length==amounts.length);
        uint i;
        for (i = 0; i < recipients.length; i++) {
            ERC20(clipperPool).uniTransfer(recipients[i], amounts[i]);
        }
    }

}