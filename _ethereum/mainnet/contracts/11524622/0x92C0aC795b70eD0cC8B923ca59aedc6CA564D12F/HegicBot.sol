// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Address.sol";
import "./ERC721Holder.sol";
import "./Counters.sol";

import "./IHegicNFT.sol";
import "./IHegicBot.sol";
import "./IPriceProvider.sol";
import "./Governable.sol";
import "./CollectableDust.sol";

contract HegicBot is IHegicBot, Governable, CollectableDust, ERC721Holder {
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public FEE_MAX = 10000;
    uint256 public workFee = 100;

    IHegicNFT public ethNft;
    IPriceProvider public priceProvider;
    address public keeper;

    Counters.Counter private _trackedTokenIds;
    mapping(uint256 => TrackedToken) public trackedTokens;

    constructor(IHegicNFT _ethNft, IPriceProvider _priceProvider) public Governable(msg.sender) CollectableDust() {
        ethNft = _ethNft;
        priceProvider = _priceProvider;
    }

    function track(uint256 tokenId, uint256 priceTarget) external override returns (uint256 trackedTokenId) {
        require(ethNft.isValidToken(tokenId), "tokenId invalid");

        ethNft.safeTransferFrom(msg.sender, address(this), tokenId);

        _trackedTokenIds.increment();
        trackedTokenId = _trackedTokenIds.current();
        TrackedToken memory trackedToken = TrackedToken(msg.sender, tokenId, priceTarget);
        trackedTokens[trackedTokenId] = trackedToken;

        emit TokenTracked(trackedTokenId);
    }

    function untrack(uint256 trackedTokenId) external override returns (bool) {
        TrackedToken memory trackedToken = trackedTokens[trackedTokenId];
        require(trackedToken.owner == msg.sender, "!owner");

        ethNft.safeTransferFrom(address(this), msg.sender, trackedToken.tokenId);
        delete trackedTokens[trackedTokenId];
        emit TokenUntracked(trackedTokenId);

        return true;
    }

    function exercisable(uint256 trackedTokenId) external view override returns (bool) {
        TrackedToken memory trackedToken = trackedTokens[trackedTokenId];
        Option memory option = ethNft.getUnderlyingOptionParams(trackedToken.tokenId);

        if (option.expiration < block.timestamp || option.state != State.Active) {
            return false;
        }

        if (trackedToken.owner == msg.sender) {
            return true;
        }

        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);

        if (option.optionType == OptionType.Call) {
            return currentPrice >= trackedToken.priceTarget;
        } else if (option.optionType == OptionType.Put) {
            return currentPrice <= trackedToken.priceTarget;
        }

        return false;
    }

    function exercise(uint256 trackedTokenId) external override returns (address, uint256) {
        require(this.exercisable(trackedTokenId), "trackedTokenId not exercisable");

        TrackedToken memory trackedToken = trackedTokens[trackedTokenId];

        ethNft.exerciseOption(trackedToken.tokenId);

        uint256 grossProfit = address(this).balance;
        uint256 ownerFee = grossProfit.mul(workFee).div(FEE_MAX);
        require(ownerFee > 0, "profit==0");

        payable(governor).transfer(ownerFee);

        uint256 netProfit = address(this).balance;
        if (msg.sender == keeper) {
            payable(keeper).transfer(netProfit);
        } else {
            payable(trackedToken.owner).transfer(netProfit);
        }

        delete trackedTokens[trackedTokenId];

        emit TrackedTokenExercised(trackedToken.tokenId, grossProfit);

        return (trackedToken.owner, netProfit);
    }

    function setWorkFee(uint256 _workFee) external override onlyGovernor {
        require(_workFee > 0 && _workFee <= 10000);
        workFee = _workFee;
        emit WorkFeeSet(_workFee);
    }

    function setKeeper(address _keeper) external override onlyGovernor {
        keeper = _keeper;
        emit KeeperSet(_keeper);
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }

    receive() external payable {}
}
