// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";

contract Mission1 is IERC721Receiver, ReentrancyGuard {
    IERC721 public _xoids;
    IERC20 public _ctzn;
    address public _admin;

    mapping(uint256 => uint256) private rewards;
    mapping(address => uint256) public rewardsClaimed;
    uint256 public _lockupPeriod = 30 days;

    struct Stake {
        uint256[] id;
        uint256 start;
        uint256 end;
    }
    // TokenID => Stake
    mapping(address => Stake[]) private receipt;

    constructor(IERC721 xoids_, IERC20 ctzn_) {
        _admin = msg.sender;
        _xoids = xoids_;
        _ctzn = ctzn_;
    }

    modifier requireTimeElapsed(uint256 depositId) {
        // require that some time has elapsed
        require(
            block.timestamp > receipt[msg.sender][depositId].end,
            "requireTimeElapsed: cannot unstake before end time"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "reclaimTokens: Caller is not the ADMIN");
        _;
    }

    //User must give this contract permission to take ownership of it.
    function stakeNFT(uint256[] calldata tokenId) public nonReentrant {
        // allow for staking three NFTS at one time.
        require(tokenId.length == 3, "Can stake 3 NFTs only");

        for (uint256 i = 0; i < tokenId.length; i++) {
            // take possession of the NFT
            _xoids.safeTransferFrom(msg.sender, address(this), tokenId[i]);
        }
        receipt[msg.sender].push(
            Stake({
                id: tokenId,
                start: block.timestamp,
                end: block.timestamp + _lockupPeriod
            })
        );
    }

    function unStakeNFT(uint256 depositId)
        external
        nonReentrant
        requireTimeElapsed(depositId)
    {
        Stake memory deposit = receipt[msg.sender][depositId];
        // payout stake, this should be safe as the function is non-reentrant
        _payoutStake(depositId);

        // return token
        for (uint256 indx = 0; indx < deposit.id.length; indx++) {
            _xoids.safeTransferFrom(
                address(this),
                msg.sender,
                deposit.id[indx]
            );
        }

        receipt[msg.sender][depositId] = receipt[msg.sender][
            receipt[msg.sender].length - 1
        ];
        receipt[msg.sender].pop();
    }

    function _payoutStake(uint256 depositId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/

        uint256 payout = cumulativeRewardsOf(depositId);

        // If contract does not have enough tokens to pay out, return the NFT without payment
        // This prevent a NFT being locked in the contract when empty
        if (_ctzn.balanceOf(address(this)) < payout) {
            return;
        }

        // payout stake
        _transferToken(msg.sender, payout);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function cumulativeRewardsOf(uint256 depositId)
        public
        view
        returns (uint256)
    {
        Stake memory deposit = receipt[msg.sender][depositId];
        uint256 cumulativeRewards;
        for (uint256 indx = 0; indx < deposit.id.length; indx++) {
            cumulativeRewards += rewards[deposit.id[indx]];
        }
        return cumulativeRewards;
    }

    function _transferToken(address to, uint256 amount) private {
        _ctzn.transfer(to, amount);
    }

    function setRewardPerTokenId(
        uint256[] calldata tokenId,
        uint256[] calldata rewardAmount
    ) external onlyAdmin {
        require(tokenId.length == rewardAmount.length, "length not matched");

        for (uint256 indx = 0; indx < tokenId.length; indx++) {
            rewards[tokenId[indx]] = rewardAmount[indx];
        }
    }

    function setLockupTime(uint256 newLockTime) external onlyAdmin {
        _lockupPeriod = newLockTime;
    }

    function getRewardPerTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return rewards[tokenId];
    }

    function getStakeContractBalance() public view returns (uint256) {
        return _ctzn.balanceOf(address(this));
    }

    function reclaimTokens() external onlyAdmin {
        _ctzn.transfer(_admin, _ctzn.balanceOf(address(this)));
    }

    function getUserDeposits(address user)
        external
        view
        returns (Stake[] memory)
    {
        return receipt[user];
    }
}
