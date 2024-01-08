// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************************************************************************************
 *  ________   ___  ________ _________    ___    ___      ________  ________  _________  ___  ________  ________   ________       *
 * |\   ___  \|\  \|\  _____\\___   ___\ |\  \  /  /|    |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \|\   ____\      *
 * \ \  \\ \  \ \  \ \  \__/\|___ \  \_| \ \  \/  / /    \ \  \|\  \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \ \  \___|_     *
 *  \ \  \\ \  \ \  \ \   __\    \ \  \   \ \    / /      \ \  \\\  \ \   ____\   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ \_____  \    *
 *   \ \  \\ \  \ \  \ \  \_|     \ \  \   \/  /  /        \ \  \\\  \ \  \___|    \ \  \ \ \  \ \  \\\  \ \  \\ \  \|____|\  \   *
 *    \ \__\\ \__\ \__\ \__\       \ \__\__/  / /           \ \_______\ \__\        \ \__\ \ \__\ \_______\ \__\\ \__\____\_\  \  *
 *     \|__| \|__|\|__|\|__|        \|__|\___/ /             \|_______|\|__|         \|__|  \|__|\|_______|\|__| \|__|\_________\ *
 *                                      \|___|/                                                                      \|_________| *                                                                                                                               *
 **********************************************************************************************************************************/

// Contracts
import "./ERC721Upgradeable.sol";
import "./URIFetcher.sol";

// Interfaces
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
/*
 * @notice This is an options contract that allows a user to deposit a bundle of tokens for a set price that can be executed at
 *  a later time. This allows users to lend their ETH as collateral for the option and collect a premium by the
 *  option creator.
 */
contract NiftyOptions is
    ERC721Upgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    uint32 public constant ONE_YEAR = 31536000;
    uint32 public constant ONE_DAY = 86400;
    IWETH public immutable WETH;

    uint256 public optionsCount = 0;
    URIFetcher public uriFetcher;
    mapping(uint256 => OptionData) public options;

    mapping(uint256 => TokenBundle) internal _bundles;
    // Holds address of last owner for failed expired options
    mapping(uint256 => address) internal _expiredLastOwner;

    enum OptionStatus {
        unfilled,
        filled,
        exercised,
        cancelled,
        expired
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    struct TokenBundle {
        TokenType[] types;
        address[] addresses;
        uint256[] ids;
        uint256[] amounts;
    }

    struct OptionData {
        uint256 strikePriceWei;
        uint256 premiumAmountWei;
        address optionFiller;
        uint32 startTime;
        uint32 duration;
        OptionStatus status;
    }

    event OptionCreated(uint256 indexed optionId, address indexed creator);
    event OptionFilled(uint256 indexed optionId, address indexed filler);
    event OptionCancelled(uint256 indexed optionId);
    event OptionExpired(uint256 indexed optionId, address sender);
    event OptionExercised(uint256 indexed optionId);
    event OptionWithdrawn(uint256 indexed optionId);
    

    modifier onlyOptionOwner(uint256 optionId) {
        require(_msgSender() == ownerOf(optionId), "Option: not owner");
        _;
    }

    modifier withETH(uint256 amount) {
        if (amount > 0) {
            if (msg.value > 0) {
                require(
                    msg.value == amount,
                    "Option: incorrect ether value"
                );
                WETH.deposit{ value: msg.value }();
            } else {
                WETH.safeTransferFrom(_msgSender(), address(this), amount);
            }
        }

        _;
    }

    constructor(address wethAddress) {
        WETH = IWETH(wethAddress);
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
        uriFetcher = URIFetcher(_uriFetcher);
    }

    /**
     * @notice Returns the token bundle assigned to the given {optionId}.
     * @param optionId The ID to query token bundle info.
     */
    function bundleOf(uint256 optionId)
        external
        view
        returns (TokenBundle memory)
    {
        return _bundles[optionId];
    }

    /**
     * @notice Gets the contract metadata URI from the URIFetcher.
     * @return The contract URI hash
     */
    function contractURI() external view returns (string memory) {
        return uriFetcher.fetchContractURI();
    }

    /**
     * @notice Gets the token metadata URI from the URIFetcher.
     * @param tokenId Token ID to get URI for.
     * @return The token URI hash
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return uriFetcher.fetchOptionURI(tokenId);
    }

    /**
     * @notice Creates a new option for a bundle of tokens and mints an Option NFT.
     * @param bundle Data describing which tokens to create the option with.
     * @param strikePriceWei Floor price in wei for the entire token bundle.
     * @param duration Max duration, in seconds, the option will last after being filled.
     */
    function createOption(
        TokenBundle calldata bundle,
        uint256 premiumAmountWei,
        uint256 strikePriceWei,
        uint32 duration
    )
        external
        payable
        withETH(premiumAmountWei)
        returns (uint256 optionId_)
    {
        require(
            duration >= ONE_DAY && duration <= ONE_YEAR,
            "Option: invalid duration"
        );
        require(
            strikePriceWei > premiumAmountWei,
            "Option: unfavorable strike price"
        );

        // Pull the tokens into escrow
        _transferTokenBundleIn(bundle);

        // Increment ID counter
        optionId_ = optionsCount++;

        // Initialize the options struct data
        OptionData storage opt = options[optionId_];
        opt.strikePriceWei = strikePriceWei;
        opt.premiumAmountWei = premiumAmountWei;
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
    function cancelOption(uint256 optionId) external onlyOptionOwner(optionId) {
        OptionData storage opt = options[optionId];

        require(opt.status < OptionStatus.exercised, "Option: option closed");

        // Prevent re-entrancy [assume the NFT can call this method on SafeTransferFrom]
        OptionStatus originalStatus = opt.status;
        opt.status = OptionStatus.cancelled;

        // Return the NFT to the option owner
        _transferOptionBundle(optionId, ownerOf(optionId), true);

        if (originalStatus == OptionStatus.unfilled && opt.premiumAmountWei > 0) {
            // Return premium amount to the owner
            WETH.safeTransfer(ownerOf(optionId), opt.premiumAmountWei);
        } else if (originalStatus == OptionStatus.filled) {
            // Return strike value to the filler
            WETH.safeTransfer(opt.optionFiller, opt.strikePriceWei);
        }

        // Burn the option token
        _burn(optionId);

        emit OptionCancelled(optionId);
    }

    /**
     * @notice Deletes an option that is expired. Sends option token bundle back to owner and strike price to filler.
     * @param optionId The option ID to expire
     *
     * Requirements:
     *  - status must be filled
     *  - option must be expired
     */
    function expireOption(uint256 optionId) external {
        OptionData storage opt = options[optionId];

        require(opt.status == OptionStatus.filled, "Option: status not filled");
        require(
            block.timestamp >= (opt.startTime + opt.duration),
            "Option: not expired"
        );

        // Prevent re-entrancy [assume the NFT can call this method on SafeTransferFrom]
        opt.status = OptionStatus.expired;

        // Return the NFT to the option owner
        bool didFail = _transferOptionBundle(optionId, ownerOf(optionId), false);
        if (didFail) {
            _expiredLastOwner[optionId] = ownerOf(optionId);
        }

        // Return strike ether to the filler
        WETH.safeTransfer(opt.optionFiller, opt.strikePriceWei);

        // Burn the option token
        _burn(optionId);

        emit OptionExpired(optionId, _msgSender());
    }

    /**
     * @notice Fills an option with the strike price and start the expiration clock.
     * @param optionId The option ID to fill.
     *
     * Requirements:
     *  - option token must exist
     *  - status must be less than {OptionStatus.filled} enum value
     *  - {msg.value} or WETH balance approved must match {strikePrice - premiumAmount}
     */
    function fillOption(uint256 optionId)
        external
        payable
        withETH(options[optionId].strikePriceWei - options[optionId].premiumAmountWei)
    {
        OptionData storage opt = options[optionId];

        require(_exists(optionId), "Option: non-existent");
        require(opt.status < OptionStatus.filled, "Option: previously filled");

        // Start options contract
        opt.optionFiller = _msgSender();
        opt.status = OptionStatus.filled;
        opt.startTime = uint32(block.timestamp);

        emit OptionFilled(optionId, opt.optionFiller);
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
    function exerciseOption(uint256 optionId)
        external
        onlyOptionOwner(optionId)
    {
        OptionData storage opt = options[optionId];

        require(opt.status == OptionStatus.filled, "Option: status not filled");
        require(
            block.timestamp < (opt.startTime + opt.duration),
            "Option: expired"
        );

        // Prevent re-entrancy [assume the NFT can call this method on SafeTransferFrom]
        opt.status = OptionStatus.exercised;

        // Send the strike ether to the optionOwner
        WETH.safeTransfer(ownerOf(optionId), opt.strikePriceWei);

        // Send the NFT to the option filler
        _transferOptionBundle(optionId, opt.optionFiller, false);

        // Burn the option token
        _burn(optionId);

        emit OptionExercised(optionId);
    }

    /*
     * @notice Used to withdraw an expired option to the filler
     * @param optionId The option ID to exercise.
     *
     * Requirements:
     *  - status must be `exercised` OR `expired`
     */
    function withdrawExpiredOptionBundle(uint256 optionId) external {
        OptionData storage opt = options[optionId];

        address claimee;
        if (opt.status == OptionStatus.exercised) {
            claimee = opt.optionFiller;
        } else if (opt.status == OptionStatus.expired) {
            claimee = _expiredLastOwner[optionId];
        }
        // Ensure we have a valid claimee address
        require(claimee != address(0), "Option: unknown claimee");

        // Send the NFT to the claimee
        _transferOptionBundle(optionId, claimee, true);

        emit OptionWithdrawn(optionId);
    }

    /* Token Transfer Functions */

    /**
     * @dev Transfers a {tokenType} based on the encoded {data}.
     */
    function _transferToken(TokenType tokenType, bytes memory data, bool revertFail) internal returns (bool failed_) {
        failed_ = _transferToken(tokenType, data, "", revertFail);
    }

    /**
     * @dev Transfers a {tokenType} based on the encoded {details}. If token is 721 or 1155 can also pass {transferData}
     *  to send with the safe transfer call.
     *  Encoded details follows the format of:
     *      `abi.encode(from, to, token, tokenId, amount)`
     */
    function _transferToken(
        TokenType tokenType,
        bytes memory details,
        bytes memory transferData,
        bool revertFail
    ) internal returns (bool failed_) {
        (
            address from,
            address to,
            address token,
            uint256 tokenId,
            uint256 amount
        ) = abi.decode(details, (address, address, address, uint256, uint256));

        if (tokenType == TokenType.ERC721) {
            require(amount == 1, "Option: 721 amount not 1");
            try IERC721(token).safeTransferFrom(from, to, tokenId, transferData) {
            } catch (bytes memory returnData) {
                failed_ = true;
                if (revertFail) {
                    assembly {
                        let returnData_size := mload(returnData)
                        revert(add(32, returnData), returnData_size)
                    }
                }
            }
        } else if (tokenType == TokenType.ERC1155) {
            try IERC1155(token).safeTransferFrom(from, to, tokenId, amount, transferData) {
            } catch (bytes memory returnData) {
                failed_ = true;
                if (revertFail) {
                    assembly {
                        let returnData_size := mload(returnData)
                        revert(add(32, returnData), returnData_size)
                    }
                }
            }
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
            bytes memory data = abi.encode(
                _msgSender(),
                address(this),
                bundle.addresses[i],
                bundle.ids[i],
                bundle.amounts[i]
            );
            _transferToken(
                bundle.types[i],
                data,
                abi.encode(_encodeTokenTransferData()),
                true
            );
        }
    }

    /**
     * @dev Transfers an option's token bundle {to} a specified recipient.
     * @param optionId The option ID to get token bundle details.
     * @param to Address to receive the token bundle.
     */
    function _transferOptionBundle(uint256 optionId, address to, bool revertFail) internal returns (bool failed_) {
        TokenBundle storage bundle = _bundles[optionId];
        for (uint256 i; i < bundle.types.length; i++) {
            bytes memory data = abi.encode(
                address(this),
                to,
                bundle.addresses[i],
                bundle.ids[i],
                bundle.amounts[i]
            );
            bool didFail = _transferToken(bundle.types[i], data, revertFail);
            if (!failed_ && didFail) {
                failed_ = true;
            }
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
        require(
            abi.decode(data, (bytes32)) == _encodeTokenTransferData(),
            "Option: invalid deposit"
        );
    }

    /**
     * @dev See {IERC721-onERC721Received}
     */
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
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
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata data
    ) external view override returns (bytes4) {
        _verifyNFTData(data);

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @dev See {IERC721-onERC1155BatchReceived}
     */
    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        uint256[] calldata, /* values */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return "";
    }
}
