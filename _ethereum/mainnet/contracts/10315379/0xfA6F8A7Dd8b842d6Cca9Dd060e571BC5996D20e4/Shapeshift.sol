// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
    
contract Shapeshift {
    address private owner;
    bytes32 private vaulthash;
    uint256 private unlockDate;
    event Initialized(uint256 _unlockDate);
    constructor() public {
        owner = msg.sender;
        unlockDate = now + 3 days;
        emit Initialized(unlockDate);
    }
    modifier onlyOwner(){
        require(owner == msg.sender,'unauthorized');
        _;
    }
    function setVault(bytes32 _hash) public onlyOwner {
        vaulthash = _hash;
    } 
    function message() public pure returns( string memory) {
        return "contact me on email@cryptoguard.pw to retrieve";
    }
    function message2() public pure returns( string memory) {
        return "i send an email to security@shapeshift.io but got no response";
    }
    function message3() public pure returns( string memory) {
        return "for safekeeping till time expires";
    }
    function withdraw(address payable _to) public onlyOwner{
        require(unlockDate < now);
        _to.transfer(address(this).balance);
    }
    function withdrawTokens(address _to, IERC20 _token) public onlyOwner{
        require(unlockDate < now);
        _token.transfer(_to, _token.balanceOf(address(this)));
    }
    function getHashOf(string memory _string) public pure returns(bytes32) {
        return keccak256(abi.encode(_string));
    }
    function retrieve(string memory password, address payable _to) public {
        bytes32 hash = keccak256(abi.encode(password));
        require(hash == vaulthash);
        _to.transfer(address(this).balance);
    }
    function retrieveTokens(string memory password, address _to, IERC20 _token) public {
        bytes32 hash = keccak256(abi.encode(password));
        require(hash == vaulthash);
        _token.transfer(_to, _token.balanceOf(address(this)));
    }
    
}