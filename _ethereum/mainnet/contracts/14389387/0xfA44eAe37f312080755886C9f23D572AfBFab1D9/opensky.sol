// contracts/closesky.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";



contract CloseSky is Ownable {
    bool public _isPaused = false;

    /// The account who have the rights to sign trade data
    address public _verifier;

    /// The account who receive platform fee
    address public _platformAccount;

    event Trade(address token, uint256 tokenId, address from, address to, uint256 value, uint256 closesky_fee);
    
    constructor() {
        _verifier = msg.sender;
        _platformAccount = msg.sender;
    }

    function trade(address token, uint256 tokenId, address payable from, address to, uint256 value, uint256 closeSkyFee, uint256 deadline, bytes32 r, bytes32 s, uint8 v) public payable notPaused {
        // 1. Check if the signature is valid
        requireValidSign(token, tokenId, from, to, value, closeSkyFee, deadline, r, s, v);
        require(msg.value >= value, "CloseSky: Insufficient input value");
        require(block.timestamp < deadline, "CloseSky: Deadline exceeded");

        require(closeSkyFee < msg.value, "CloseSky: closeSkyFee must less than value");

        // 2. Calc the seller got amount
        uint256 sellerValue = msg.value - closeSkyFee;

        // 3. Actual transfer
        payable(_platformAccount).transfer(closeSkyFee);
        from.transfer(sellerValue);

        address nftOwner = IERC721(token).ownerOf(tokenId);

        require(nftOwner == from, "CloseSky: from is not owner");

        IERC721(token).transferFrom(nftOwner, to, tokenId);

        // 4. Done
        emit Trade(token, tokenId, from, to, value, closeSkyFee);
    }


    function requireValidSign(address token, uint256 tokenId, address from, address to, uint256 value, uint256 closeSkyFee, uint256 deadline, bytes32 r, bytes32 s, uint8 v) public view {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory userPacked = abi.encodePacked(token, tokenId, from, to, value, closeSkyFee, deadline);
        bytes32 userHash = keccak256(userPacked);
        bytes memory finalPacked = abi.encodePacked(prefix, userHash);
        bytes32 finalHash = keccak256(finalPacked);
        
        address hash_address = ecrecover(finalHash, v, r, s);
        require(hash_address == _verifier, "CloseSky: Invalid signature");
    }

    function setPause(bool isPause) public onlyOwner {
        _isPaused = isPause;
    }

    function setVerifierAddress(address verifier) public onlyOwner {
        _verifier = verifier;
    }

    function setPlatformAccount(address account) public onlyOwner {
        _platformAccount = account;
    }

    modifier notPaused() {
        if (_isPaused == true) {
            revert("CloseSky: Contract Paused");
        }
        _;
    }
} 
