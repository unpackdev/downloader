pragma solidity ^0.8.5;
import "./IAntiBotBlacklist.sol";

abstract contract Blacklist{
    IAntiBotBlacklist _blacklist = IAntiBotBlacklist(0x3a129aaDeF6A34D6E6d1D5e01de82eBd5d98af51);
    modifier antiBot(address _user) {
        require( _blacklist.blacklistCheck(_user),"user is in decentralized blacklist");
        _;
    }
    modifier antiBots(address _user0,address _user1) {
        require( _blacklist.blacklistCheck(_user0),"user0 is in decentralized blacklist");
        require( _blacklist.blacklistCheck(_user1),"user1 is in decentralized blacklist");
        _;
    }
}