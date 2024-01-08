// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC20.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract RebelKidsStickers is ERC20, Ownable {

    using ECDSA for bytes32;

    address public authorizedSigner;
    uint public globalNonce;
    mapping(address => uint) public userNonce;

    constructor() ERC20("Rebel Kids Stickers", "RBLSTCKRS") {
    }

    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function hashTransaction(address minter, uint stickers, uint nonce) internal pure returns (bytes32) {
        bytes32 dataHash = keccak256(abi.encodePacked(minter, stickers, nonce));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));
    }

    function recoverSignerAddress(address minter, uint stickers, uint nonce, bytes memory signature) internal pure returns (address) {
        bytes32 hash = hashTransaction(minter, stickers, nonce);
        return hash.recover(signature);
    }

    function claim(uint stickers, uint nonce, bytes memory signature) external {
        require(recoverSignerAddress(msg.sender, stickers, nonce, signature) == authorizedSigner, "Unauthorized signer address");
        require(nonce > userNonce[msg.sender] && nonce > globalNonce, "Wrong nonce");
        userNonce[msg.sender] = nonce;
        _mint(msg.sender, stickers);
    }

    function sendTokens(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i]);
        }
    }

    function setSigner(address _authorizedSigner) external onlyOwner {
        authorizedSigner = _authorizedSigner;
    }

    function setGlobalNonce(uint _globalNonce) external onlyOwner {
        globalNonce = _globalNonce;
    }


}