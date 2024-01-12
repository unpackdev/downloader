// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Proof Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import "./NextShuffler.sol";
import "./PRNG.sol";
import "./IERC721.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/**
@title RandomDistributor
@notice Randomly distributes a set of ERC721 tokens to a set of recipients.
@dev To allow for reuse behind a minimal proxy contract, this contract uses the
upgradeable pattern so has an initialize() function instead of a constructor.
 */
contract RandomDistributor is Initializable, OwnableUpgradeable, NextShuffler {
    using PRNG for PRNG.Source;

    /**
    @dev ERC721 token contract from which tokens are distributed.
     */
    IERC721 token;

    /**
    @dev Initializer in lieu of a constructor.
    @param _token The contract from which tokens will be distributed.
    @param numToDistribute Number of tokens that this RandomDistributor will
    distribute.
     */
    function initialize(IERC721 _token, uint256 numToDistribute)
        public
        initializer
    {
        token = _token;
        OwnableUpgradeable.__Ownable_init();
        NextShuffler.initialize(numToDistribute);
    }

    /**
    @dev A recipient address coupled with the number of tokens they receive.
     */
    struct Recipient {
        address receiver;
        uint96 count;
    }

    /**
    @dev Distributes tokens, randomly selected from the IDs, to the recipients.
    @param from The owner of the tokenIds; which must have allowed this contract
    with setApproveForAll().
    @param recipients Set of recipients receiving a random selection from
    ``tokenIds``, typically different on each call to distribute().
    @param tokenIds The IDs of the tokens to be transferred. These MUST be
    identical on each call to distribute().
     */
    function distribute(
        address from,
        Recipient[] calldata recipients,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        require(
            tokenIds.length == numToShuffle,
            "RandomDistributor: tokenIds.length invalid"
        );

        uint256 shuffled_ = shuffled;
        uint256 numToShuffle_ = numToShuffle;
        {
            uint256 total = 0;
            for (uint256 i = 0; i < recipients.length; ++i) {
                total += uint256(recipients[i].count);
            }
            require(
                shuffled_ + total <= numToShuffle_,
                "RandomDistributor: too many distributed"
            );
            shuffled = shuffled_ + total;
        }

        IERC721 token_ = token;
        PRNG.Source src = PRNG.newSource(
            keccak256(
                abi.encode(
                    block.number,
                    block.coinbase,
                    recipients[0],
                    address(this)
                )
            )
        );

        // This comes straight from the ethier NextShuffler, modified to not
        // require multiple function calls.
        for (uint256 i = 0; i < recipients.length; ++i) {
            uint256 n = uint256(recipients[i].count);
            address to = recipients[i].receiver;

            for (uint256 j = 0; j < n; ++j) {
                uint256 next = src.readLessThan(numToShuffle_ - shuffled_) +
                    shuffled_;

                token_.transferFrom(from, to, tokenIds[_get(next)]);

                _set(next, _get(shuffled_));
                ++shuffled_;
            }
        }
    }
}
