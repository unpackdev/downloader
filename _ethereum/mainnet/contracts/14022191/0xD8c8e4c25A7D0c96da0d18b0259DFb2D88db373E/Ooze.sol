// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SlimeProducer.sol";

contract Ooze is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 constant REWARD_END_DATE = 1957967999;

    event Claimed(
        address indexed tokenContract,
        address indexed claimant,
        uint256 indexed tokenId,
        uint256 amount
    );

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

    constructor() ERC20("Ooze", "OOZ") {}

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
            min(block.timestamp, REWARD_END_DATE).sub(
                    SlimeProducer(producerAddress).getCreationTime(tokenId)                
            ).div(1 days).mul(_slimeProducers[producerAddress]).sub(_payouts[producerAddress][tokenId])
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
            msg.sender == SlimeProducer(producerAddress).ownerOf(tokenId),
            "not the owner of the token"
        );
        uint256 available = getUnclaimedOoze(producerAddress, tokenId);
        if (available > 0 ) {
          _payouts[producerAddress][tokenId] =
              _payouts[producerAddress][tokenId].add(available);
          _mint(msg.sender, available);
          emit Claimed(producerAddress, msg.sender, tokenId, available);
        }
    } 

    /** @dev Claim all the ooze produce by the producerAddress for each `tokenIds`
    *   @param producerAddress contract address of producer of ooze
    *   @param tokenIds  array of tokenIds
    */
    function claimAll(address producerAddress, uint256[] memory tokenIds) external {
        uint256 owned = IERC721(producerAddress).balanceOf(msg.sender);
        if (owned <= tokenIds.length) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                claim(
                    producerAddress,                                                
                        tokenIds[i]
                    );                
            }
        }
    }
}
