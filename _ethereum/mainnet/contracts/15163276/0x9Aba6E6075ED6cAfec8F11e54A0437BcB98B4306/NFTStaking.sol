// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IBotXNFT.sol";
import "./IBotXToken.sol";

contract NFTStaking is Ownable, Pausable {
    using SafeMath for uint256;

    struct Stake {
        uint256 tokenId;
        address owner;
        uint256 lastClaimTime;
    }

    IBotXNFT public botXNFT;
    IBotXToken public botXToken;
    mapping(uint256 => Stake) public botXPolls;
    mapping(address => uint256[]) public stakedNFTs;
    mapping(uint256 => uint256) public stakedNFTsIndices;
    uint256 public stakedBot;
    uint256 public CLAIM_AMOUNT_1 = 3 ether;
    uint256 public CLAIM_AMOUNT_2 = 4 ether;
    uint256 public CLAIM_AMOUNT_3 = 5 ether;
    uint256 public CLAIM_AMOUNT_4 = 7 ether;

    event TokenStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 lastClaimTime
    );

    constructor(IBotXNFT _botXNFT, IBotXToken _botXToken) {
        botXNFT = _botXNFT;
        botXToken = _botXToken;
        _pause();
    }

    function getPollInfo(uint8 id) public view returns (Stake memory) {
        return botXPolls[id];
    }

    function addManyToPoll(address account, uint256[] calldata tokenIds)
        public
    {
        require(tx.origin == _msgSender(), "NFTStaking: Only EOA");
        require(account == tx.origin, "NFTStaking: account to sender mismatch");
        require(
            tokenIds.length != 0,
            "NFTStaking: Token id's length can't be zero."
        );

        for (uint8 i = 0; i < tokenIds.length; i++) {
            require(
                botXNFT.ownerOf(uint256(tokenIds[i])) == _msgSender(),
                "NFTStaking: caller not owner"
            );
            _addBotPoll(account, tokenIds[i]);
            stakedNFTs[account].push(tokenIds[i]);
            stakedNFTsIndices[tokenIds[i]] = stakedNFTs[account].length - 1;
            botXNFT.transferFrom(account, address(this), tokenIds[i]);
        }
    }

    function getStakedByAddress(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return stakedNFTs[_owner];
    }

    function _removeStakedAddress(address stakedOwner, uint256 tokenId)
        internal
    {
        uint256 lastStakedNFTs = stakedNFTs[stakedOwner][
            stakedNFTs[stakedOwner].length - 1
        ];
        stakedNFTs[stakedOwner][stakedNFTsIndices[tokenId]] = lastStakedNFTs;
        stakedNFTsIndices[
            stakedNFTs[stakedOwner][stakedNFTs[stakedOwner].length - 1]
        ] = stakedNFTsIndices[tokenId];
        stakedNFTs[_msgSender()].pop();
        delete stakedNFTsIndices[tokenId];
    }

    function claimManyFromPoll(uint256[] calldata tokenIds, bool unstake)
        external
    {
        require(tx.origin == _msgSender(), "NFTStaking: Only EOA");
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claim(tokenIds[i], unstake);
        }
        botXToken.mint(_msgSender(), owed);
    }

    function _addBotPoll(address account, uint256 tokenId) internal {
        botXPolls[tokenId] = Stake({
            owner: account,
            tokenId: tokenId,
            lastClaimTime: block.timestamp
        });
        stakedBot++;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    function _calculateRewards(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        Stake memory stake = botXPolls[tokenId];
        uint256 owed = block.timestamp.mul(stake.lastClaimTime).div(1 days);
        return owed;
    }

    function _claim(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = botXPolls[tokenId];
        require(stake.owner == tx.origin, "NFTStaking: caller not owner");

        uint256 lastClaimTime = block.timestamp - stake.lastClaimTime;

        uint256 claimRate = 0;

        if (lastClaimTime <= 7 days) {
            claimRate = CLAIM_AMOUNT_1;
        } else if (lastClaimTime > 7 days && lastClaimTime <= 14 days) {
            claimRate = CLAIM_AMOUNT_2;
        } else if (lastClaimTime > 14 days && lastClaimTime <= 30 days) {
            claimRate = CLAIM_AMOUNT_3;
        } else if (lastClaimTime > 30 days) {
            claimRate = CLAIM_AMOUNT_4;
        }

        owed = ((block.timestamp.sub(stake.lastClaimTime)).mul(claimRate)).div(
            1 days
        );

        if (unstake) {
            delete botXPolls[tokenId];
            _removeStakedAddress(stake.owner, tokenId);
            botXNFT.transferFrom(address(this), stake.owner, tokenId);
        } else {
            botXPolls[tokenId] = Stake({
                owner: stake.owner,
                tokenId: stake.tokenId,
                lastClaimTime: block.timestamp
            });
        }
    }

    function setBotXNFTContract(IBotXNFT _botAddress) public onlyOwner {
        botXNFT = _botAddress;
    }

    function setBotXTokenContract(IBotXToken _tokenAddress) public onlyOwner {
        botXToken = _tokenAddress;
    }

    function setClaimAmounts(
        uint256 amount1,
        uint256 amount2,
        uint256 amount3,
        uint256 amount4
    ) public onlyOwner {
        CLAIM_AMOUNT_1 = amount1;
        CLAIM_AMOUNT_2 = amount2;
        CLAIM_AMOUNT_3 = amount3;
        CLAIM_AMOUNT_4 = amount4;
    }
}
