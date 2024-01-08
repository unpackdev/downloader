// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./IMirrorOpenSaleV0.sol";
import "./Reentrancy.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTreasury.sol";
import "./MirrorFeeRegistry.sol";
import "./IERC721.sol";

/**
 * @title MirrorOpenSaleV0
 *
 * @notice The Mirror Open Sale allows anyone to list an ERC721 with a tokenId range.
 *
 * Each token will be sold with tokenId incrementing starting at the lower end of the range.
 * To minimize storage we hash all sale configuration to generate a unique ID and only store
 * the necessary data that maintains the sale state.
 *
 * The token holder must first approve this contract otherwise purchasing will revert.
 *
 * The contract forwards the ether payment to the specified recipient and pays an optional fee
 * to the Mirror Treasury (0x138c3d30a724de380739aad9ec94e59e613a9008). Additionally, sale
 * royalties are distributed using the NFT Roylaties Standard (EIP-2981).
 *
 * @author MirrorXYZ
 */
contract MirrorOpenSaleV0 is
    IMirrorOpenSaleV0,
    IMirrorOpenSaleV0Events,
    IERC721Events,
    Reentrancy
{
    /// @notice Version
    uint8 public constant VERSION = 0;

    /// @notice Mirror treasury configuration
    address public immutable override treasuryConfig;

    /// @notice Mirror fee registry
    address public immutable override feeRegistry;

    /// @notice Mirror tributary registry
    address public immutable override tributaryRegistry;

    /// @notice Map of sale data hash to sale state
    mapping(bytes32 => Sale) internal sales_;

    /// @notice Store configuration and registry addresses as immutable
    /// @param treasuryConfig_ address for Mirror treasury configuration
    /// @param feeRegistry_ address for Mirror fee registry
    /// @param tributaryRegistry_ address for Mirror tributary registry
    constructor(
        address treasuryConfig_,
        address feeRegistry_,
        address tributaryRegistry_
    ) {
        treasuryConfig = treasuryConfig_;
        feeRegistry = feeRegistry_;
        tributaryRegistry = tributaryRegistry_;
    }

    /// @notice Get stored state for a specific sale
    /// @param h keccak256 of sale configuration (see `_getHash`)
    function sale(bytes32 h) external view override returns (Sale memory) {
        return sales_[h];
    }

    /// @notice Register a sale
    /// @dev only the token itself or the operator can list tokens
    /// @param saleConfig_ sale configuration
    function register(SaleConfig calldata saleConfig_) external override {
        require(
            msg.sender == saleConfig_.token ||
                msg.sender == saleConfig_.operator,
            "cannot register"
        );

        _register(saleConfig_);
    }

    /// @notice Close a sale
    /// @dev Reverts if called by an account that does not operate the sale
    /// @param saleConfig_ sale configuration
    function close(SaleConfig calldata saleConfig_) external override {
        require(msg.sender == saleConfig_.operator, "not operator");

        _setSaleStatus(saleConfig_, false);
    }

    /// @notice Open a sale
    /// @dev Reverts if called by an account that does not operate the sale
    /// @param saleConfig_ sale configuration
    function open(SaleConfig calldata saleConfig_) external override {
        require(msg.sender == saleConfig_.operator, "not operator");

        _setSaleStatus(saleConfig_, true);
    }

    /// @notice Purchase a token
    /// @dev Reverts if the sale configuration does not hash to an open sale,
    ///  not enough ether is sent, he sale is sold out, or if token approval
    ///  has not been granted. Sends funds to the recipient and treasury.
    /// @param saleConfig_ sale configuration
    /// @param recipient account that will receive the purchased token
    function purchase(SaleConfig calldata saleConfig_, address recipient)
        external
        payable
        override
        nonReentrant
    {
        // generate hash of sale data
        bytes32 h = _getHash(saleConfig_);

        // retrive stored sale data
        Sale storage s = sales_[h];

        // the registered field serves to assert that the hash maps to
        // a listed sale and the open field asserts the listed sale is open
        require(s.registered && s.open, "closed sale");

        // assert correct amount of eth is received
        require(msg.value == saleConfig_.price, "incorrect value");

        // calculate next tokenId, and increment amount sold
        uint256 tokenId = saleConfig_.startTokenId + s.sold++;

        // check that the tokenId is valid
        require(tokenId <= saleConfig_.endTokenId, "sold out");

        // transfer token to recipient
        IERC721(saleConfig_.token).transferFrom(
            saleConfig_.operator,
            recipient,
            tokenId
        );

        emit Purchase(
            // h
            h,
            // token
            saleConfig_.token,
            // tokenId
            tokenId,
            // buyer
            msg.sender,
            // recipient
            recipient
        );

        // send funds to recipient and pay fees if necessary
        _withdraw(
            saleConfig_.operator,
            saleConfig_.token,
            tokenId,
            h,
            saleConfig_.recipient,
            msg.value,
            saleConfig_.feePercentage
        );
    }

    // ============ Internal Methods ============

    function _feeAmount(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10_000;
    }

    function _getHash(SaleConfig calldata saleConfig_)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    saleConfig_.token,
                    saleConfig_.startTokenId,
                    saleConfig_.endTokenId,
                    saleConfig_.operator,
                    saleConfig_.recipient,
                    saleConfig_.price,
                    saleConfig_.open,
                    saleConfig_.feePercentage
                )
            );
    }

    function _register(SaleConfig calldata saleConfig_) internal {
        // get maximum fee from fees registry
        uint256 maxFee = IMirrorFeeRegistry(feeRegistry).maxFee();

        // allow to pay any fee below the max, including no fees
        require(saleConfig_.feePercentage <= maxFee, "fee too high");

        // generate hash of sale data
        bytes32 h = _getHash(saleConfig_);

        // assert the sale has not been registered previously
        require(!sales_[h].registered, "sale already registered");

        // store critical sale data
        sales_[h] = Sale({
            registered: true,
            open: saleConfig_.open,
            sold: 0,
            operator: saleConfig_.operator
        });

        // all fields used to generate the hash need to be emitted to store and
        // generate the hash off-chain for interacting with the sale
        emit RegisteredSale(
            // h
            h,
            // token
            saleConfig_.token,
            // startTokenId
            saleConfig_.startTokenId,
            // endTokenId
            saleConfig_.endTokenId,
            // operator
            saleConfig_.operator,
            // recipient
            saleConfig_.recipient,
            // price
            saleConfig_.price,
            // open
            saleConfig_.open,
            // feePercentage
            saleConfig_.feePercentage
        );

        if (saleConfig_.open) {
            emit OpenSale(h);
        } else {
            emit CloseSale(h);
        }
    }

    function _setSaleStatus(SaleConfig calldata saleConfig_, bool status)
        internal
    {
        bytes32 h = _getHash(saleConfig_);

        // assert the sale is registered
        require(sales_[h].registered, "unregistered sale");

        require(sales_[h].open != status, "status already set");

        sales_[h].open = status;

        if (status) {
            emit OpenSale(h);
        } else {
            emit CloseSale(h);
        }
    }

    function _withdraw(
        address operator,
        address token,
        uint256 tokenId,
        bytes32 h,
        address recipient,
        uint256 totalAmount,
        uint256 feePercentage
    ) internal {
        uint256 feeAmount = 0;

        if (feePercentage > 0) {
            // calculate fee amount
            feeAmount = _feeAmount(totalAmount, feePercentage);

            // contribute to treasury
            IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
                .contributeWithTributary{value: feeAmount}(operator);
        }

        uint256 saleAmount = totalAmount - feeAmount;

        (address royaltyRecipient, uint256 royaltyAmount) = _royaltyInfo(
            token,
            tokenId,
            saleAmount
        );

        require(royaltyAmount < saleAmount, "invalid royalty amount");

        if (msg.sender == royaltyRecipient || royaltyRecipient == address(0)) {
            // transfer funds to recipient
            _send(payable(recipient), saleAmount);

            // emit an event describing the withdrawal
            emit Withdraw(h, totalAmount, feeAmount, recipient);
        } else {
            // transfer funds to recipient
            _send(payable(recipient), saleAmount - royaltyAmount);

            // transfer royalties
            _send(payable(royaltyRecipient), royaltyAmount);

            // emit an event describing the withdrawal
            emit Withdraw(h, totalAmount, feeAmount, recipient);
        }
    }

    function _royaltyInfo(
        address token,
        uint256 tokenId,
        uint256 amount
    ) internal view returns (address royaltyRecipient, uint256 royaltyAmount) {
        // get royalty info
        if (IERC165(token).supportsInterface(type(IERC2981).interfaceId)) {
            (royaltyRecipient, royaltyAmount) = IERC2981(token).royaltyInfo(
                tokenId,
                amount
            );
        }
    }

    function _send(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "recipient reverted");
    }
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
