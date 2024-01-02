//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
    https://t.me/JATWerc20
    https://x.com/JATWerc20
    https://jatw.org/
    
    $TURBO holders, hold tight! Jingle All the Way ($JATW) airdrop incoming,
    unlocking exclusive NFTs & community perks.
    Be more than a holder, join the mememovement! 
    #JingleAllTheWay #TurboFam #NFTCommunity
*/
import "./ERC20.sol";

contract Turbo is ERC20{

    uint256 constant AVAILABLE_AMOUNT = 107580000 ether;
    uint256 constant LOCKED_AMOUNT = 112420000 ether;
    uint256 immutable unlockAt;
    address immutable unlocker;

    constructor() ERC20("JingleAllTheWay", "TURBO"){
        _mint(msg.sender, AVAILABLE_AMOUNT);
        _mint(address(this), LOCKED_AMOUNT);
        unlockAt = block.timestamp + 31536000;
        unlocker = msg.sender;
    }

    function unlockTokens() public{
        require((msg.sender == unlocker) && (block.timestamp >= unlockAt));
        _update(address(this), unlocker, LOCKED_AMOUNT);
    }
}
