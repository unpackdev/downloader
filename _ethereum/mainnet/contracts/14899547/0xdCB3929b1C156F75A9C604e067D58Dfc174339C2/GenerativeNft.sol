// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./SharedConfig.sol";
import "./SharedLogic.sol";

contract GenerativeNft is
    SharedLogic,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    EIP712Upgradeable,
    UUPSUpgradeable
{
    function initialize(address config) external initializer {
        __ERC721_init("GenerativeNft", "MGN");
        __EIP712_init("GenerativeNftEIP712", "0.0.2");
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _config = config;
    }

    function setConfig(address config) external onlyOwner {
        require(config != address(0), "Invalid config");
        _config = config;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    SharedConfig(_config)._nftHost(),
                    "/api/v1/generative-nfts/",
                    StringsUpgradeable.toString(tokenId),
                    "/metadata"
                )
            );
    }

    // For opensea.io to display contract metadata
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(SharedConfig(_config)._nftHost(), "/api/v1/contracts/GenerativeNft/metadata"));
    }

    // API

    function redeem(
        address sellerAddress,
        uint256 tokenId,
        uint256 price,
        bytes calldata signature
    ) external payable virtual {
        address buyerAddress = _msgSender();
        address signerAddress = _verifySignature(sellerAddress, tokenId, price, signature);
        _processPayment(msg.value, price, sellerAddress);
        _mintGenerativeNft(signerAddress, buyerAddress, tokenId);
    }

    // Implementation

    function _verifySignature(
        address sellerAddress,
        uint256 tokenId,
        uint256 price,
        bytes calldata signature
    ) internal view virtual returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("GenerativeNftSignData(address sellerAddress,uint256 tokenId,uint256 price)"),
                    sellerAddress,
                    tokenId,
                    price
                )
            )
        );
        address signerAddress = ECDSAUpgradeable.recover(digest, signature);
        require(SharedConfig(_config)._signer() == signerAddress, "Invalid signature");

        return signerAddress;
    }

    function _processPayment(
        uint256 moneySend,
        uint256 price,
        address sellerAddress
    ) internal virtual {
        require(moneySend >= price, "Insufficient funds to redeem");

        uint256 platformFee = (price / PERCENTAGE) * SharedConfig(_config)._feePercentMintingGenerativeNfts();
        uint256 sellerAmount = price - platformFee;

        if (platformFee > 0) {
            // solhint-disable-next-line
            (bool wasSent, ) = payable(SharedConfig(_config)._withdrawalWallet()).call{value: platformFee}("");
            require(wasSent, "Failed to send Ether to wallet");
        }

        if (sellerAmount > 0) {
            // solhint-disable-next-line
            (bool wasSent, ) = payable(sellerAddress).call{value: sellerAmount}("");
            require(wasSent, "Failed to send Ether");
        }
    }

    function _mintGenerativeNft(
        address signerAddress,
        address buyerAddress,
        uint256 tokenId
    ) internal virtual {
        require(SharedConfig(_config)._signer() == signerAddress, "Permission to mint is denied");
        _safeMint(buyerAddress, tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
