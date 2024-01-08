pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./console.sol";

contract TokenDispense is Ownable {
    using SafeMath for uint256;
    using Address for address;

    event TokensClaimed(address indexed _address, uint256 tokenAmount);

    mapping(address => bool) claimedAddresses;

    IERC20 mxsToken;
    
    constructor (address mxsTokenAddress) {
        mxsToken = IERC20(mxsTokenAddress);
    }

    function retrieveTokens() external onlyOwner {
        uint256 tokenBalance = mxsToken.balanceOf(address(this));
        mxsToken.transfer(owner(), tokenBalance);
    }

    function claimTokens(bytes memory signature, uint256 tokenAmount) public {
        require(!claimedAddresses[msg.sender], "TokenDispense: Address has already claimed");

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, tokenAmount));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address signer = recoverSigner(ethSignedMessageHash, signature);

        require(signer == owner(), "TokenDispense: Message was not signed by owner");
        
        uint256 tokenBalance = mxsToken.balanceOf(address(this));
        require(tokenBalance > tokenAmount, "TokenDispense: Insufficient balance");

        claimedAddresses[msg.sender] = true;
        mxsToken.transfer(msg.sender, tokenAmount);
        emit TokensClaimed(msg.sender, tokenAmount);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}