// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract Signet is ERC721Enumerable, Ownable {
    mapping (address => bool) _hasMinted;

    constructor(bytes memory signature) ERC721("The Emperor's Signet", "SIGNET") {
        mintWithSignature(signature);
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmX4RwMwmUs3w14U7KtoxbM33mqvzRBTw3DfYhzoTxcYgC";
    }

    function tokenURI(uint256 /*tokenId*/) public pure override returns (string memory) {
        return contractURI();
    }

    function mint() external {
        require(isValidMinter(msg.sender), "EEEEEEEE not found.");
        require(!_hasMinted[msg.sender], "Already minted with this address.");
        _hasMinted[msg.sender] = true;

        _mint(msg.sender, totalSupply());
    }

    // This is essentially a metatransaction to allow minting from a qualifying
    // address without having to transfer ether to cover gas and then make a
    // separate transaction to transfer the NFT. A standard signature from
    // MetaMask of the string "The Emperor's Signet" will do. This is PURELY to
    // save on gas.
    function mintWithSignature(bytes memory signature) public {
        address signer = getSigner(signature);
        require(isValidMinter(signer), "EEEEEEEE not found.");
        require(!_hasMinted[signer] && !_hasMinted[msg.sender], "Already minted with this address.");
        _hasMinted[signer] = true;
        _hasMinted[msg.sender] = true;

        uint256 tokenId = totalSupply();
        _mint(signer, tokenId);
        _transfer(signer, msg.sender, tokenId);
    }

    // Only the Emperor is allowed to own the royal signet. The Emperor can be
    // identified by his taste in Ethereum addresses. His addresses always
    // contain his initial (E) eight times in a row.
    function isValidMinter(address addr) public pure returns (bool) {
        // Cast the address to a number for easy manipulation
        uint256 a = uint256(uint160(addr));
        uint256 last8Mask = 0xFFFFFFFF;
        uint256 EEEEEEEE = 0xEEEEEEEE;

        // The Es can appear anywhere in the 40-character hex address
        for (uint256 i = 0; i < 32; i++) {
            // Take the last 8 hex characters
            uint256 last8 = a & last8Mask;

            // See if they're all Es
            if (last8 == EEEEEEEE) {
                return true;
            }

            // Otherwise move over a hex character (4 bits)
            a >>= 4;
        }

        // We failed to find eight Es in a row
        return false;
    }

    function isValidSignature(bytes memory signature) public pure returns (bool) {
        return isValidMinter(getSigner(signature));
    }


    function getSigner(bytes memory signature) public pure returns (address) {
        return ECDSA.recover(keccak256("\x19Ethereum Signed Message:\n20The Emperor's Signet"), signature);
    }
}
