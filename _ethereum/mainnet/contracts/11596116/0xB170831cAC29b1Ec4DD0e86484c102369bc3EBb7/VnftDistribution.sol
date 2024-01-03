pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./IVNFT.sol";
import "./IVNFTX.sol";

// instead of minting  Gov tokens with this contract
// we can send tokens to this contract and then send tokens to qualified users.
contract VnftDistribution {
    using SafeMath for uint256;

    uint256 public timeRequirement = 1609137000; //time born
    mapping(uint256 => bool) public gotTokens;

    IERC20 public token;
    IVNFT public vnft;
    IVNFTx public vnftx;

    address public owner;

    event Claimed(address indexed user, uint256 indexed pet, uint256 hp);

    constructor(
        IERC20 _token,
        IVNFT _vnft,
        IVNFTx _vnftx
    ) public {
        token = _token;
        vnft = _vnft;
        vnftx = _vnftx;
        owner = msg.sender;
    }

    function changeTimeReq(uint256 _time) external {
        require(msg.sender == owner, "!owner");
        timeRequirement = _time;
    }

    function getTokens(uint256 _nftId) external {
        require(!gotTokens[_nftId], "trying to cheat");
        require(
            vnft.timeVnftBorn(_nftId).add(30 days) <= timeRequirement,
            "!qualify"
        );
        require(vnft.ownerOf(_nftId) == msg.sender, "!owner");

        gotTokens[_nftId] = true;

        uint256 hp = vnftx.getHp(_nftId);

        if (hp >= 90) {
            token.transfer(msg.sender, 1000 ether);
        } else if (hp >= 70 && hp <= 89) {
            token.transfer(msg.sender, 100 ether);
        }

        emit Claimed(msg.sender, _nftId, hp);
    }
}
