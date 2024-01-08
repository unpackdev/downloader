// SPDX-License-Identifier: MIT

// ____   ____               .___              _________ .__  __          
// \   \ /   /___   ____   __| _/____   ____   \_   ___ \|__|/  |_ ___.__.
//  \   Y   /  _ \ /  _ \ / __ |/  _ \ /  _ \  /    \  \/|  \   __<   |  |
//   \     (  <_> |  <_> ) /_/ (  <_> |  <_> ) \     \___|  ||  |  \___  |
//    \___/ \____/ \____/\____ |\____/ \____/   \______  /__||__|  / ____|
//                            \/                       \/          \/     

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

contract VoodooCoin is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 public MAX_WALLET_STAKED = 30;
    uint256 public EMISSIONS_RATE = 115740740800000; //  EMISSIONS_RATE * 60 * 60 * 24
    uint256 public CLAIM_END_TIME = 1795996800;
    uint256 public SCROLL_BONUS_RATE = 11000; // 110%

    address public vdcAddress;
    address public scrollAdress;

    //Mapping of vdc to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    //Mapping of vdc to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    //Mapping of staker to vdc
    mapping(address => uint256[]) internal stakerToTokenIds;

    constructor() ERC20("Voodoo Coin", "VC") {}

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function setVdcAddress(address _vdcAddress) public onlyOwner {
        vdcAddress = _vdcAddress;
    }

    function setScrollAddress(address _scrollAddress) public onlyOwner {
      scrollAdress = _scrollAddress;
    }

    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function getScrollState(address staker) public view returns (bool) {
      if (scrollAdress == address(0)) return false;

      return IERC721(scrollAdress).balanceOf(staker) > 0 ? true : false;
    } 

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(
            stakerToTokenIds[msg.sender].length + tokenIds.length <=
                MAX_WALLET_STAKED,
            "Must have less than 30 VDC staked!"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(vdcAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == address(0),
                "Token must be stakable by you!"
            );

            IERC721(vdcAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one token staked!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(vdcAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    EMISSIONS_RATE);

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = address(0);
        }
        if (block.timestamp < CLAIM_END_TIME) {
            _mint(msg.sender, getScrollState(msg.sender) ? totalRewards * SCROLL_BONUS_RATE / 10000 : totalRewards);
        }

    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(vdcAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = address(0);
        }
        if (block.timestamp < CLAIM_END_TIME) {
            _mint(msg.sender, getScrollState(msg.sender) ? totalRewards * SCROLL_BONUS_RATE / 10000 : totalRewards);
        }
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");

        uint256 baseAmount = ((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE);

        _mint(
            msg.sender,
            getScrollState(msg.sender) ? baseAmount * SCROLL_BONUS_RATE / 10000 : baseAmount
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public {
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, getScrollState(msg.sender) ? totalRewards * SCROLL_BONUS_RATE / 10000 : totalRewards);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);
        }

        return getScrollState(staker) ? totalRewards * SCROLL_BONUS_RATE / 10000 : totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != address(0),
            "Token is not staked!"
        );

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];
        uint256 baseAmount = secondsStaked * EMISSIONS_RATE;

        address owner = IERC721(vdcAddress).ownerOf(tokenId);

        return getScrollState(owner) ? baseAmount * SCROLL_BONUS_RATE / 10000 : baseAmount;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }
}