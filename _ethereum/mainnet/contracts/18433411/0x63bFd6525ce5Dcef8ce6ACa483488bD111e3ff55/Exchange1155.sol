//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC1155Mintable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";


 contract RAKUZA1155_EXCHANGE is Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    

    // Mitigating Replay Attacks
    mapping(address => mapping(uint256 => bool)) seenNonces;

    // Addresses running auction NFT
    // mapping(address => bool) public whitelistAddress;
    mapping(address => bool) public whitelistNFTAddress;

    struct Data {
        address[5] tradeAddress;
        uint256[5] attributes;
    }

    // Events
    // addrs: from, to, token
    event BuyNFTETH(address[3] addrs, uint256 tokenId, uint256 amount, uint256 price);

     constructor() public {
        
    }

    function setWhitelistNFTAddress(address _address, bool approved) public 
        onlyOwner
    {
        whitelistNFTAddress[_address] = approved;
    }

    modifier verifySignature(
        uint256 nonce,
        address[5] memory _tradeAddress,
        uint256[5] memory _attributes,
        bytes memory signature
    ) {
        // This recreates the message hash that was signed on the client.
        bytes32 hash = keccak256(
            abi.encodePacked(
                msg.sender,
                nonce,
                _tradeAddress,
                _attributes
            )
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        // Verify that the message's signer is the owner of the order
        require(messageHash.recover(signature) == owner(), "Invalid signature");
        require(!seenNonces[msg.sender][nonce], "Used nonce");
        seenNonces[msg.sender][nonce] = true;
        _;
    }

    function checkFeeProductExits(
        address[5] memory _tradeAddress,
        uint256[5] memory _attributes
    ) private returns (uint256 price, uint256 feeOwner, uint256 feeAdmin) {
        uint256 totalFeeTrade;
        // Check fee for owner
        if (_tradeAddress[2] != address(0)) {
            feeOwner = _attributes[0].mul(_attributes[3]).div(1000);
            totalFeeTrade += feeOwner;
        }
        // Check fee for admin
        if (_tradeAddress[3] != address(0)) {
            feeAdmin = _attributes[0].mul(_attributes[4]).div(1000);
            totalFeeTrade += feeAdmin;
        }

        price = _attributes[0].sub(totalFeeTrade);
    }

    // Buy NFT normal by ETH
    // address[5]: buyer, seller, fee, feeAdmin, NFT contract
    // uint256[5]: price, amount, tokenId, feePercent, feePercentAdmin
    function buyNFTETH(
        address[5] memory _tradeAddress,
        uint256[5] memory _attributes,
        uint256 nonce,
        bytes memory signature
    )
        external
        payable
        verifySignature(nonce, _tradeAddress, _attributes, signature)
    {
        Data memory tradeInfo = Data({
            tradeAddress: _tradeAddress,
            attributes: _attributes
        });

        require(
            whitelistNFTAddress[tradeInfo.tradeAddress[4]] == true,
            "NFT is not in whitelist"
        );

        (uint256 price, uint256 feeOwner, uint256 feeAdmin) = checkFeeProductExits(
            tradeInfo.tradeAddress,
            tradeInfo.attributes
        );
        // transfer eth to fee address
        if (feeOwner != 0) {
            TransferHelper.safeTransferETH(tradeInfo.tradeAddress[2], feeOwner);
        }

        // transfer eth to admin address
        if (feeAdmin != 0) {
            TransferHelper.safeTransferETH(tradeInfo.tradeAddress[3], feeAdmin);
        }

        TransferHelper.safeTransferETH(tradeInfo.tradeAddress[1], price);

        ERC1155(tradeInfo.tradeAddress[4]).safeTransferFrom(
            tradeInfo.tradeAddress[1],
            msg.sender,
            tradeInfo.attributes[2],
            tradeInfo.attributes[1],
            ""
        );
        // refund dust eth, if any
        if (msg.value > tradeInfo.attributes[0])
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - tradeInfo.attributes[0]
            );
        emit BuyNFTETH(
            [msg.sender, tradeInfo.tradeAddress[1], tradeInfo.tradeAddress[4]],
            tradeInfo.attributes[2],
            tradeInfo.attributes[1],
            tradeInfo.attributes[0]
        );
    }
}