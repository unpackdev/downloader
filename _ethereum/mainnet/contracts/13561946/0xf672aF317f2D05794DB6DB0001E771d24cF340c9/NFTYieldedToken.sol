// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./TimeYieldedCredit.sol";
import "./UtilityToken.sol";
import "./IERC721Enumerable.sol";
import "./IERC721.sol";

interface NFTContract is IERC721, IERC721Enumerable {}

/// @custom:security-contact astridfox@protonmail.com
contract NFTYieldedToken is UtilityToken, TimeYieldedCredit {
    
    // The ERC721 NFT contract whose tokens are yielded this token 
    NFTContract public nftContract;

    constructor(
        string memory name,
        string memory symbol,
        address admin,
        address pauser,
        address minter,
        address yieldManager,
        uint256 yieldStep_,
        uint256 yield_,
        uint256 epoch_,
        uint256 horizon_,
        address nftContractAddress)
        UtilityToken(name, symbol, admin, pauser, minter)
        TimeYieldedCredit(yieldManager, yieldStep_, yield_, epoch_, horizon_)
        {
            nftContract = NFTContract(nftContractAddress);
        }

        /**
         * @dev Returns the amount claimable by the owner of `tokenId`.
         *
         * Requirements:
         *
         * - `tokenId` must exist.
         */
        function getClaimableAmount(uint256 tokenId) external view returns (uint256) {
            require(tokenId < nftContract.totalSupply(), "NFTYieldedToken: Non-existent tokenId");
            return _creditFor(tokenId);
        }

        /**
         * @dev Returns an array of amounts claimable by `addr`.
         * If `addr` doesn't own any tokens, returns an empty array.
         */
        function getClaimableForAddress(address addr) external view returns (uint256[] memory, uint256[] memory) {
            uint256 balance = nftContract.balanceOf(addr);
            uint256[] memory balances = new uint256[](balance);
            uint256[] memory tokenIds = new uint256[](balance);

            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = nftContract.tokenOfOwnerByIndex(addr, i);
                balances[i] = _creditFor(tokenId);
                tokenIds[i] = tokenId;
            }

            return (balances, tokenIds);
        }

        /**
         * @dev Spends `amount` credit from `tokenId`'s balance -
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spend}
         */
        function spend(
            uint256 tokenId,
            uint256 amount,
            uint256 serviceId,
            bytes calldata data
        ) public {
            _spend(tokenId, amount);
            
            emit TokenSpent(msg.sender, amount, serviceId, data);
        }

        /**
         * @dev Claims `amount` credit as tokens from `tokenId`'s balance.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spend}
         */
        function claim(uint256 tokenId, uint256 amount) public {
            _spend(tokenId, amount);

            _mint(msg.sender, amount);
        }

        /**
         * @dev Spends `amount` credit from `tokenId`'s balance.
         *
         * Requirements:
         *
         * - The caller must own `tokenId`.
         *
         * - `tokenId` must exist.
         *
         * - `tokenId` must have at least `amount` of credit available.
         */
        function _spend(uint256 tokenId, uint256 amount) internal {
            require(msg.sender == nftContract.ownerOf(tokenId), "NFTYieldedToken: Not owner of token");

            _spendCredit(tokenId, amount);
        }

        /**
         * @dev Spends `amount` credit from `tokenId`'s balance on behalf of `account`-
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendFrom}
         */
        function spendFrom(
            address account,
            uint256 tokenId,
            uint256 amount,
            uint256 serviceId,
            bytes calldata data
        ) public {
            _spendFrom(account, tokenId, amount);

            emit TokenSpent(account, amount, serviceId, data);
        }

        /**
         * @dev Claims `amount` credit as tokens from `tokenId`'s balance on behalf of `account`-
         * The tokens are minted to the address `to`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendFrom}
         */
        function claimFrom(
            address account,
            uint256 tokenId,
            uint256 amount,
            address to
        ) public {
            _spendFrom(account, tokenId, amount);

            _mint(to, amount);
        }


        /**
         * @dev Spends `amount` credit from `tokenId`'s balance on behalf of `account`.
         *
         * Requirements:
         *
         * - `account` must own `tokenId`.
         *
         * - `tokenId` must exist.
         *
         * - The caller must have allowance for `accounts`'s tokens of at least
         * `amount`.
         */
        function _spendFrom(
            address account,
            uint256 tokenId,
            uint256 amount
        ) internal {
            require(account == nftContract.ownerOf(tokenId), "NFTYieldedToken: Not owner of token");
            uint256 currentAllowance = allowance(account, msg.sender);
            require(currentAllowance >= amount, "NFTYieldedToken: spend amount exceeds allowance");

            unchecked {
                _approve(account, msg.sender, currentAllowance - amount);
            }

            _spendCredit(tokenId, amount);
        }

        /**
         * @dev Spends credit from multiple `tokenIds` as specified by `amounts`-
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendMultiple}
         */
        function spendMultiple(
            uint256[] calldata tokenIds,
            uint256[] calldata amounts,
            uint256 serviceId,
            bytes calldata data
        ) public {
            uint256 totalSpent = _spendMultiple(msg.sender, tokenIds, amounts);

            emit TokenSpent(msg.sender, totalSpent, serviceId, data);
        }

        /**
         * @dev Spends credit from multiple `tokenIds` - owned by `account` - as specified by `amounts`-
         * for the consumption of an external service identified by `serviceId`.
         * Optionally sending additional `data`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendMultiple}
         */
        function externalSpendMultiple(
            address account,
            uint256[] calldata tokenIds,
            uint256[] calldata amounts,
            uint256 serviceId,
            bytes calldata data
        ) external onlyRole(EXTERNAL_SPENDER_ROLE) {
            uint256 totalSpent = _spendMultiple(account, tokenIds, amounts);

            emit TokenSpent(account, totalSpent, serviceId, data);
        }

        /**
         * @dev Claims credit as tokens from multiple `tokenIds` as specified by `amounts`.
         *
         * Requirements:
         *
         * See {NFTYieldedToken._spendMultiple}
         */
        function claimMultiple(
            uint256[] calldata tokenIds,
            uint256[] calldata amounts
        ) public {
            uint256 totalSpent = _spendMultiple(msg.sender, tokenIds, amounts);

            _mint(msg.sender, totalSpent);
        }

        /**
         * @dev Spends credit from multiple `tokenIds` as specified by `amounts`.
         * Returns the total amount spent.
         *
         * Requirements:
         *
         * - `account` must own all of the tokens in the `tokenIds` array.
         *
         * - All tokens in `tokenIds` must exist.
         *
         * - All tokens must have available credit greater than or equal to the corresponding amounts to transact.
         */
        function _spendMultiple(
            address account,
            uint256[] calldata tokenIds,
            uint256[] calldata amounts
        ) internal returns (uint256) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(account == nftContract.ownerOf(tokenIds[i]), "NFTYieldedToken: Not owner of token");
            }

            return _spendCreditBatch(tokenIds, amounts);
        }

        /**
         * @dev Claims all the available credit as the token for `tokenId`.
         *
         * Requirements:
         *
         * - The caller must own `tokenId`.
         *
         * - `tokenId` must exist.
         */
        function claimAll(uint256 tokenId) public {
            require(msg.sender == nftContract.ownerOf(tokenId), "NFTYieldedToken: Not owner of token");
            uint256 amount = _spendAll(tokenId);

            _mint(msg.sender, amount);
        }
}