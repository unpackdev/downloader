// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./SlimeProducer.sol";

abstract contract SlimeStore is Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    address private _signer_address;
    SlimeProducer private _slime_producer;

    mapping(string => bool) private _usedNonces;    

    address[] private _founderAddresses = [        
        0x97081ceB16f5Af465122e87b8FA39ab8BCeB5A94,
        0x15Ed267ad25527DF43CAD5669f84Db5a584d0C40,
        0x6B42eECb761DDc75aaFF2B3EcA75052caD4db299,
        0x84f3978072f139f4887983aB70E3CEeF14Df356C
    ];

    uint256 public totalMinted;

    bool public saleLive=true;

    constructor(address producer) {
        _slime_producer = SlimeProducer(producer);
    }

    function getProducer() internal view returns (SlimeProducer) {
        return _slime_producer;
    }
    function getPrice() internal pure virtual returns (uint256);

    function getArtistAddresses() internal view virtual returns (address[] memory);
    
    function getWithdrawRate() internal pure virtual returns (uint256);

    function getMaxMint() internal pure virtual returns (uint256);

    function setSignerAddress(address addr) external onlyOwner {
        _signer_address = addr;
    }

    function getSignerAddress() public view returns (address) {
        return _signer_address;
    }

    function safeMint(address to, uint256 qty) internal {
        SlimeProducer producer = getProducer();
        require(
            totalMinted.add(qty) < producer.maxSupply(),
            "exceeds maximum supply"
        );
        totalMinted = totalMinted + qty;
        for (uint256 i = 0; i < qty; i++) {
            producer.proxyMint(to);
        }
    }

    function hashTransaction(
        address sender,
        uint256 qty,
        string memory nonce
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce))
            )
        );
        return hash;
    }

    function buy(
        bytes32 hash,
        bytes memory signature,
        string memory nonce,
        uint256 tokenQuantity
    ) external payable {
        require(saleLive, "Sale Not Active");
        require(getSignerAddress() != address(0x0), "Signer Not Yet Set");
        require(
            getSignerAddress() == hash.recover(signature),
            "Direct Minting Disallowed"
        );
        require(!_usedNonces[nonce], "Invalid Nonce");
        require(
            hashTransaction(msg.sender, tokenQuantity, nonce) == hash,
            "Signature Failed"
        );
        require(totalMinted.add(tokenQuantity) < getMaxMint(), "Out of Stock");
        require(
            getPrice().mul(tokenQuantity) <= msg.value,
            "Insufficient Funds"
        );
        _usedNonces[nonce] = true;
        safeMint(msg.sender, tokenQuantity);
    }

    function gift(address[] calldata receivers, uint256 tokenQuantity) external onlyOwner {
        require(totalMinted.add(tokenQuantity.mul(receivers.length)) <= getMaxMint(), "Out of Stock");
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], tokenQuantity);
        }
    }

    function withdraw() external onlyOwner {
        address[] memory artists = getArtistAddresses();        
        uint256 share= address(this).balance.mul(getWithdrawRate()).div(100).div(_founderAddresses.length +artists.length);
        for (uint i = 0; i < _founderAddresses.length; i++) {
            payable(_founderAddresses[i]).transfer(share);
        }        
        for (uint i = 0; i < artists.length; i++) {
            payable(artists[i]).transfer(share);
        }
        //in case of remainder, sent to owner
        if (address(this).balance>0){
          payable(msg.sender).transfer(address(this).balance);
        }
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
}
