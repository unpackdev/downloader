// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AccessControlUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SharedConfig.sol";
import "./SharedLogic.sol";

contract MatterTrack is
    SharedLogic,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155BurnableUpgradeable,
    EIP712Upgradeable,
    UUPSUpgradeable
{
    mapping(uint256 => uint256) internal _tokenIdToMaxMintingCount;

    function initialize(address config) external initializer {
        __AccessControl_init();
        __AccessControlEnumerable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __EIP712_init_unchained("MatterTrackEIP712", "0.0.2");
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _config = config;
    }

    function setConfig(address config) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(config != address(0), "Invalid config");
        _config = config;
    }

    // For etherscan.io to display contract name
    function name() external pure returns (string memory) {
        return "MatterTrack";
    }

    // For etherscan.io to display contract symbol
    function symbol() external pure returns (string memory) {
        return "MTR";
    }

    // For opensea.io to display contract metadata
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(SharedConfig(_config)._nftHost(), "/api/v1/contracts/MatterTrack/metadata"));
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    SharedConfig(_config)._nftHost(),
                    "/api/v1/tracks/",
                    StringsUpgradeable.toString(tokenId),
                    "/nft"
                )
            );
    }

    // API

    function redeem(
        address sellerAddress,
        uint256 tokenId,
        uint256 mintCount,
        uint256 maxMintCount,
        uint256 price,
        bytes calldata signature
    ) public payable virtual {
        address buyerAddress = _msgSender();
        address signerAddress = _verifySignature(sellerAddress, tokenId, mintCount, maxMintCount, price, signature);
        _setMaxMintingCount(tokenId, maxMintCount);
        _validateMintCountIsAvailableToMint(tokenId, mintCount, maxMintCount);
        _processPayment(msg.value, price, sellerAddress);
        _mintTrack(signerAddress, buyerAddress, tokenId, mintCount);
    }

    // Implementation

    function _mintTrack(
        address signerAddress,
        address buyerAddress,
        uint256 tokenId,
        uint256 mintCount
    ) internal virtual {
        require(SharedConfig(_config)._signer() == signerAddress, "Permission to mint is denied");
        _mint(buyerAddress, tokenId, mintCount, "");
    }

    function _processPayment(
        uint256 moneySend,
        uint256 price,
        address sellerAddress
    ) internal virtual {
        require(moneySend >= price, "Insufficient funds to redeem");

        uint256 platformFee = (price / PERCENTAGE) * SharedConfig(_config)._feePercentMintingTracks();
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

    function _setMaxMintingCount(uint256 tokenId, uint256 maxMintCount) internal virtual {
        require(maxMintCount > 0, "Max mint count must be more than zero");
        require(
            _tokenIdToMaxMintingCount[tokenId] == 0 || _tokenIdToMaxMintingCount[tokenId] == maxMintCount,
            "Max mint count cannot be updated"
        );

        if (_tokenIdToMaxMintingCount[tokenId] == 0) {
            _tokenIdToMaxMintingCount[tokenId] = maxMintCount;
        }
    }

    function _validateMintCountIsAvailableToMint(
        uint256 tokenId,
        uint256 mintCount,
        uint256 maxMintCount
    ) internal view virtual {
        require(mintCount > 0, "Mint count must be more than zero");
        require(totalSupply(tokenId) + mintCount <= maxMintCount, "Mint count must be less or equal to max mint count");
    }

    function _verifySignature(
        address sellerAddress,
        uint256 tokenId,
        uint256 mintCount,
        uint256 maxMintCount,
        uint256 price,
        bytes calldata signature
    ) internal view virtual returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "MatterTrackSignData(address sellerAddress,uint256 tokenId,uint256 mintCount,uint256 maxMintCount,uint256 price)"
                    ),
                    sellerAddress,
                    tokenId,
                    mintCount,
                    maxMintCount,
                    price
                )
            )
        );
        address signerAddress = ECDSAUpgradeable.recover(digest, signature);
        require(SharedConfig(_config)._signer() == signerAddress, "Invalid signature");

        return signerAddress;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE) // solhint-disable-next-line
    {}

    // The following functions are overrides required by Solidity.

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        ERC1155SupplyUpgradeable._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        ERC1155SupplyUpgradeable._burnBatch(account, ids, amounts);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        ERC1155SupplyUpgradeable._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        ERC1155SupplyUpgradeable._mintBatch(to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
