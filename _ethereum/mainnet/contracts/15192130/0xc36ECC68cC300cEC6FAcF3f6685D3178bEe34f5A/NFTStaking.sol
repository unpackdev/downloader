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
        uint256 periodTime;
        uint256 dailyAmount;
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
        uint256 lastClaimTime,
        uint256 periodTime,
        uint256 dailyAmount
    );

    constructor(IBotXNFT _botXNFT, IBotXToken _botXToken) {
        botXNFT = _botXNFT;
        botXToken = _botXToken;
        _pause();
    }

    function getPollInfo(uint8 id) public view returns (Stake memory) {
        return botXPolls[id];
    }

    function addManyToPoll(
        address account,
        uint256[] calldata tokenIds,
        uint256 _periodType
    ) public {
        require(tx.origin == _msgSender(), "NFTStaking: Only EOA");
        require(account == tx.origin, "NFTStaking: account to sender mismatch");
        require(
            tokenIds.length != 0,
            "NFTStaking: Token id's length can't be zero."
        );
        require(
            _periodType >= 0 && _periodType <= 3,
            "NFTStaking: Staking Period Type Failed."
        );

        for (uint8 i = 0; i < tokenIds.length; i++) {
            require(
                botXNFT.ownerOf(uint256(tokenIds[i])) == _msgSender(),
                "NFTStaking: caller not owner"
            );
            _addBotPoll(account, tokenIds[i], _periodType);
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

    function claimManyFromPoll(uint256[] calldata tokenIds) external {
        require(tx.origin == _msgSender(), "NFTStaking: Only EOA");
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claim(tokenIds[i]);
        }
        botXToken.mint(_msgSender(), owed);
    }

    function _addBotPoll(
        address account,
        uint256 tokenId,
        uint256 _periodType
    ) internal {
        uint256 stakingPeriod = 0;
        uint256 dailyAmount = 0;
        if (_periodType == 0) {
            stakingPeriod = 7 days;
            dailyAmount = CLAIM_AMOUNT_1;
        } else if (_periodType == 1) {
            stakingPeriod = 14 days;
            dailyAmount = CLAIM_AMOUNT_2;
        } else if (_periodType == 2) {
            stakingPeriod = 30 days;
            dailyAmount = CLAIM_AMOUNT_3;
        } else if (_periodType == 3) {
            stakingPeriod = 60 days;
            dailyAmount = CLAIM_AMOUNT_4;
        }

        botXPolls[tokenId] = Stake({
            owner: account,
            tokenId: tokenId,
            lastClaimTime: block.timestamp,
            periodTime: stakingPeriod,
            dailyAmount: dailyAmount
        });
        stakedBot++;
        emit TokenStaked(
            account,
            tokenId,
            block.timestamp,
            stakingPeriod,
            dailyAmount
        );
    }

    function _claim(uint256 tokenId) internal returns (uint256 owed) {
        Stake memory stake = botXPolls[tokenId];
        require(stake.owner == tx.origin, "NFTStaking: caller not owner");

        uint256 lastClaimTime = block.timestamp - stake.lastClaimTime;

        require(
            lastClaimTime >= stake.periodTime,
            "NFTStaking: You can unstake NFT after lock time."
        );

        owed = (stake.periodTime.div(1 days)).mul(stake.dailyAmount);

        delete botXPolls[tokenId];
        _removeStakedAddress(stake.owner, tokenId);
        botXNFT.transferFrom(address(this), stake.owner, tokenId);
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
