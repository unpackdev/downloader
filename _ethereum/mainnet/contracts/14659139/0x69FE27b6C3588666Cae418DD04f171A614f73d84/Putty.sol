// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

        ██████╗ ██╗   ██╗████████╗████████╗██╗   ██╗
        ██╔══██╗██║   ██║╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝
        ██████╔╝██║   ██║   ██║      ██║    ╚████╔╝ 
        ██╔═══╝ ██║   ██║   ██║      ██║     ╚██╔╝  
        ██║     ╚██████╔╝   ██║      ██║      ██║   
        ╚═╝      ╚═════╝    ╚═╝      ╚═╝      ╚═╝   


       by out.eth and 0xtamogoyaki

*/

import "./console.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/// @title Putty - https://putty.finance
/// @author out.eth
/// @notice Exotic option market for NFTs and ERC20s
contract Putty is
    EIP712("Putty", "v0.9"),
    ERC721("Putty Options", "OPUT"),
    // ERC721Enumerable, // Only for L2s
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for ERC20;

    /// @notice Fires when a buy order has been filled and an option contract is created
    /// @param option The newly created option
    /// @param seller The account that filled the buy order
    /// @param tokenId The token ID of the newly created long option NFT
    /// @param shortTokenId The token ID of the newly created short option NFT
    event BuyFilled(Option option, address indexed seller, uint256 tokenId, uint256 shortTokenId);

    /// @notice Fires when a an option is exercised
    /// @param option The option which is being exercised
    /// @param seller The account that currently holds the short option NFT
    /// @param tokenId The token ID of the long option NFT
    /// @param shortTokenId The token ID of the short option NFT
    event Exercised(Option option, address indexed seller, uint256 tokenId, uint256 shortTokenId);

    /// @notice Fires when a an open buy order is cancelled
    /// @param option The option for the buy order which is being cancelled
    event Cancelled(Option option);

    /// @notice Fires when a an option expires
    /// @param option The option that has expired
    /// @param seller The account that currently holds the short option NFT
    /// @param tokenId The token ID of the long option NFT
    /// @param shortTokenId The token ID of the short option NFT
    event Expired(Option option, address indexed seller, uint256 tokenId, uint256 shortTokenId);

    ERC20 public immutable weth;
    string public baseURI;

    /// @notice Fees which have yet to be collected by the admin
    uint256 public uncollectedFees;

    /// @notice Current fee rate - ex: 1.9% = 1.9 * 1000 = 1900
    uint256 public feeRate;

    /// @notice Gets the creation timestamp of a particular long option NFT
    mapping(uint256 => uint256) public tokenIdToCreationTimestamp;

    /// @notice Gets whether or not a long option NFT buy order has been cancelled
    mapping(uint256 => bool) public cancelledOrders;

    struct ERC20Info {
        ERC20 token;
        uint256 amount;
    }

    struct ERC721Info {
        ERC721 token;
        uint256 tokenId;
    }

    struct Option {
        uint256 strike;
        uint256 duration; // seconds
        uint256 premium;
        address owner;
        uint256 nonce;
        ERC20Info[] erc20Underlying;
        ERC721Info[] erc721Underlying;
    }

    constructor(
        ERC20 weth_,
        string memory baseURI_,
        uint256 feeRate_
    ) {
        weth = weth_;
        baseURI = baseURI_;
        feeRate = feeRate_;
    }

    /*********************
        ADMIN FUNCTIONS
    **********************/

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /// @notice Admin function which sets the fee that is collected on exercise
    /// @param feeRate_ The new fee rate
    function setFeeRate(uint256 feeRate_) public onlyOwner {
        require(feeRate_ <= 1000, "Fee can't be greater than 100%");
        feeRate = feeRate_;
    }

    /// @notice Admin function which withdraws uncollected fees to `recipient`
    /// @param recipient The account which will receive the fees
    function withdrawFees(address recipient) public onlyOwner {
        uint256 amount = uncollectedFees;
        uncollectedFees = 0;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "ETH transfer failed");
    }

    /*********************
        LOGIC FUNCTIONS
    **********************/

    /// @notice Fills an existing buy order
    /// @param option The buy order to fill
    /// @param signature The buy order owner's signature to verify that the buy order is valid
    function fillBuyOrder(Option calldata option, bytes calldata signature)
        public
        payable
        nonReentrant
    {
        // *** Checks *** //

        // transfer the strike amount (WETH) from the seller -> contract
        require(msg.value >= option.strike, "Not enough eth");

        // hash the fields
        (bytes32 orderHash, bytes32 shortOrderHash) = _hashOption(option);
        (uint256 tokenId, uint256 shortTokenId) = (uint256(orderHash), uint256(shortOrderHash));

        // check the signature for the buy order
        bytes32 digest = ECDSA.toEthSignedMessageHash(orderHash);
        address signer = ECDSA.recover(digest, signature);
        require(signer == option.owner, "Invalid order signature");

        // check that the order has not been cancelled or filled already
        require(!cancelledOrders[tokenId], "Order has been cancelled");
        require(tokenIdToCreationTimestamp[tokenId] == 0, "Order has already been filled");

        // *** Effects *** //

        // save the creation timestamp for calculating the expiry date later
        tokenIdToCreationTimestamp[tokenId] = block.timestamp;

        // mint the option NFT contracts to the buyer and seller
        _mint(option.owner, tokenId);
        _mint(msg.sender, shortTokenId);

        // *** Interactions *** //

        // transfer the premium (WETH) from the buyer -> seller
        weth.transferFrom(option.owner, msg.sender, option.premium);

        emit BuyFilled(option, msg.sender, tokenId, shortTokenId);
    }

    /// @notice Exercises a long option NFT and burns both the short and long option NFTs
    /// @param option The option to exercise
    function exercise(Option calldata option) public nonReentrant {
        // *** Checks *** //

        // hash the fields and get buyer/seller
        (bytes32 orderHash, bytes32 shortOrderHash) = _hashOption(option);
        (uint256 tokenId, uint256 shortTokenId) = (uint256(orderHash), uint256(shortOrderHash));
        (address buyer, address seller) = (ownerOf(tokenId), ownerOf(shortTokenId));

        // check that the account calling is the owner of the option
        require(buyer == msg.sender, "You don't own this option");
        require(
            block.timestamp <= tokenIdToCreationTimestamp[tokenId] + option.duration,
            "Expired option"
        );

        // *** Effects *** //

        // burn both the long and short tokens
        _burn(tokenId);
        _burn(shortTokenId);

        // *** Interactions *** //

        // transfer underlying erc20 assets from buyer to seller
        for (uint256 i = 0; i < option.erc20Underlying.length; i++) {
            ERC20Info calldata info = option.erc20Underlying[i];
            info.token.safeTransferFrom(buyer, seller, info.amount);
        }

        // transfer underlying erc721 assets from buyer to seller
        for (uint256 i = 0; i < option.erc721Underlying.length; i++) {
            ERC721Info calldata info = option.erc721Underlying[i];
            info.token.transferFrom(buyer, seller, info.tokenId);
        }

        // collect fee
        uint256 fee;
        if (feeRate > 0) {
            fee = (option.strike * feeRate) / 1000;
            uncollectedFees += fee;
        }

        // transfer `strike - fee` to the buyer
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = buyer.call{ value: option.strike - fee }("");
        require(success, "ETH transfer to buyer failed");

        emit Exercised(option, seller, tokenId, shortTokenId);
    }

    /// @notice Cancels an unfilled buy order
    /// @param option The unfilled option to cancel
    function cancel(Option calldata option) public {
        require(msg.sender == option.owner, "You are not the owner");

        (bytes32 orderHash, ) = _hashOption(option);
        uint256 tokenId = uint256(orderHash);

        cancelledOrders[tokenId] = true;

        emit Cancelled(option);
    }

    /// @notice Expires an option and burns the long and short option NFTs
    /// @param option The option to expire
    function expire(Option calldata option) public {
        // *** Checks *** //

        // hash the fields and get the seller
        (bytes32 orderHash, bytes32 shortOrderHash) = _hashOption(option);
        (uint256 tokenId, uint256 shortTokenId) = (uint256(orderHash), uint256(shortOrderHash));
        address seller = ownerOf(shortTokenId);

        require(
            block.timestamp > tokenIdToCreationTimestamp[tokenId] + option.duration,
            "Option has not expired"
        );

        // *** Effects *** //

        // burn both tokens
        _burn(tokenId);
        _burn(shortTokenId);

        // *** Interactions *** //

        // transfer strike (ETH) to seller
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = seller.call{ value: option.strike }("");
        require(success, "ETH transfer to seller failed");

        emit Expired(option, seller, tokenId, shortTokenId);
    }

    /********************
        UTIL FUNCTIONS
    *********************/

    function _hashOption(Option calldata option)
        internal
        view
        returns (bytes32 orderHash, bytes32 shortOrderHash)
    {
        // NOTE:
        // This was implemented incorrectly but it's too late to change now.
        // It should be updated to be EIP-712 compliant and also there is no need
        // to pre-hash the underlying assets - it's just as secure to do this instead:
        // `orderHash = keccak256(abi.encode(_domainSeparatorV4(), option))`
        orderHash = keccak256(
            abi.encode(
                _domainSeparatorV4(),
                option.strike,
                option.duration,
                option.premium,
                option.owner,
                option.nonce,
                keccak256(abi.encode(option.erc20Underlying)),
                keccak256(abi.encode(option.erc721Underlying))
            )
        );

        shortOrderHash = keccak256(abi.encode(orderHash));
    }

    /**********************
        GETTER FUNCTIONS
    **********************/

    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @notice Checks whether a buy order has been filled or not
    /// @param tokenId The tokenId of the option to check
    function filledOrders(uint256 tokenId) public view returns (bool) {
        return tokenIdToCreationTimestamp[tokenId] > 0;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /***************
        OVERRIDES
    ****************/

    // Only for L2s
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal override(ERC721, ERC721Enumerable) {
    //     super._beforeTokenTransfer(from, to, tokenId);
    // }

    // Only for L2s
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     override(ERC721, ERC721Enumerable)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }
}
