pragma solidity ^0.5.17;

interface IERC20Token {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract WdxReferralWithdraw {
    IERC20Token public tokenContract;
    address owner;
    
    constructor(IERC20Token _tokenContract) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
    }
    
    function get_wdx (uint8 v, bytes32 r, bytes32 s, uint numberOfTokens) public returns (bool) {
        bytes32 msgh = keccak256(abi.encodePacked(msg.sender));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgh));
        require(ecrecover(prefixedHash, v, r, s) == 0x3f3140632657b79FB3716e9852F6697bda9db677, "Incorrect admin wallet");
        
        require(numberOfTokens > 0, "You need to get at least some tokens");
        
        tokenContract.transfer(address(msg.sender), numberOfTokens);
    }
}