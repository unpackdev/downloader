// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ReentrancyGuard.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "Controlled.sol";
import "ISuperBidNFT.sol";


contract RedeemCtl is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    ISuperBidNFT nft;
    address public signedBy;

    constructor(address _signedBy, ISuperBidNFT _nft) {
        signedBy = _signedBy;
        nft = _nft;
    }

    function mint(uint256 _id, address _owner, string memory _url, uint256 _deadline, bytes memory signature) external nonReentrant {
        address sender = _msgSender();
        require(_deadline >= block.timestamp, "RedeemCtl: past deadline");
        bytes32 hashed = keccak256(abi.encode(block.chainid, _id, _owner, _deadline, keccak256(bytes(_url))));
        (address _signedBy,) = hashed.tryRecover(signature);
        require(signedBy == _signedBy, "RedeemCtl: invalid signature");
        nft.mint(_id, _owner, _url);
    }

    function rotateSignedBy(address _newSigner) external onlyOwner {
        signedBy = _newSigner;
    }

    function time() external view returns (uint256) {
        return block.timestamp;
    }
}