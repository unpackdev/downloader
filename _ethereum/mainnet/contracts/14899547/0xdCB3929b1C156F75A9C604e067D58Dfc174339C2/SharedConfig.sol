// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AccessControlEnumerableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

struct Currency {
    address erc20Address;
    string code;
}

contract SharedConfig is AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    address public _signer;
    address payable public _withdrawalWallet;
    string public _nftHost;
    mapping(string => address) public _currencies;
    uint256 public _feePercentMintingTracks;
    uint256 public _feePercentPurchasingProducts;
    uint256 public _feePercentMintingGenerativeNfts;

    function initialize(
        address signerAddress,
        address payable withdrawalWallet,
        string calldata nftHost,
        Currency[] calldata currencies
    ) external initializer {
        require(signerAddress != address(0), "Invalid signer");
        require(withdrawalWallet != address(0), "Invalid wallet");

        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _signer = signerAddress;
        _withdrawalWallet = withdrawalWallet;
        _nftHost = nftHost;

        _feePercentMintingTracks = 250; // 2.5%
        _feePercentPurchasingProducts = 250; // 2.5%
        _feePercentMintingGenerativeNfts = 250; // 2.5%

        for (uint256 i = 0; i < currencies.length; i++) {
            require(currencies[i].erc20Address != address(0), "Invalid erc20 address");
            _currencies[currencies[i].code] = currencies[i].erc20Address;
        }
    }

    function setSigner(address signer) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(signer != address(0), "Invalid signer");
        _signer = signer;
    }

    function setWithdrawalWallet(address payable withdrawalWallet) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(withdrawalWallet != address(0), "Invalid wallet");
        _withdrawalWallet = withdrawalWallet;
    }

    function setNftHost(string calldata nftHost) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _nftHost = nftHost;
    }

    function setFeePercentMintingTracks(uint256 fee) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 10000, "Invalid fee percent");
        _feePercentMintingTracks = fee;
    }

    function setFeePercentPurchasingProducts(uint256 fee) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 10000, "Invalid fee percent");
        _feePercentPurchasingProducts = fee;
    }

    function setFeePercentMintingGenerativeNfts(uint256 fee) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 10000, "Invalid fee percent");
        _feePercentMintingGenerativeNfts = fee;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE) // solhint-disable-next-line
    {}
}
