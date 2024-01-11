// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract ApeInRollCall is ERC1155Supply, Ownable {
    address private _signerAddress = 0x31cF2F62586D6e66df722FC39c2F81Aa2001791c;

    uint256 constant APE_CLAIMABLE = 3000;

    mapping(address => uint256) public claimedAmount;
    uint256 public claimedCounter;
    bool public claimingLive;

    constructor() ERC1155("https://ipfs.io/ipfs/QmUEgzWcqfSak2S7kHqNPCDsxKQ5KFcXaUtayimQ8UDXe5/{id}") {}

    function claim(uint256 claimableAmount, bytes calldata signature) external {
        require(claimingLive, "NOT_LIVE");
        require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, claimableAmount)), signature) == _signerAddress, "INVALID_TRANSACTION");

        uint256 unclaimedAmount = claimableAmount - claimedAmount[msg.sender];
        require(unclaimedAmount > 0, "ALREADY_CLAIMED_MAX");
        require(claimedCounter + unclaimedAmount <= APE_CLAIMABLE, "MAX_CLAIMED");

        claimedAmount[msg.sender] += unclaimedAmount;
        claimedCounter += unclaimedAmount;
        _mint(msg.sender, 3, unclaimedAmount, "");
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function setSignerAddress(address signer) external onlyOwner {
        _signerAddress = signer;
    }

    function toggleClaiming() external onlyOwner {
        claimingLive = !claimingLive;
    }
}