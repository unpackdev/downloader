// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC721AQueryable.sol";

// import "./console.sol";

error AlreadyClaimed();
error ArrayLengthMismatch();
error DuplicateAddress();
error IncorrectETH();
error InsufficientCredits();
error InvalidSignature();
error QuantityExceedsMax();

/**
 * @title DigiBitties 1337 Collection
 * @author Digitz @digitz
 * @notice See: https://digibitties.com
 */

contract DigiBitties is Ownable, ERC721AQueryable {
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    string private baseURI; // Private to reduce gas.
    mapping(address => uint64) public teamCredits;
    mapping(address => bool) public alreadyClaimed;

    // All 3 of these are packed into a single uint256 slot.
    uint64 public constant MAX_SUPPLY = 13337;
    uint64 public constant CLAIM_REWARD = 1;
    uint128 public price; // Max price in ether: 340282366920938463463.374607431768211456

    /* Events */
    event PriceChange(uint256 oldPrice, uint256 newPrice);
    event BaseURIChange(string oldUri, string newUri);
    event TeamClaim(address claimant, uint256 oldCredit, uint256 newCredit);
    event UserClaim(address claimant); // only 1 can be claimed
    event Withdraw(address owner, uint256 amount);
    event WithdrawTokens(address owner, address tokenAddress, uint256 amount);

    /* Modifiers */
    modifier belowMax(uint256 _quantity) {
        if (_nextTokenId() + _quantity > _startTokenId() + MAX_SUPPLY) revert QuantityExceedsMax();
        _;
    }

    /**
     * @param _addresses An array of team addresses which will be granted credits.
     * @param _credits An array of team credit amounts, index aligned with _addresses.
     */
    constructor(
        address[] memory _addresses,
        uint64[] memory _credits,
        uint128 _price
    ) ERC721A("DigiBitties 1337 Collection", "DB1") {
        if (_addresses.length != _credits.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (teamCredits[_addresses[i]] != 0) revert DuplicateAddress();
            teamCredits[_addresses[i]] = _credits[i];
            emit TeamClaim(_addresses[i], 0, teamCredits[_addresses[i]]);
        }
        price = _price;
        emit PriceChange(0, price);
        baseURI = "ipfs://QmTb7EKyRArWW1AboBnYhyg7jmJFTsAgdVHK4jYiZJVA4v/json/";
        emit BaseURIChange("", baseURI);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @param _price The price per NFT in wei.
     */
    function setPrice(uint128 _price) external onlyOwner {
        emit PriceChange(uint256(price), uint256(_price));
        price = _price;
    }

    /**
     * @param _quantity The amount of NFTs to mint using credits.
     */
    function teamMint(uint64 _quantity) external belowMax(_quantity) {
        uint64 credits = teamCredits[_msgSender()];
        if (credits < _quantity) revert InsufficientCredits();
        teamCredits[_msgSender()] -= _quantity;
        _safeMint(_msgSender(), _quantity);
    }

    /**
     * @param _signature The message containing the user address signed by the owner.
     */
    function claim(bytes calldata _signature) external belowMax(CLAIM_REWARD) {
        if (alreadyClaimed[_msgSender()]) revert AlreadyClaimed();
        alreadyClaimed[_msgSender()] = true;
        if (
            owner() !=
            bytes32(uint256(uint160(_msgSender())))
                .toEthSignedMessageHash()
                .recover(_signature)
        ) revert InvalidSignature();
        _safeMint(_msgSender(), CLAIM_REWARD);
    }

    /**
     * @param _quantity The amount of NFTs to mint using ETH.
     */
    function mint(uint256 _quantity) external payable belowMax(_quantity) {
        if (msg.value != _quantity * price) revert IncorrectETH();
        _safeMint(_msgSender(), _quantity);
    }

    /**
     * @return The baseURI is used in assembling the URI to the metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _rootURI) external onlyOwner {
        emit BaseURIChange(baseURI, _rootURI);
        baseURI = _rootURI;
    }

    /**
     * @notice Receive ETH (no calldata).
     */
    receive() external payable {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Receive ETH (with calldata).
     */
    fallback() external payable {}

    /**
     * @notice ERC20 sent directly to the contract can be withdrawn.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of the ERC20 token to withdraw.
     */
    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        emit WithdrawTokens(owner(), _token, _amount);
        IERC20(_token).safeTransfer(owner(), _amount);
    }

    /**
     * @notice ETH sent directly to the contract can be withdrawn.
     */
    function withdraw() external onlyOwner {
        emit Withdraw(owner(), address(this).balance);
        payable(owner()).transfer(address(this).balance);
    }
}
