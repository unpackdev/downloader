// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract MINTPSSpotlights is ERC1155Supply, Ownable {
    address private _signerAddress = 0x688d50CB5f6AbB31622404ec9e581CcB6309dD7b;

    uint256 public MAX_CLAIM = 600;
    bool public live;
    mapping(uint16 => bool) public claimed;

    constructor() ERC1155("https://ipfs.io/ipfs/QmcHcBpfKieKtgsTfXSPG26vFC22MBbqQRCX6sBYtNuDsU/{id}") {}

    function verify(address sender, uint16[] calldata tokens, bytes memory signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, tokens));
        return _signerAddress == ECDSA.recover(hash, signature);
    }

    function claim(uint16[] calldata tokens, bytes memory signature) external payable {
        require(live, "NOT_LIVE");
        require(verify(msg.sender, tokens, signature), "INVALID_TRANSACTION");

        uint8 claimAmount;
        for (uint8 i; i < tokens.length; i++) {
            if (claimed[tokens[i]]) continue;
            claimed[tokens[i]] = true;
            claimAmount++;
        }

        require(totalSupply(1) + claimAmount <= MAX_CLAIM, "SOLD_OUT");

        _mint(msg.sender, 1, claimAmount, "");
    }
    
    function toggleLive() external onlyOwner {
        live = !live;
    }

    function setSignerAddress(address signer) external onlyOwner {
        _signerAddress = signer;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }
}