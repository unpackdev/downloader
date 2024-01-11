pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface ISucker is IERC20 {
    function mint(address receiver, uint256 amount) external;
}

contract Claim is Ownable {

    uint256 public REWARD_FOR_SEURM = 5038297872 * 10 ** 18;
    uint256 public REWARD_FOR_SUCKER = 2033647624 * 10 ** 18;

    mapping(uint256 => bool) public suckersClaimed;
    mapping(uint256 => bool) public serumsClaimed;

    ISucker suckerToken;
    IERC721 suckerNft;
    IERC721 serumNft;

    bool claimsClosed;

    constructor(ISucker _suckToken, IERC721 _suckerNft, IERC721 _serumNft) {
        suckerToken = _suckToken;
        suckerNft = _suckerNft;
        serumNft = _serumNft;
    }

    function claimForSuckers(uint256[] memory suckerIds) external {
        require(!claimsClosed, "CLAIMS_CLOSED");
        for(uint256 i; i < suckerIds.length;) {
            uint256 suckerId = suckerIds[i];
            require(!suckersClaimed[suckerId], "CLAIMED");
            require(suckerNft.ownerOf(suckerIds[i]) == msg.sender, "NOT_OWNER");
            suckersClaimed[suckerIds[i]] = true;
            unchecked { ++i; }
        }
        suckerToken.mint(msg.sender, REWARD_FOR_SUCKER * suckerIds.length);
    }

    function claimForSerums(uint256[] memory serumIds) external {
        require(!claimsClosed, "CLAIMS_CLOSED");
        for(uint256 i; i < serumIds.length;) {
            uint256 currentSerumId = serumIds[i];
            require(currentSerumId > 1034 && !serumsClaimed[currentSerumId], "CLAIMED");
            require(serumNft.ownerOf(serumIds[i]) == msg.sender, "NOT_OWNER");
            serumsClaimed[currentSerumId] = true;
            unchecked { ++i; }

        }
        suckerToken.mint(msg.sender, REWARD_FOR_SEURM * serumIds.length);
    }

    function closeClaiming(bool state) external onlyOwner {
        claimsClosed = state;
    }

    function setTokens(ISucker _suckerToken, IERC721 _suckerNft, IERC721 _serumNft) external onlyOwner {
        suckerToken = _suckerToken;
        suckerNft = _suckerNft;
        serumNft = _serumNft;
    }

    function editClaimAmounts(uint256 suckerAmount, uint256 serumAmount) external onlyOwner {
        REWARD_FOR_SUCKER = suckerAmount;
        REWARD_FOR_SEURM = serumAmount;
    }

}