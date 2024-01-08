// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Address.sol";

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title Samot Staking
 * SamotStaking - a contract for the Samot NFT Staking
 */
abstract contract SamotToken {
    function claim(address account, uint256 amount) external {}
}
abstract contract SamotNFT {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function isApprovedForAll(address owner, address operator)
        external
        view
        virtual
        returns (bool);
}
contract SamotStakingF is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    //addresses
    address public stakingDestinationAddress;
    address public erc20Address;

    //uint256's
    //rate governs how often you receive your token
    uint256 public rate;

    SamotToken token;
    SamotNFT nft;

    // mappings
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    constructor(
        address _stakingDestinationAddress,
        uint256 _rate,
        address _erc20Address
    ) {
        stakingDestinationAddress = _stakingDestinationAddress;
        rate = _rate;
        token = SamotToken(_erc20Address);
        nft=SamotNFT(_stakingDestinationAddress);
        _pause();
    }

    function setTokenContract(address _erc20Address) external onlyOwner {
        token = SamotToken(_erc20Address);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /* STAKING MECHANICS */

    // Set a multiplier for how many tokens to earn each time a block passes.
    // 1 $AMOT PER DAY
    // n Blocks per day= 6000, Token Decimal = 18
    // Rate = 238095238100000
    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    //Checks staked amount
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    //Calculate rewards amount by address/tokenIds[]
    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            rewards[i] =
                rate *
                (_deposits[account].contains(tokenId) ? 1 : 0) *
                (block.number - _depositBlocks[account][tokenId]);
        }

        return rewards;
    }

    //Reward amount by address/tokenId
    function calculateReward(address account, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            block.number > _depositBlocks[account][tokenId],
            "Invalid blocks"
        );
        return
            rate *
            (_deposits[account].contains(tokenId) ? 1 : 0) *
            (block.number - _depositBlocks[account][tokenId]);
    }

    //reward claim function
    function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
        uint256 reward;
        uint256 blockCur = block.number;

        for (uint256 i; i < tokenIds.length; i++) {
            reward += calculateReward(msg.sender, tokenIds[i]);
            _depositBlocks[msg.sender][tokenIds[i]] = blockCur;
        }

        if (reward > 0) {
            token.claim(msg.sender, reward);
        }
    }

    //Staking function
    function stake(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                nft.ownerOf(tokenIds[i]) == msg.sender,
                "You do not own this NFT."
            );
            require(
                nft.isApprovedForAll(msg.sender, address(this)),
                "This contract is not approved to transfer your NFT."
            );
        }
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(stakingDestinationAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );
            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    //Unstaking function
    function unstake(uint256[] calldata tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Staking: token not deposited"
            );
            _deposits[msg.sender].remove(tokenIds[i]);
            IERC721(stakingDestinationAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
