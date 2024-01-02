// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Leaderboard.sol";
import "./IDougToken.sol";
import "./Ownable.sol";

contract DougBank is Ownable, Leaderboard, IDougBank {
    uint256 public devRoyalties;
    uint256 public commonRoyalties;
    uint256 public undistributedRoyalties;
    IDougToken private _token;
    mapping(uint256 => uint256) public _withdrawals;
    uint16[7] private _rankShareRatio = [2, 5, 12, 28, 64, 144, 320];

    constructor(address tokenAddress, address owner) payable Ownable(owner) {
        _token = IDougToken(tokenAddress);
        for (uint8 i = 0; i < DOUG_TYPES; i++) {
            _typeRoyalties[i] = 1;
        }
    }

    receive() external payable {
        uint256 _devShare = (msg.value * 20) / 100;
        uint256 _communityShare = msg.value - _devShare;

        devRoyalties += _devShare;
        uint256 _highScoreShare = _communityShare >> (1);
        uint256 distributionPerPoint = _highScoreShare / LEADERBOARD_PTS_TOTAL;

        uint256 _disbursed;

        // Plough through the top20 of the ordered leaderboard allocating the bonus royalty share

        for (uint256 i = 0; i < 20; i++) {
            uint8 points = _leaderboardAmounts[i];
            uint128 _typeShare = uint128(distributionPerPoint * points);

            _typeRoyalties[i] += _typeShare;
            _disbursed += _typeShare;
        }

        commonRoyalties += _communityShare - _disbursed;
    }

    function onTokenMerged(
        uint8 _type,
        uint8 _rank,
        uint256 tokenA,
        uint256 tokenB,
        uint256 merged
    ) external override {
        require(msg.sender == address(_token), "DougBank: invalid sender");
        updateLeaderboard(_rank, _type);

        _withdrawals[merged] = _withdrawals[tokenA] + _withdrawals[tokenB];
    }

    function tokenBalance(uint256 tokenId) public view returns (uint256) {
        uint8 _dougType = _token.dougType(tokenId);
        uint8 _dougRank = _token.dougRank(tokenId);

        uint8 _position = leaderboardPosition(_dougType);
        uint256 _typeShare = _typeRoyalties[_position];
        uint256 _totalTypeRoyalties = _typeShare + commonRoyalties / 100;
        uint256 _tokenRoyalties = (_totalTypeRoyalties * _rankShareRatio[_dougRank]) / 575;
        return _tokenRoyalties - _withdrawals[tokenId];
    }

    function tokenBalanceMany(uint256[] memory tokenIds) public view returns (uint256) {
        address _tokenOwnerFirst = _token.ownerOf(tokenIds[0]);
        require(_tokenOwnerFirst == msg.sender, "DougBank: not owner of token");
        uint256 _available = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address _tokenOwner = _token.ownerOf(tokenId);
            require(_tokenOwner == _tokenOwnerFirst, "DougBank: not owner of token");
            uint256 _tokenAvailable = tokenBalance(tokenId);
            _available += _tokenAvailable;
        }

        return _available;
    }

    function transferTokenBalance(uint256 tokenId) public {
        address _tokenOwner = _token.ownerOf(tokenId);
        require(_tokenOwner == msg.sender, "DougBank: not owner of token");
        address payable _to = payable(_tokenOwner);
        uint256 _available = tokenBalance(tokenId);
        _withdrawals[tokenId] += _available;

        _to.transfer(_available);
    }

    function transferTokenBalanceMany(uint256[] memory tokenIds) public {
        address _tokenOwnerFirst = _token.ownerOf(tokenIds[0]);
        require(_tokenOwnerFirst == msg.sender, "DougBank: not owner of token");
        address payable _to = payable(_tokenOwnerFirst);
        uint256 _available = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address _tokenOwner = _token.ownerOf(tokenId);
            require(_tokenOwner == _tokenOwnerFirst, "DougBank: not owner of token");
            uint256 _tokenAvailable = tokenBalance(tokenId);
            _withdrawals[tokenId] += _tokenAvailable;
            _available += _tokenAvailable;
        }

        _to.transfer(_available);
    }

    function withdrawDeveloperRoyalties(address toAddress) public isOwner {
        uint256 _amount = devRoyalties;
        devRoyalties = 0;
        address payable _to = payable(toAddress);
        _to.transfer(_amount);
    }

    function withdrawAll() public isOwner {
        address payable _to = payable(_owner);
        uint256 _amount = address(this).balance;
        _to.transfer(_amount);
    }
}
