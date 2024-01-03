pragma solidity ^0.6.0;
import "./IERC165.sol";

interface IVNFT is IERC165 {
    // function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 id);

    function totalSupply() external view returns (uint256);

    function fatality(uint256 _deadId, uint256 _tokenId) external;

    function buyAccesory(uint256 nftId, uint256 itemId) external;

    function claimMiningRewards(uint256 nftId) external;

    function addCareTaker(uint256 _tokenId, address _careTaker) external;

    function careTaker(uint256 _tokenId, address _user)
        external
        view
        returns (address _careTaker);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function itemPrice(uint256 itemId) external view returns (uint256 _amount);

    function getRewards(uint256 tokenId) external view returns (uint256);

    function isVnftAlive(uint256 _nftId) external view returns (bool);

    function level(uint256 tokenId) external view returns (uint256);

    function timeUntilStarving(uint256 _tokenId)
        external
        view
        returns (uint256 _time);

    function lastTimeMined(uint256 _tokenId)
        external
        view
        returns (uint256 _time);

    function getVnftInfo(uint256 _nftId)
        external
        view
        returns (
            uint256 _vNFT,
            bool _isAlive,
            uint256 _score,
            uint256 _level,
            uint256 _expectedReward,
            uint256 _timeUntilStarving,
            uint256 _lastTimeMined,
            uint256 _timeVnftBorn,
            address _owner,
            address _token,
            uint256 _tokenId,
            uint256 _fatalityReward
        );

    function vnftScore(uint256 _tokenId) external view returns (uint256 _score);

    function vnftScore(
        uint256 _tokenId,
        address //TODO What is this one?
    ) external view returns (uint256 _score);

    function timeVnftBorn(uint256 _tokenId)
        external
        view
        returns (uint256 _born);

    function mint(address to) external;
}
