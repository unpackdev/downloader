// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

interface ISlimeProducer {
    function getCreationTime(uint256 tokenId) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Ooze is ERC20Burnable, Ownable {
    

    uint256 constant REWARD_END_DATE = 1957967999;

    //address -> rate
    mapping(address => uint256) _slimeProducers;
    //address -> id -> payout amount
    mapping(address => mapping(uint256 => uint256)) _payouts;

    /**
     * @dev Returns the smallest integer between two integers
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) return a;
        return b;
    }

    constructor() ERC20("Ooze", "OOZE") {}

    /** @dev Add/Update the `_slimeProducers` with key `producerAddress` and value `rate`
     * Requirements:
     *
     * - `producerAddress` cannot be the zero address.
     */
    function setProducer(address producerAddress, uint256 rate)
        external
        onlyOwner
    {
        require(producerAddress != address(0x0), "cannot be an empty contract");
        _slimeProducers[producerAddress] = rate;                
    }

    /** @dev Get the unclaim ooze of the producer address and its token id based on time
     * Get the total claimable ooze from creation time until current time with a span of 1 year excluded the claimed ooze
     * Requirements:
     *
     * - `producerAddress` should whitelisted
     *   @param producerAddress contract address of producer of ooze
     *   @param tokenId  nft token id of producer of ooze
     */
    function getUnclaimedOoze(address producerAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            _slimeProducers[producerAddress] != 0,
            "not a valid Slime Producer Contract"
        );
        return (
            (min(block.timestamp, REWARD_END_DATE)
                 - (ISlimeProducer(producerAddress).getCreationTime(tokenId)))
                / (1 days)
                *  (_slimeProducers[producerAddress])
                - (_payouts[producerAddress][tokenId])
        );
    }

    /** @dev Claim the ooze produce by the producerAddress and increase the total produce
     *
     * Emits an {Claimed} event indicating the claim ooze
     *
     * Requirements:
     *
     * - sender should owned the `tokenId`
     *   @param producerAddress contract address of producer of ooze
     *   @param tokenId  nft token id of producer of ooze
     */
    function claim(address producerAddress, uint256 tokenId) public {
        require(
            msg.sender == ISlimeProducer(producerAddress).ownerOf(tokenId),
            "not the owner of the token"
        );
        uint256 available = getUnclaimedOoze(producerAddress, tokenId);
        if (available > 0) {
            _payouts[producerAddress][tokenId] = _payouts[producerAddress][
                tokenId
            ] + available;
            _mint(msg.sender, available);
        }
    }

    /** @dev Claim all the ooze produce by the producerAddress for each `tokenIds`
     *   @param producerAddress contract address of producer of ooze
     *   @param tokenIds  array of tokenIds
     */
    function claimAll(address producerAddress, uint256[] memory tokenIds)
        external
    {
        uint256 owned = ISlimeProducer(producerAddress).balanceOf(msg.sender);        
        if (owned >= tokenIds.length) {
            uint256 total = 0;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(
                    msg.sender ==
                        ISlimeProducer(producerAddress).ownerOf(tokenIds[i]),
                    "not the owner of the token"
                );
                uint256 available = getUnclaimedOoze(
                    producerAddress,
                    tokenIds[i]
                );
                if (available > 0) {
                    _payouts[producerAddress][tokenIds[i]] = _payouts[
                        producerAddress
                    ][tokenIds[i]]+ available;
                    total += available;
                }
            }            
            if (total > 0) {
                _mint(msg.sender, total);
            }
        }
    }
}
