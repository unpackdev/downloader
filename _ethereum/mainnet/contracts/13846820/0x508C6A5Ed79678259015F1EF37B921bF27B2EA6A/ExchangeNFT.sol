//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC721.sol";
import "./IStableToken.sol";
import "./ECDSA.sol";
import "./TransferHelper.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract ExchangeNFT is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for ERC20;

    address public ERC721;

    // Address is owner of ERC721
    address public admin;

    // Mitigating Replay Attacks
    mapping(address => mapping(uint256 => bool)) seenNonces;

    // Addresses running auction NFT
    mapping(address => bool) public whitelistAddress;

    // Events
    // addrs: from, to, token
    event BuyNFTNormal(address[3] addrs, uint256 tokenId, uint256 amount);
    event BuyNFTETH(address[3] addrs, uint256 tokenId, uint256 amount);
    event AuctionNFT(address[3] addrs, uint256 tokenId, uint256 amount);
    event AcceptOfferNFT(address[3] addrs, uint256 tokenId, uint256 amount);

    constructor(address _erc721) public {
        ERC721 = _erc721;
        whitelistAddress[msg.sender] = true;
        admin = msg.sender;
    }

    function setNFTAddress(address _nft) public onlyOwner {
        ERC721 = _nft;
    }

    function setWhitelistAddress(address _address, bool approved)
        public
        onlyOwner
    {
        whitelistAddress[_address] = approved;
    }

    function setAdminAddress(address _admin) public onlyOwner {
        admin = _admin;
    }

    modifier verifySignature(
        uint256 nonce,
        address[4] memory _tradeAddress,
        uint256[3] memory _attributes,
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
        address feeAddress,
        uint256[3] memory _attributes
    ) internal pure returns (uint256 amount, uint256 feeProduct) {
        amount = _attributes[0];
        // Check fee address exits
        if (feeAddress != address(0)) {
            feeProduct = (_attributes[0] * _attributes[2]) / 100;
            amount = _attributes[0] - feeProduct;
        }
    }

    // Buy NFT normal by token ERC-20
    // address[4]: buyer, seller, token, fee
    // uint256[3]: amount, tokenId, feePercent
    function buyNFTNormal(
        address[4] memory _tradeAddress,
        uint256[3] memory _attributes,
        uint256 nonce,
        bytes memory signature
    ) external verifySignature(nonce, _tradeAddress, _attributes, signature) {
        // check allowance of buyer
        require(
            IERC20(_tradeAddress[2]).allowance(msg.sender, address(this)) >=
                _attributes[0],
            "token allowance too low"
        );
        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(
            _tradeAddress[3],
            _attributes
        );

        if (feeProduct != 0) {
            // transfer token to fee address
            ERC20(_tradeAddress[2]).safeTransferFrom(
                msg.sender,
                _tradeAddress[3],
                feeProduct
            );
        }
        // transfer token from buyer to seller
        ERC20(_tradeAddress[2]).safeTransferFrom(
            msg.sender,
            _tradeAddress[1],
            amount
        );
        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            msg.sender,
            _attributes[1]
        );
        emit BuyNFTNormal(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }

    // Buy NFT normal by ETH
    // address[3]: buyer, seller, token, fee
    // uint256[2]: amount, tokenId, feePercent
    function buyNFTETH(
        address[4] memory _tradeAddress,
        uint256[3] memory _attributes,
        uint256 nonce,
        bytes memory signature
    )
        external
        payable
        verifySignature(nonce, _tradeAddress, _attributes, signature)
    {
        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(
            _tradeAddress[3],
            _attributes
        );
        // transfer token to fee address
        if (feeProduct != 0) {
            TransferHelper.safeTransferETH(_tradeAddress[3], feeProduct);
        }
        TransferHelper.safeTransferETH(_tradeAddress[1], amount);

        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            msg.sender,
            _attributes[1]
        );
        // refund dust eth, if any
        if (msg.value > _attributes[0])
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - _attributes[0]
            );
        emit BuyNFTETH(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }

    // Auction NFT
    // address[4]: buyer, seller, token, fee
    // uint256[2]: amount, tokenId, feePercent
    function auctionNFT(
        address[4] memory _tradeAddress,
        uint256[3] memory _attributes
    ) external {
        // Check address execute auction
        require(
            whitelistAddress[msg.sender] == true,
            "Address is not in whitelist"
        );
        // check allowance of buyer
        require(
            IERC20(_tradeAddress[2]).allowance(
                _tradeAddress[0],
                address(this)
            ) >= _attributes[0],
            "token allowance too low"
        );
        if (_tradeAddress[1] == admin) {
            require(
                IERC721(ERC721).isApprovedForAll(admin, address(this)),
                "tokenId do not approve for contract"
            );
        } else {
            require(
                IERC721(ERC721).getApproved(_attributes[1]) == address(this),
                "tokenId do not approve for contract"
            );
        }

        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(
            _tradeAddress[3],
            _attributes
        );
        if (feeProduct != 0) {
            // transfer token to fee address
            ERC20(_tradeAddress[2]).safeTransferFrom(
                _tradeAddress[0],
                _tradeAddress[3],
                feeProduct
            );
        }

        // transfer token from buyer to seller
        ERC20(_tradeAddress[2]).safeTransferFrom(
            _tradeAddress[0],
            _tradeAddress[1],
            amount
        );
        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            _tradeAddress[0],
            _attributes[1]
        );
        emit AuctionNFT(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }

    // Accept offer from buyer
    // address[4]: buyer, seller, token, fee
    // uint256[3]: amount, tokenId, feePercent
    function acceptOfferNFT(
        address[4] memory _tradeAddress,
        uint256[3] memory _attributes,
        uint256 nonce,
        bytes memory signature
    ) external verifySignature(nonce, _tradeAddress, _attributes, signature) {
        require(
            IERC721(ERC721).getApproved(_attributes[1]) == address(this),
            "tokenId do not approve for contract"
        );
        // check allowance of buyer
        require(
            IERC20(_tradeAddress[2]).allowance(
                _tradeAddress[0],
                address(this)
            ) >= _attributes[0],
            "token allowance too low"
        );

        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(
            _tradeAddress[3],
            _attributes
        );
        if (feeProduct != 0) {
            // transfer token to fee address
            ERC20(_tradeAddress[2]).safeTransferFrom(
                _tradeAddress[0],
                _tradeAddress[3],
                feeProduct
            );
        }

        // transfer token from buyer to seller
        ERC20(_tradeAddress[2]).safeTransferFrom(
            _tradeAddress[0],
            msg.sender,
            amount
        );

        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            _tradeAddress[0],
            _attributes[1]
        );
        emit AcceptOfferNFT(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }
}
