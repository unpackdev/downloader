// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./SporesRegistry.sol";
import "./Signature.sol";

/**
   @title SporesNFTMarket contract
   @dev This contract is used to handle buy/sell NFT tokens/items
   Note: 
    - The supporting NFT standards:
        + ERC-721 (https://eips.ethereum.org/EIPS/eip-721)
    - For payment, the supporting coins/tokens:
        + ETH/WETH
        + ERC-20 (https://ethereum.org/en/developers/docs/standards/tokens/erc-20/)
*/
contract SporesNFTMarket is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Signature for Signature.TradeType;

    //  Market version
    bytes32 public constant VERSION = keccak256("MARKET_721_v1");

    // FEE_DENOMINATOR = 10^6 should be good for lower fee ratio, e.g. 0.1%
    uint256 private constant FEE_DENOMINATOR = 10**6;

    // SporesRegistry contract
    SporesRegistry public registry;

    event SporesNFTMarketTransaction(
        address indexed _buyer,
        address indexed _seller,
        address _paymentReceiver,
        address _contractNFT,
        address _paymentToken,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _amount,
        uint256 _fee,
        uint256 _sellId,
        Signature.TradeType _tradeType
    );

    event NativeCoinPayment(address indexed _to, uint256 _amount);

    /**
       @notice Initialize SporesRegistry contract 
       @param _registry        Address of SporesRegistry contract
    */
    constructor(address _registry) Ownable() {
        registry = SporesRegistry(_registry);
    }

    /**
       @notice Update new address of SporesRegistry contract
       @dev Caller must be Owner
           SporesRegistry contract is upgradeable smart contract
           Thus, the address remains unchanged in upgrading
           However, this functions is a back up in the worse case 
           that requires to deploy a new SporesRegistry contract
       @param _newRegistry          Address of new SporesRegistry contract
    */
    function updateRegistry(address _newRegistry) external onlyOwner {
        require(
            _newRegistry != address(0),
            "SporesNFTMarket: Set zero address"
        );
        registry = SporesRegistry(_newRegistry);
    }

    /**
       @notice Handle transaction of trading Spores NFT721 item with Native Coin
       @dev Caller can be ANY
           Buyer must use his/her account to send this request
       @param _info                 Trading Information     
        + _seller               Seller Address
        + _paymentReceiver      Address to receive payment
        + _contractNFT          Address of NFT721 contract
        + _paymentToken         Address(0) - Native coin
        + _tokenId              NFT721 Token ID
        + _feeRate              Numerator of commission fee
        + _price                Selling price
        + _amount               SINGLE_UNIT = 1
        + _sellId               A number of selling information (BE requirement)
       @param _signature            Signature of Verifier
    */
    function buyNFT721NativeCoin(
        Signature.TradeInfo calldata _info,
        bytes calldata _signature
    ) external payable nonReentrant {
        // @dev Avoid the case: Seller authorizes SporesNFTMarket to proceed Buy/Sell by setting 'setApproveForAll'
        // Buyer purchases the NFT721 item, but specify the receiving of payment is its own account.
        // Solution: check NFT721 TokenId and address of Seller
        // The owner of '_tokenId' must match the address of Seller
        require(
            msg.value == _info._price,
            "SporesNFTMarket: Insufficient payment"
        );
        require(
            registry.supportedNFT721(_info._contractNFT) ||
                registry.collections(_info._contractNFT),
            "SporesNFTMarket: NFT721 Contract not supported"
        );
        require(
            IERC721Upgradeable(_info._contractNFT).ownerOf(_info._tokenId) ==
                _info._seller,
            "SporesNFTMarket: Seller is not owner"
        );

        // In addition, Verifier provides a signature
        // Sig = sign(
        //    [_seller, _paymentReceiver, _contractNFT, _tokenId, _paymentToken, _feeRate, _price, _amount, _sellId, PURCHASE_TYPE]
        // )
        _checkAuthorization(
            Signature.TradeType.NATIVE_COIN_NFT_721,
            _info,
            _signature
        );

        //  Calculate charging fee, and paying amount to Seller
        (uint256 _fee, uint256 _payToSeller) =
            _calcPayment(_info._price, _info._amount, _info._feeRate);

        //  transfer a payment to '_paymentReceiver' and Fee Collector
        _paymentTransfer(payable(_info._paymentReceiver), _payToSeller);
        _paymentTransfer(payable(registry.treasury()), _fee);

        //  transfer NFT721 item to Buyer
        //  If Seller has not yet setApproveForAll to allow SporesNFTMarket contract
        //  transfer NFT721 item, this transaction is likely reverted
        IERC721Upgradeable(_info._contractNFT).safeTransferFrom(
            _info._seller,
            _msgSender(),
            _info._tokenId
        );

        emit SporesNFTMarketTransaction(
            _msgSender(),
            _info._seller,
            _info._paymentReceiver,
            _info._contractNFT,
            _info._paymentToken,
            _info._tokenId,
            _info._price,
            _info._amount,
            _fee,
            _info._sellId,
            Signature.TradeType.NATIVE_COIN_NFT_721
        );
    }

    function _paymentTransfer(address payable _to, uint256 _amount) private {
        (bool sent, ) = _to.call{ value: _amount }("");
        require(sent, "SporesNFTMarket: Payment transfer failed");
        emit NativeCoinPayment(_to, _amount);
    }

    /**
       @notice Handle transaction of trading Spores NFT721 item with ERC-20 Token
       @dev Caller can be ANY
           Buyer must use his/her account to send this request
       @param _info                 Trading Information     
        + _seller               Seller Address
        + _paymentReceiver      Address to receive payment
        + _contractNFT          Address of NFT721 contract
        + _paymentToken         Addres of payment token contract
        + _tokenId              NFT721 Token ID
        + _feeRate              Numerator of commission fee
        + _price                Selling price
        + _amount               SINGLE_UNIT = 1
        + _sellId               A number of selling information (BE requirement)
       @param _signature            Signature of Verifier
    */
    function buyNFT721ERC20(
        Signature.TradeInfo calldata _info,
        bytes calldata _signature
    ) external {
        require(
            registry.supportedTokens(_info._paymentToken),
            "SporesNFTMarket: Invalid payment"
        );
        require(
            registry.supportedNFT721(_info._contractNFT) ||
                registry.collections(_info._contractNFT),
            "SporesNFTMarket: NFT721 Contract not supported"
        );
        require(
            IERC721Upgradeable(_info._contractNFT).ownerOf(_info._tokenId) ==
                _info._seller,
            "SporesNFTMarket: Seller is not owner"
        );

        // Verifier provides a signature
        // Sig = sign(
        //    [_seller, _paymentReceiver, _contractNFT, _tokenId, _paymentToken, _feeRate, _price, _amount, _sellId, PURCHASE_TYPE]
        // )
        _checkAuthorization(
            Signature.TradeType.ERC_20_NFT_721,
            _info,
            _signature
        );

        // Calculate charging fee, and paying amount to Seller
        (uint256 _fee, uint256 _payToSeller) =
            _calcPayment(_info._price, _info._amount, _info._feeRate);

        // transfer payment Tokens to '_paymentReceiver' and Fee Collector
        // If Buyer has not yet set allowance[buyer][operator]
        // or Buyer has insufficient balances, these transactions are likely reverted
        IERC20(_info._paymentToken).safeTransferFrom(
            _msgSender(),
            _info._paymentReceiver,
            _payToSeller
        );
        IERC20(_info._paymentToken).safeTransferFrom(
            _msgSender(),
            registry.treasury(),
            _fee
        );

        // transfer NFT721 item to Buyer
        // If Seller has not yet setApproveForAll to allow SporesNFTMarket contract
        // transfer NFT721 item, this transaction is likely reverted
        IERC721Upgradeable(_info._contractNFT).safeTransferFrom(
            _info._seller,
            _msgSender(),
            _info._tokenId
        );

        emit SporesNFTMarketTransaction(
            _msgSender(),
            _info._seller,
            _info._paymentReceiver,
            _info._contractNFT,
            _info._paymentToken,
            _info._tokenId,
            _info._price,
            _info._amount,
            _fee,
            _info._sellId,
            Signature.TradeType.ERC_20_NFT_721
        );
    }

    function _checkAuthorization(
        Signature.TradeType _type,
        Signature.TradeInfo calldata _info,
        bytes calldata _signature
    ) private {
        registry.checkAuthorization(
            _type.getTradingSignature(_info, _signature),
            keccak256(_signature)
        );
    }

    function _calcPayment(
        uint256 _price,
        uint256 _amount,
        uint256 _feeRate
    ) private pure returns (uint256 _fee, uint256 _payToSeller) {
        //  @dev Solidity 0.8.0 has integrated overflow and underflow checking
        //  Please check it out https://docs.soliditylang.org/en/v0.8.7/080-breaking-changes.html
        // _fee = _feeRate * Price * Amount / FEE_DENOMINATOR
        // _payToSeller = Price * Amount - fee
        _fee = (_feeRate * _price * _amount) / FEE_DENOMINATOR;
        _payToSeller = _price * _amount - _fee;
    }
}
