//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./INFT.sol";

import "./ECDSA.sol";
import "./Ownable.sol";

contract TVHeadXMinter is Ownable {
    using ECDSA for bytes32;

    uint16 public constant devLimit = 10;
    uint16 public devMinted;
    uint16 public constant whitelistLimit = 20;
    uint16 public whitelistMinted;
    mapping(address => bool) public isMinted; // for whitelist

    uint chainId;

    uint16 public payWhitelistMinted;
    mapping(address => bool) public isPayMinted;

    address public signer;
    address public nft;
    uint public price = 0.1 ether;

    event SignerChanged(address signer);

    constructor(address _nft) {
        nft = _nft;
        signer = msg.sender;
        chainId = block.chainid;
    }

    function mint(address user, uint16 quantity) external payable {
    } 

    function payWhitelistMint(bytes calldata sig) external payable {
        address user = msg.sender;
        require(!isPayMinted[user], "aleady minted");
        require(verify(user, 2, sig), "signature unmatch");

        payWhitelistMinted += 1;
        isPayMinted[user] = true;

        refundIfOver(price);
        INFT(nft).mint(user, 1);
    }  

    function devMint(address user, uint16 quantity) external onlyOwner {
        require(devMinted + quantity <= devLimit, "Over Dev Limit");
        devMinted += quantity;
        
        INFT(nft).mint(user, quantity);
    }

    function whitelistMint(bytes calldata sig) external {
        require(whitelistMinted < whitelistLimit, "Over Whitelist Limit");

        address user = msg.sender;
        require(!isMinted[user], "aleady minted");
        require(verify(user, 1, sig), "signature unmatch");

        whitelistMinted += 1;
        isMinted[user] = true;

        INFT(nft).mint(user, 1);
    }


    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
        emit SignerChanged(_signer);
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function verify(address sender, uint sigtype, bytes memory sig) internal view returns (bool) {
        bytes32 hashStruct = keccak256(abi.encode(sender, sigtype, chainId, address(this)));
        return recover(hashStruct, sig) == signer;
    }

    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(sig);
    }

    function refundIfOver(uint256 spend) private {
        require(msg.value >= spend, "Need to send more ETH");

        if (msg.value > spend) {
            payable(msg.sender).transfer(msg.value - spend);
        }
    }




}