// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./ERC721Upgradeable.sol";
import "./OptionURIFetcher.sol";

// Interfaces
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";

/*
 * @notice This is an options contract that allows a user to deposit a bundle of tokens for a set price that can be executed at
 *  a later time. This allows users to lend their ETH as collateral for the option and collect an incentive by the
 *  option creator.
 *
 * @author develop@teller.finance
 */
contract Option is ERC721Upgradeable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {

    uint32 constant ONE_YEAR = 31536000;
    uint32 constant ONE_DAY = 86400;

    uint256 public optionsCount = 0;
    OptionURIFetcher public uriFetcher;
    mapping(uint256 => OptionData) public options;

    mapping(uint256 => TokenBundle) internal _bundles;

    enum OptionStatus {
        undefined,
        filled,
        exercised,
        cancelled
    }

    enum TokenType {
        ERC721,
        ERC1155
        // TODO: support ERC20
    }

    struct TokenBundle {
        TokenType[] types;
        address[] addresses;
        uint256[] ids;
        uint256[] amounts;
    }

    struct OptionData {
        uint256 buyoutPriceWei;
        uint256 incentiveAmountWei;

        address optionFiller;
        uint32 startTime;
        uint32 duration;
        OptionStatus status;
    }

    event OptionCreated(uint256 indexed optionId, address indexed creator);
    event OptionFilled(uint256 indexed optionId);
    event OptionCancelled(uint256 indexed optionId);
    event OptionExpired(uint256 indexed optionId);
    event OptionExercised(uint256 indexed optionId);

    modifier onlyOptionOwner(uint256 optionId) {
        require(_msgSender() == ownerOf(optionId), "Option: not owner");
        _;
    }

    /**
     * @notice Initializes the Option contract as an ERC721 token.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _uriFetcher
    ) external initializer {
        __ERC721_init(_name, _symbol);
        uriFetcher = OptionURIFetcher(_uriFetcher);
    }

    /**
     * @notice Returns the token bundle assigned to the given {optionId}.
     * @param optionId The ID to query token bundle info.
     */
    function bundleOf(uint256 optionId) public view returns (TokenBundle memory) {
        return _bundles[optionId];
    }

    /**
     * @notice Gets the contract metadata URI from the OptionURIFetcher.
     * @return The contract URI hash
     */
    function contractURI() external view returns (string memory) {
        return uriFetcher.fetchContractURI();
    }

    /**
     * @notice Gets the token metadata URI from the OptionURIFetcher.
     * @param tokenId Token ID to get URI for.
     * @return The token URI hash
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return uriFetcher.fetchOptionURI(tokenId);
    }

    /**
     * @notice Creates a new option for a bundle of tokens and mints an Option NFT.
     * @param bundle Data describing which tokens to create the option with.
     * @param buyoutPriceWei Floor price in wei for the entire token bundle.
     * @param duration Max duration, in seconds, the option will last after being filled.
     */
    function createOption(
        TokenBundle calldata bundle,
        uint256 buyoutPriceWei,
        uint32 duration
    ) public payable returns (uint256 optionId_) {
        require(duration >= ONE_DAY && duration <= ONE_YEAR, "Option: invalid duration");

        // Pull the tokens into escrow
        _transferTokenBundleIn(bundle);

        // Increment ID counter
        optionId_ = optionsCount++;

        // Initialize the options struct data
        OptionData storage opt = options[optionId_];
        opt.buyoutPriceWei = buyoutPriceWei;
        opt.incentiveAmountWei = msg.value;
        opt.duration = duration;

        // Set the token bundle for option
        _bundles[optionId_] = bundle;

        // Mint the option NFT for the creator
        _mint(_msgSender(), optionId_);

        emit OptionCreated(optionId_, _msgSender());
    }

    /*
     * @notice Used by the option owner to retrieve the escrowed tokens.
     * @param optionId ID of the option to cancel
     *
     * Requirements:
     *  - {optionId} must exists
     *  - {_msgSender} must be the option owner
     */
    function cancelOption(uint256 optionId) public onlyOptionOwner(optionId) {
        OptionData storage opt = options[optionId];

        require(opt.status < OptionStatus.exercised, "Option: option closed");

        // Prevent re-entrancy [assume the NFT can call this method on SafeTransferFrom]
        OptionStatus originalStatus = opt.status;
        opt.status = OptionStatus.cancelled;

        // Return the NFT to the option owner
        _transferOptionBundle(optionId, ownerOf(optionId));

        // Return any buyout ether to the filler [if exists]
        if (originalStatus == OptionStatus.filled) {
            // TODO: change buyout token from ETH to WETH (ERC20)
            payable(opt.optionFiller).transfer(
                opt.buyoutPriceWei
            );
        }

        // Burn the option token
        _burn(optionId);

        emit OptionCancelled(optionId);
    }

    /**
     * @notice Deletes an option that is expired. Sends option token bundle back to owner and buyout price to filler.
     * @param optionId The option ID to expire
     *
     * Requirements:
     *  - status must be filled
     *  - option must be expired
     */
    function expireOption(uint256 optionId) public {
        OptionData storage opt = options[optionId];

        require(
            opt.status == OptionStatus.filled,
            "Option: status not filled"
        );
        require(
            block.timestamp >= (opt.startTime + opt.duration),
            "Option: not expired"
        );

        // Prevent re-entrancy [assume the NFT can call this method on SafeTransferFrom]
        opt.status = OptionStatus.cancelled;

        // Return the NFT to the option owner
        _transferOptionBundle(optionId, ownerOf(optionId));

        // Return any buyout ether to the filler [if exists]
        // TODO: change buyout token from ETH to WETH (ERC20)
        payable(opt.optionFiller).transfer(
            opt.buyoutPriceWei
        );

        // Burn the option token
        _burn(optionId);

        emit OptionExpired(optionId);
    }

    /**
     * @notice Fills an option with the buyout price and start the expiration clock.
     * @param optionId The option ID to fill.
     *
     * Requirements:
     *  - option token must exist
     *  - status must be undefined
     *  - {msg.value} must match the buyout price
     */
    function fillOption(uint256 optionId) public payable {
        OptionData storage opt = options[optionId];

        require(_exists(optionId), "Option: non-existent");
        require(
            opt.status == OptionStatus.undefined,
            "Option: already filled"
        );
        require(
            msg.value == opt.buyoutPriceWei,
            "Option: incorrect ether value"
        );

        // Start options contract
        opt.optionFiller = _msgSender();
        opt.status = OptionStatus.filled;
        opt.startTime = uint32(block.timestamp);

        // Send the incentive amount to the filler
        // TODO: change buyout token from ETH to WETH (ERC20)
        if (opt.incentiveAmountWei > 0) {
            payable(_msgSender()).transfer(opt.incentiveAmountWei);
        }

        emit OptionFilled(optionId);
    }

    /*
     * @notice Used by the option owner to retrieve the escrowed ETH.
     * @param optionId The option ID to exercise.
     *
     * Requirements:
     *  - {_msgSender} must be the option owner
     *  - status must be filled
     *  - must not be expired
     */
    function exerciseOption(uint256 optionId) public onlyOptionOwner(optionId) {
        OptionData storage opt = options[optionId];

        require(
            opt.status == OptionStatus.filled,
            "Option: status not filled"
        );
        require(
            block.timestamp < (opt.startTime + opt.duration),
            "Option: expired"
        );

        // Prevent re-entrancy [assume the NFT can call this method on SafeTransferFrom]
        opt.status = OptionStatus.exercised;

        // Send the buyout ether to the optionOwner
        payable(ownerOf(optionId)).transfer(
            opt.buyoutPriceWei
        );

        // Send the NFT to the option filler
        _transferOptionBundle(optionId, opt.optionFiller);

        _burn(optionId);

        emit OptionExercised(optionId);
    }

    /* Token Transfer Functions */

    /**
     * @dev Transfers a {tokenType} based on the encoded {data}.
     */
    function _transferToken(TokenType tokenType, bytes memory data) internal {
        _transferToken(tokenType, data, "");
    }

    /**
     * @dev Transfers a {tokenType} based on the encoded {details}. If token is 721 or 1155 can also pass {transferData}
     *  to send with the safe transfer call.
     *  Encoded details follows the format of:
     *      `abi.encode(from, to, token, tokenId, amount)`
     */
    function _transferToken(TokenType tokenType, bytes memory details, bytes memory transferData) internal {
        (address from, address to, address token, uint256 tokenId, uint256 amount) =
            abi.decode(details, (address, address, address, uint256, uint256));

        if (tokenType == TokenType.ERC721) {
            require(amount == 1, "Option: 721 amount not 1");
            IERC721(token).safeTransferFrom(
                from,
                to,
                tokenId,
                transferData
            );
        } else if (tokenType == TokenType.ERC1155) {
            IERC1155(token).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                transferData
            );
        }
    }

    /**
     * @dev Transfers a bundle of tokens during the creation of an option. 721 and 1155 tokens are passed transfer token
     *  data to ensure it was transferred and received in the same tx.
     * @param bundle Data containing details of the tokens to transfer.
     */
    function _transferTokenBundleIn(TokenBundle calldata bundle) internal {
        uint256 expectedLength = bundle.types.length;
        require(
            expectedLength == bundle.addresses.length &&
                expectedLength == bundle.ids.length &&
                expectedLength == bundle.amounts.length,
            "Option: bundle lengths mismatch"
        );

        for (uint256 i; i < bundle.types.length; i++) {
            bytes memory data =
                abi.encode(_msgSender(), address(this), bundle.addresses[i], bundle.ids[i], bundle.amounts[i]);
            _transferToken(bundle.types[i], data, abi.encode(_encodeTokenTransferData()));
        }
    }

    /**
     * @dev Transfers an option's token bundle {to} a specified recipient.
     * @param optionId The option ID to get token bundle details.
     * @param to Address to receive the token bundle.
     */
    function _transferOptionBundle(uint256 optionId, address to) internal {
        TokenBundle storage bundle = _bundles[optionId];
        for (uint256 i; i < bundle.types.length; i++) {
            bytes memory data =
                abi.encode(address(this), to, bundle.addresses[i], bundle.ids[i], bundle.amounts[i]);
            _transferToken(bundle.types[i], data);
        }
    }

    /* Token Receiver Hooks */

    /**
     * @dev Encodes this contract address and the block number for verification.
     */
    function _encodeTokenTransferData() private view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), block.number));
    }

    /**
     * @dev Verifies that the ERC721 or ERC1155 token was transferred by this contract in the same block.
     * @dev This function should be used by the receive hook functions defined below.
     * @param data The encode data that was created via the `createOption` function.
     */
    function _verifyNFTData(bytes calldata data) private view {
        // NOTE: msg.sender should be the token contract as it is the one calling the hook
        require(abi.decode(data, (bytes32)) == _encodeTokenTransferData(), "Option: invalid deposit");
    }

    /**
     * @dev See {IERC721-onERC721Received}
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata data
    ) external view override returns (bytes4) {
        _verifyNFTData(data);

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /**
     * @dev See {IERC1155.onERC1155Received}
     */
    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata data
    ) external view override returns (bytes4) {
        _verifyNFTData(data);

        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
     * @dev See {IERC721-onERC1155BatchReceived}
     */
    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return "";
    }
}
