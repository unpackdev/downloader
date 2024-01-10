// SPDX-License-Identifier: APGL-3.0-only
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";

/// @title ElyGenesisCollection
/// @notice Minting contract for Ely's Genesis Collection (https://twitter.com/ratkingnft).
/// @author 0xMetas (https://twitter.com/0xMetas)
contract ElyGenesisCollection is ERC1155, Ownable {
    //////////////////////
    /// External State ///
    //////////////////////

    /// @notice The name of the contract.
    /// @dev EIP-1155 doesn't define `name()` so that the metadata JSON returned by `uri` is
    /// the definitive name, but it's provided for compatibility with existing front-ends.
    string public constant name = "Ely Genesis Collection"; // solhint-disable-line const-name-snakecase

    /// @notice The symbol of the contract.
    /// @dev EIP-1155 doesn't define `symbol()` because it isn't a "globally useful piece of
    /// data", but, again, it's provided for compatibility with existing front-ends.
    string public constant symbol = "ELYGENESIS"; // solhint-disable-line const-name-snakecase

    /// @notice The price of each token.
    uint256 public constant PRICE = 0.05 ether;

    /// @notice The maximum supply of all tokens.
    uint256 public constant MAX_SUPPLY = 500;

    /// @notice The maximum supply of each token.
    uint256 public constant MAX_SUPPLY_PER_ID = 100;

    /// @notice True if the metadata (URI) can no longer be modified.
    bool public metadataFrozen = false;

    /// @notice The maximum number of tokens you can purchase in a single transaction.
    uint256 public transactionLimit = 3;

    /// @notice True if the sale is open.
    bool public purchaseable = false;

    /// @notice The total supply of all tokens.
    /// @dev EIP-1155 requires enumeration off-chain, but the contract provides `totalSupplyAll`
    /// for convenience, and compatibility with marketplaces and other front-ends.
    uint256 public totalSupplyAll = 0;

    /// @notice The total supply of an individual token.
    /// @dev See `totalSupplyAll`.
    uint8[5] public totalSupply;

    //////////////////////
    /// Internal State ///
    //////////////////////

    /// @dev The ids available to mint. This array is used when generating a random index for the mint.
    /// Ids are removed from this array when their max amount has been minted.
    uint8[] private availableIds = [0, 1, 2, 3, 4];

    /// @dev The 'dynamic' length of the `availableIds` array. Since it's a static array, it's actual
    /// length cannot be modified, so this variable is used instead.
    uint8 private availableIdsLength = 5;

    /// @dev The base of the generated URI returned by `uri(uint256)`.
    string private baseUri;

    //////////////
    /// Errors ///
    //////////////

    error WithdrawFail();
    error FrozenMetadata();
    error NotPurchaseable();
    error SoldOut();
    error InsufficientValue();
    error InvalidPurchaseAmount();
    error ExternalAccountOnly();

    //////////////
    /// Events ///
    //////////////

    event PermanentURI(string uri, uint256 indexed id);
    event Purchaseable(bool state);
    event TransactionLimit(uint256 previousLimit, uint256 newLimit);

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    /// @notice Purchase `amount` number of tokens.
    /// @param amount The number of tokens to purchase.
    function purchase(uint256 amount) public payable {
        if (!purchaseable) revert NotPurchaseable();
        if (amount + totalSupplyAll > MAX_SUPPLY) revert SoldOut();
        if (msg.value != amount * PRICE) revert InsufficientValue();
        if (msg.sender.code.length != 0) revert ExternalAccountOnly();
        if (amount > transactionLimit || amount < 1)
            revert InvalidPurchaseAmount();

        for (uint256 i; i < amount; ) {
            uint256 idx = getPseudorandom() % availableIdsLength;
            uint256 id = availableIds[idx];

            _mint(msg.sender, id, 1, "");

            // `totalSupplyAll` needs to be incremented in the loop to provide a unique nonce for
            // each call to `getPseudorandom()`.
            unchecked {
                ++i;
                ++totalSupplyAll;
                ++totalSupply[id];
            }

            // Remove the token from `availableIds` if it's reached the supply limit
            if (totalSupply[id] == MAX_SUPPLY_PER_ID) removeIndex(idx);
        }
    }

    /// @notice Returns a deterministically generated URI for the given token ID.
    /// @return string
    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, toString(id), ".json"))
                : "";
    }

    //////////////////////
    /// Administration ///
    //////////////////////

    /// @notice Prevents any future changes to the URI of any token ID.
    /// @dev Emits a `PermanentURI(string, uint256 indexed)` event for each token ID with the permanent URI.
    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
        for (uint256 i = 0; i < 5; ++i) {
            emit PermanentURI(uri(i), i);
        }
    }

    /// @notice Updates the base of the generated URI returned by `uri(uint256)`.
    /// @dev The URI event isn't emitted because there is no applicable ID to emit the event for. The
    /// baseURI given here applies to all token IDs.
    function setBaseUri(string memory newBaseUri) public onlyOwner {
        if (metadataFrozen == true) revert FrozenMetadata();
        baseUri = newBaseUri;
    }

    /// @notice Sets the current state of the sale. `false` will disable sale, `true` will enable it.
    function setPurchaseable(bool state) public onlyOwner {
        purchaseable = state;
        emit Purchaseable(purchaseable);
    }

    /// @notice Withdraws entire balance of this contract to the `owner` address.
    function withdrawEth() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert WithdrawFail();
    }

    /// @notice Sets the maximum purchase amount per transaction.
    function setTransactionLimit(uint256 newTransactionLimit) public onlyOwner {
        emit TransactionLimit(transactionLimit, newTransactionLimit);
        transactionLimit = newTransactionLimit;
    }

    ////////////////
    /// Internal ///
    ////////////////

    /// @dev Generates a pseudorandom number to use when determining an ID for purchase. True randomness isn't
    /// necessary because IDs have no rarity (no ID is inherently more valuable than another).
    function getPseudorandom() internal view returns (uint256) {
        // solhint-disable not-rely-on-time
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            msg.sender,
                            totalSupplyAll
                        )
                    )
                );
        }
        // solhint-enable not-rely-on-time
    }

    /// @dev Removes the specified index from the `availableIds` array. This function is used when the max supply
    /// of the token ID at `index` has already been purchased. The index isn't checked because useage is internal.
    function removeIndex(uint256 index) internal {
        availableIds[index] = availableIds[availableIdsLength - 1];
        availableIdsLength--;
    }

    /// @dev Taken from OpenZeppelin's implementation
    /// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol)
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
