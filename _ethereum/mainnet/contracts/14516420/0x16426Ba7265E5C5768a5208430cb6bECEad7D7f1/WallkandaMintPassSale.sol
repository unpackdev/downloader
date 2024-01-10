//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

/// @title WallkandaMintPassSale
/// @author Simon Fremaux (@dievardump) for Wallkanda.art
/// @notice This contract allows to create different mint passes and let user purchase it
/// the users can get a refund for their token at any time by sending back the mintpass they purchased to this contract
///
/// Usage:
///
/// 1) For contract owner:
///
/// Mint a new MintPass on mintPassContract
/// Configure the mintpass in this contract: price, limitPerWallet, active
/// Transfer the mintpass from the owner of current contract to this contract,
/// with `data` == WallkandaMintPassSale.FILL
///
/// 2) For Users / Buyers
///
/// Users can then buy tokens using the purchase(mintPassId, amount) function
///
/// Owners can get a refund by transfering the tokens to this contract with `data` == WallkandaMintPassSale.REFUND
///
/// 3) For Contracts
///
/// Contracts can redeem the tokens vs the price of the token by transfering to this contract with `data` == WallkandaMintPassSale.REDEEM
/// when redeemed, the mintPass are burnt
/// to save gas, ideally all mintpasses are redeemed in one tx after sale has ended (and not everytime someone purchase using a mintPass)
///
/// -----------------------------------------
///
/// The only way to get funds out of this contract, is to send back tokens in it, either for a REFUND or a REDEEM
/// This ensures that until the tokens are used, Wallkanda can not get the funds
///
/// -----------------------------------------
contract WallkandaMintPassSale is Ownable, ReentrancyGuard {
    error WrongSettings();
    error NoPriceZero();
    error NoZeroInput();
    error WrongValue();
    error WrongMintPass();
    error TooManyRequested();
    error SaleClosed();
    error WrongNFTReceived();
    error NoLimitZero();

    event Purchase(
        address buyer,
        uint256 mintPassId,
        uint256 amount,
        uint256 value
    );

    event Redeem(
        address sender,
        uint256 mintPassId,
        uint256 amount,
        uint256 value
    );
    event Refund(
        address sender,
        uint256 mintPassId,
        uint256 amount,
        uint256 value
    );

    struct MintPass {
        uint256 price;
        uint16 limitPerWallet;
        bool active;
    }

    bytes32 public constant REDEEM = keccak256("REDEEM");
    bytes32 public constant REFUND = keccak256("REFUND");
    bytes32 public constant FILL = keccak256("FILL");

    address public mintPassContract;

    mapping(uint256 => MintPass) public mintPassData;

    mapping(address => mapping(uint256 => uint256)) public purchased;

    constructor(address mintPassContract_, address owner_) {
        if (mintPassContract_ == address(0)) {
            revert WrongSettings();
        }

        mintPassContract = mintPassContract_;

        configureMintPass(1, 0.05 ether, 3, false);

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    ////////////////////////////////////////////////////
    ///// Public                                      //
    ////////////////////////////////////////////////////

    /// @notice call to purchase a mintPass id
    /// @param mintPassId the mintpass to purchase
    /// @param amount the amount to purchase
    function purchase(uint256 mintPassId, uint16 amount)
        external
        payable
        nonReentrant
    {
        if (amount == 0) {
            revert NoZeroInput();
        }

        MintPass memory mintPass = mintPassData[mintPassId];

        if (mintPass.active == false) {
            revert SaleClosed();
        }

        if (mintPass.price == 0) {
            revert WrongMintPass();
        }

        if (msg.value != uint256(amount) * mintPass.price) {
            revert WrongValue();
        }

        address sender = msg.sender;
        address mintPassContract_ = mintPassContract;

        uint256 purchased_ = purchased[sender][mintPassId];

        if (
            // if the sender already purchased limit
            purchased_ + amount > uint256(mintPass.limitPerWallet) ||
            // or the sender already got some passes somewhere
            ERC1155Burnable(mintPassContract_).balanceOf(sender, mintPassId) +
                uint256(amount) >
            uint256(mintPass.limitPerWallet)
        ) {
            revert TooManyRequested();
        }

        purchased[sender][mintPassId] += amount;

        // this will fail if this contract doesn't have enough items to sell
        ERC1155Burnable(mintPassContract_).safeTransferFrom(
            address(this),
            sender,
            mintPassId,
            uint256(amount),
            ""
        );

        emit Purchase(sender, mintPassId, amount, msg.value);
    }

    /// @notice This function is triggered when items are sent back into this contract
    /// @dev this function manages different actions according to the data input
    /// FILL: filling tokens
    /// REFUND: refund the token price to `from`
    /// REDEEM: refund the token price to `from` & burn the token as it was redeemed
    function onERC1155Received(
        address,
        address from,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        // only accepts tokens from mintPassContract
        if (msg.sender != mintPassContract) {
            revert WrongNFTReceived();
        }

        bytes32 dataCast = bytes32(data);

        if (dataCast == REFUND || dataCast == REDEEM) {
            uint256 price = mintPassData[tokenId].price;

            // accepts only mintPasses that have a price
            if (price == 0) {
                revert WrongMintPass();
            }

            if (dataCast == REDEEM) {
                ERC1155Burnable(msg.sender).burn(
                    address(this),
                    tokenId,
                    amount
                );
                emit Redeem(msg.sender, tokenId, amount, amount * price);
            } else {
                emit Refund(msg.sender, tokenId, amount, amount * price);
            }

            // send the cost of those tokens to the sender
            // which might be either a user that wants a refund
            // or one of our contracts, after someone paid with a mintPass.
            from.call{value: amount * price, gas: 30_000}("");
        } else if (dataCast == FILL && from == owner()) {
            // nothing
        } else {
            revert("UnknownAction()");
        }

        return this.onERC1155Received.selector;
    }

    ////////////////////////////////////////////////////
    ///// Only Owner                                  //
    ////////////////////////////////////////////////////

    /// @notice Allows to configure a mintPass
    /// @param mintPassId the mintPass id
    /// @param mintPassPrice the new price (only settable if the price was never set)
    /// @param mintPassLimitPerWallet the limit per wallet
    /// @param active if buying the mint pass is active
    function configureMintPass(
        uint256 mintPassId,
        uint256 mintPassPrice,
        uint16 mintPassLimitPerWallet,
        bool active
    ) public onlyOwner {
        MintPass storage mintPass = mintPassData[mintPassId];

        // the price can not be changed once set.
        if (mintPass.price == 0 && mintPassPrice != 0) {
            mintPass.price = mintPassPrice;
        }

        if (mintPassLimitPerWallet != 0) {
            mintPass.limitPerWallet = mintPassLimitPerWallet;
        }

        mintPass.active = active;

        // can not activate sale with a price of 0
        if (mintPass.active && mintPass.price == 0) {
            revert NoPriceZero();
        }

        // can not activate sale with a limitPerWallet of 0
        if (mintPass.active && mintPass.limitPerWallet == 0) {
            revert NoLimitZero();
        }
    }

    /// @notice Allows to burn this contract balance for a given mintpass
    /// @param mintPassId the mintPass id
    function burnMintPass(uint256 mintPassId) public onlyOwner {
        address mintPassContract_ = mintPassContract;
        ERC1155Burnable(mintPassContract_).burn(
            address(this),
            mintPassId,
            ERC1155Burnable(mintPassContract_).balanceOf(
                address(this),
                mintPassId
            )
        );
    }
}
