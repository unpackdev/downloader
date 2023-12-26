// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";

contract Ox33labs is ERC721A, Ownable {
    string private _metadataURI;
    
    uint256 constant public MAX_SUPPLY = 333;
    uint256 public price = 0.015 ether;
    address public signer;
    bool public open;

    constructor(address signer_) ERC721A("0x33labs", "KEYS") Ownable(msg.sender) {
        _mint(msg.sender, 10);
        signer = signer_;
    }

    function mint(bytes memory signature_, uint256 expiry_) external payable  {
        require(msg.sender == tx.origin, "Nop");
        require(msg.value == price, "Invalid price");
        require(open, "Closed");
        require(_totalMinted() < MAX_SUPPLY, "No supply left");
        require(expiry_ > block.timestamp, "Signature expired");

        bytes32 message = keccak256(abi.encode(msg.sender, expiry_));
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(message);
        
        (address recovered, ECDSA.RecoverError error, ) = ECDSA.tryRecover(hash, signature_);

        require(error == ECDSA.RecoverError.NoError && recovered == signer, "Invalid signature");

        require(_numberMinted(msg.sender) == 0, "Reached maximum allowed per address");
        
        _mint(msg.sender, 1);
    }

    function tokenURI(uint256 id_)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(id_)) revert URIQueryForNonexistentToken();

        return bytes(_metadataURI).length != 0 ? string(abi.encodePacked(_metadataURI, _toString(id_), ".json")) : "";
    }

    function toggleOpen() external onlyOwner {
        open = !open;
    }

    function setMetadataURI(string memory metadataURI_) external onlyOwner {
        _metadataURI = metadataURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );

        require(success);
    }
}