//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./INFT.sol";

import "./ECDSA.sol";
import "./Ownable.sol";

contract CardborgMinter is Ownable {
    using ECDSA for bytes32;

    uint16 public constant perAddrBuyLimit = 10;

    uint16 public devMinted;
    uint16 public whitelistLimit = 800;
    uint16 public whitelistMinted;
    uint16 public payMintLimit = 1200;
    uint16 public totalPayMinted;

    uint chainId;

    mapping(address => bool) public isMinted; // for whitelist
    mapping(address => uint) public payMinted; 

    address public signer;
    address public nft;
    uint public price = 0.02 ether;
    uint public payMintUntil = type(uint256).max;

    event SignerChanged(address signer);

    constructor(address _nft) {
        nft = _nft;
        signer = msg.sender;
        chainId = block.chainid;
    }

    function mint(address user, uint16 quantity) external payable {
        require(block.timestamp >= payMintUntil, "not start");
        require(totalPayMinted + quantity <= payMintLimit, "Over payMintLimit");
        require(payMinted[user] + quantity <= perAddrBuyLimit, "Over BuyLimit");

        refundIfOver(price * uint256(quantity));
        
        payMinted[user] += quantity;
        totalPayMinted += quantity;
        INFT(nft).mint(user, quantity);
    }  

    function devMint(address user, uint16 quantity) external onlyOwner {
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

    function setPayPriceAndLimit(uint _price, uint16 _payMintLimit) external onlyOwner {
        price = _price;
        payMintLimit = _payMintLimit;
    }

    function setWhitelistLimit(uint16 _limit)  external onlyOwner {
        whitelistLimit = _limit;
    }

    function setPayMintUntil(uint _until) external onlyOwner {
        payMintUntil = _until;
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