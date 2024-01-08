// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ERC165Storage.sol";

import "./Fields.sol";

abstract contract Base is
    Ownable,
    Fields,
    ERC165Storage,
    ERC721Pausable,
    ERC721Enumerable
{
    /*
     * accepts ether sent with no txData
     */
    receive() external payable {}

    /*
     * refuses ether sent with txData that does not match any function signature in the contract
     */
    fallback() external {}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
        super._unpause();
    }

    function setDepositor(IDepositor depositor_) public onlyOwner {
        depositor = depositor_;
    }

    function setSoulToken(ISoulToken soulToken_) public onlyOwner {
        soulToken = soulToken_;
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the ProxyRegistry of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev baseURI for computing {tokenURI}. Empty by default, can be overwritten
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC165Storage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Send an amount of value to a specific address
     * @param to_ address that will receive the value
     * @param value to be sent to the address
     */
    function sendValueTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, FUNCTION_CALL_ERROR);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Pausable, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Set the baseURI to a given uri
     * @param baseURI_ string to save
     */
    function changeBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Get the list of tokens for a specific owner
     * @param _owner address to retrieve token ids for
     */
    function tokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * @dev Withdraw remaining contract balance to owner
     */
    function withdrawRemainingContractBalance() public onlyOwner {
        uint256 remainingBalance = address(this).balance;
        for (uint8 i; i < currentTeamBalance.length; i++) {
            remainingBalance -= currentTeamBalance[i];
        }
        require(remainingBalance > 0, NO_BALANCE);
        sendValueTo(owner(), remainingBalance);
    }

    /**
     * Get random index and save it
     */
    function randomId() internal returns (uint256) {
        uint256 totalSize = 1000 -
            totalSupply() -
            numberOfReservedTeamCustomTokens;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    block.coinbase,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;

        totalSize--;
        uint256 value;

        uint256 currentValue = indices[index];
        if (currentValue != 0) {
            value = currentValue;
        } else {
            value = index;
        }
        uint16 currentLastValue = indices[totalSize];
        // Move last value to selected position
        if (currentLastValue == 0) {
            // Array position not initialized, so use position
            indices[index] = uint16(totalSize);
        } else {
            // Array position holds a value so use that
            indices[index] = currentLastValue;
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    /**
     * Set token index id
     */
    function setTokenId(uint256 tokenId) internal {
        uint256 totalSize = 1000 - totalSupply() - tokenId;
        indices[tokenId - 1] = uint16(totalSize);
        nonce++;
        numberOfReservedTeamCustomTokens++;
    }

    function limitMaxWhitelistTokensTo(uint256 maxTokens) public onlyOwner {
        MAX_WHITELIST_TOKENS = maxTokens;
    }

    function limitMaxTokensTo(uint256 maxTokens) public onlyOwner {
        require(
            totalSupply() + MAX_RESERVED_TOKENS - mintedReservedTokens <=
                maxTokens,
            "Invalid number of tokens"
        );
        MAX_TOKENS = maxTokens;
    }
}
