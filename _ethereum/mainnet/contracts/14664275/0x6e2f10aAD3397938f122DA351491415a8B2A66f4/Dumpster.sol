// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dao: DumpsterDAO

/*
    ::........::::.......:::..:::::..::..::::::::::......::::::..:::::........::..:::::...:::
    :: ########   ##     ##  ##     ##  #########   ######   ########  ########  ########  ::
    :: ##     ##  ##     ##  ###   ###  ##     ##  ##    ##     ##     ##        ##     ## ::
    :: ##     ##  ##     ##  #### ####  ##     ##  ##           ##     ##        ##     ## ::
    :: ##     ##  ##     ##  ## ### ##  ########    ######      ##     ######    ########  ::
    :: ##     ##  ##     ##  ##  #  ##  ##               ##     ##     ##        ##   ##   ::
    :: ##     ##  ##     ##  ##     ##  ##         ##    ##     ##     ##        ##    ##  ::
    :: ########    #######   ##     ##  ##          ######      ##     ########: ##     ## ::
    :::::...::::.......:::..:::::..::..::::::::::......::::::..:::::........::..:::::....::::
*/

import "./StakingWrapper.sol";
import "./IERC1155.sol";

import "./IERC20.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract Dumpster is StakingWrapper, Pausable, AccessControl {
    using SafeMath for uint256;

    uint256 private constant DECIMALS = 1e17;
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    IERC1155 public nftToken;

    struct NFT {
        uint256 points;
        uint256 releaseTime;
    }

    bool public allowBoosts = true;
    uint256 public start;
    uint256 public maxStake = 8200 * DECIMALS;
    uint256 public dumpsterDive = 82000 * DECIMALS;
    uint256 public rewardRate = 14114724480;
    uint256[4] public boosts = [
        100, // 10%
        250, // 25%
        300, // 33%
        500 // 50%
    ];

    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public points;
    mapping(uint256 => NFT) public nfts;

    event Redeemed(address indexed user, uint256 points);
    event Added(
        uint256 tokenId,
        uint256 maxIssuance,
        uint256 points,
        uint256 releaseTime,
        string tokenUri
    );

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = _blockTime();
        }
        _;
    }

    modifier onlyCreator() {
        require(
            hasRole(CREATOR_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "caller is not a creator"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "caller is not owner"
        );
        _;
    }

    constructor(address _tokenAddress, address _nftAddress)
        StakingWrapper(_tokenAddress)
    {
        nftToken = IERC1155(_nftAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function percentStaked() public view returns (uint256 percent) {
        return (totalStaked().mul(1000)).div(totalSupply());
    }

    function boostAmount() public view returns (uint256 boost) {
        if (!allowBoosts) return 0;
        if (percentStaked() >= boosts[3]) return 500;
        if (percentStaked() >= boosts[2]) return 330;
        if (percentStaked() >= boosts[1]) return 250;
        if (percentStaked() >= boosts[0]) return 100;
        return 0;
    }

    function earned(address account) public view returns (uint256) {
        uint256 blockTime = _blockTime();
        uint256 base = balanceOf(account)
            .mul(blockTime.sub(lastUpdateTime[account]).mul(rewardRate))
            .div(DECIMALS)
            .add(points[account]);

        return base.add(base.mul(boostAmount()).div(1000));
    }

    function nftReleaseTime(uint256 tokenId) public view returns (uint256) {
        return nfts[tokenId].releaseTime;
    }

    function nftPoints(uint256 tokenId) public view returns (uint256) {
        return nfts[tokenId].points;
    }

    function nftTotalIssuance(uint256 tokenId) public view returns (uint256) {
        return nftToken.totalSupply(tokenId);
    }

    function nftMaxIssuance(uint256 tokenId) public view returns (uint256) {
        return nftToken.maxIssuance(tokenId);
    }

    function mintingOpen() public view returns (bool) {
        return totalStaked() >= dumpsterDive;
    }

    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        whenNotPaused
    {
        require(_blockTime() >= start, "dumpster not ready");
        require(
            amount.add(balanceOf(msg.sender)) <= maxStake,
            "deposit > max allowed"
        );

        super.stake(amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "why withdraw 0?");
        super.withdraw(amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function redeem(uint256 id, uint256 quantity)
        public
        updateReward(msg.sender)
    {
        require(totalStaked() >= dumpsterDive, "diving not started");
        require(quantity > 0, "mint 1 or more");
        require(nfts[id].points != 0, "nft not found");
        require(_blockTime() >= nfts[id].releaseTime, "nft not released");

        NFT memory n = nfts[id];

        uint256 requiredPoints = quantity.mul(n.points);
        require(points[msg.sender] >= requiredPoints, "need more points");

        points[msg.sender] = points[msg.sender].sub(requiredPoints);
        nftToken.mint(msg.sender, id, quantity);

        emit Redeemed(msg.sender, requiredPoints);
    }

    function _blockTime() internal view returns (uint256) {
        return block.timestamp;
    }

    // ADMIN FUNCTIONS //

    function setAllowBoosts(bool _allowBoosts) public onlyOwner {
        allowBoosts = _allowBoosts;
    }

    function setDumpsterDive(uint256 _dumpsterDive) public onlyOwner {
        dumpsterDive = _dumpsterDive;
    }

    function setMaxStake(uint256 _maxStake) public onlyOwner {
        maxStake = _maxStake;
    }

    function setRewardRate(uint256 _toStakePerPoint) public onlyOwner {
        uint256 _rewardRate = (
            uint256(1e18).div(86400).mul(DECIMALS).div(_toStakePerPoint)
        );

        rewardRate = _rewardRate;
    }

    function setStart(uint256 _start) public onlyOwner {
        start = _start;
    }

    function addNFT(
        uint256 _maxIssuance,
        string memory _tokenURI,
        uint256 _points,
        uint256 _releaseTime
    ) public onlyCreator returns (uint256 tokenId) {
        tokenId = nftToken.initializeToken(
            _msgSender(),
            _maxIssuance,
            _tokenURI
        );
        require(tokenId > 0, "ERC1155 create did not succeed");

        NFT storage n = nfts[tokenId];
        n.points = _points;
        n.releaseTime = _releaseTime;

        emit Added(tokenId, _maxIssuance, _points, _releaseTime, _tokenURI);
    }
}
