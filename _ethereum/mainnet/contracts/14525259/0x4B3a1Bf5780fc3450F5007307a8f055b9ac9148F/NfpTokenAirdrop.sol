// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./TnfpTrader.sol";
import "./WhitelistVerifier.sol";

/// @title NFPS Airdrop Contract
/// @author NFP Swap
/// @notice NFPS Airdrop contract (Wave 1)
contract NfpsTokenAirdrop is Ownable, ReentrancyGuard, WhitelistVerifier {
    using SafeMath for uint256;
    using SafeMath for uint;

    uint256 private totalSupply;
    uint private _startTime;
    uint private _endTime;
    IERC20 private _nfpToken;
    TnfpTrader private _tNfpTrader;

    uint private _totalWhiteListOne = 0;
    uint private _totalWhiteListTwo = 0;
    uint private _totalWhiteListThree = 0;
    mapping(address => uint) private _ownerFirstClaimed;
    mapping(address => uint) private _ownerLastClaimed;
    mapping(address => uint) private _ownerClaimsMade;

    struct ClaimInfo {
        bool canClaim;
        uint256 tnfpCount;
        uint256 totalToClaim;
        uint256 availableAmount;
        uint totalClaims;
        uint firstClaimed;
        uint lastClaimed;
        uint startTime;
        uint endTime;
    }

    event Claim(address indexed from, uint256 amount);

    constructor(
        address adminAddress,
        uint totalWhiteListOne,
        uint totalWhiteListTwo,
        uint totalWhiteListThree
    ) {
        _setAdminAddress(adminAddress);
        _totalWhiteListOne = totalWhiteListOne;
        _totalWhiteListTwo = totalWhiteListTwo;
        _totalWhiteListThree = totalWhiteListThree;
    }

    /// @notice Sets admin address for whitelist signed messages
    function setAdminAddress(address _adminAddress) public onlyOwner {
        _setAdminAddress(_adminAddress);
    }

    /// @notice Fetch claim information for a given account and bucket
    function userClaimInfo(address account, uint bucket)
        public
        view
        returns (ClaimInfo memory)
    {
        bool canClaim = false;
        uint256 amountToClaim = 0;
        if (bucket == 1) {
            canClaim = true;
            amountToClaim = getAidropBucketOne();
        } else if (bucket == 2) {
            canClaim = true;
            amountToClaim = getAidropBucketTwo();
        } else if (bucket == 3) {
            canClaim = true;
            amountToClaim = getAidropBucketThree();
        }
        uint256 availableAmount = canClaim
            ? amountAvailableToClaim(
                amountToClaim,
                _ownerClaimsMade[account],
                _ownerFirstClaimed[account],
                _ownerLastClaimed[account]
            )
            : 0;
        uint256 tnfpCount = _tNfpTrader._listedItemsForOwnerCount(account);
        return
            ClaimInfo(
                canClaim,
                tnfpCount,
                amountToClaim,
                availableAmount,
                _ownerClaimsMade[account],
                _ownerFirstClaimed[account],
                _ownerLastClaimed[account],
                _startTime,
                _endTime
            );
    }

    /// @notice Claims from airdrop for authtorised address
    function claim(
        uint _bucket,
        uint _nonce,
        bytes memory signature
    )
        public
        nonReentrant
        verifyWhitelist(msg.sender, _bucket, _nonce, signature)
        airdropIsActive
    {
        ClaimInfo memory uci = userClaimInfo(msg.sender, _bucket);
        require(uci.canClaim == true, "User is not white listed");
        require(uci.tnfpCount > 0, "User must own a tNFP");
        require(
            uci.lastClaimed == 0 ||
                block.timestamp >= uci.lastClaimed + 30 days,
            "You can only claim once per month"
        );
        require(uci.availableAmount > 0, "No airdrop to claim");
        require(
            _nfpToken.balanceOf(address(this)) >= uci.availableAmount,
            "Airdrop contract does not have enough funds"
        );
        if (uci.firstClaimed == 0) {
            uint timeDiff = block.timestamp.sub(_startTime);
            uint monthsPassed = timeDiff.div(30 days).div(10);
            require(
                monthsPassed < 2,
                "Cannot claim two months after start of airdrop"
            );
            _ownerFirstClaimed[msg.sender] = block.timestamp;
        }
        _nfpToken.transfer(msg.sender, uci.availableAmount);
        _ownerLastClaimed[msg.sender] = block.timestamp;
        _ownerClaimsMade[msg.sender] = _ownerClaimsMade[msg.sender].add(1);
        emit Claim(msg.sender, uci.availableAmount);
    }

    /// @notice Gets the available amount to claim for a given authorised address
    function amountAvailableToClaim(
        uint256 initialAmount,
        uint claimsMade,
        uint firstClaimedTime,
        uint lastClaimedTime
    ) private view airdropIsActive returns (uint256) {
        if (claimsMade == 6) {
            return 0;
        }

        initialAmount = initialAmount.div(2);
        if (firstClaimedTime == 0) {
            return initialAmount;
        }

        if (lastClaimedTime > 0) {
            uint timeDiff = block.timestamp.sub(lastClaimedTime);
            uint monthsPassed = timeDiff.div(30 days).div(10);
            if (monthsPassed > 0) {
                return initialAmount.div(5).mul(monthsPassed);
            }
        }
        return 0;
    }

    /// @notice Gets claim amount for tier 1 bucket
    function getAidropBucketOne() private view returns (uint256) {
        return totalSupply.mul(65).div(100).div(_totalWhiteListOne);
    }

    /// @notice Gets claim amount for tier 2 bucket
    function getAidropBucketTwo() private view returns (uint256) {
        return totalSupply.mul(30).div(100).div(_totalWhiteListTwo);
    }

    /// @notice Gets claim amount for tier 3 bucket
    function getAidropBucketThree() private view returns (uint256) {
        return totalSupply.mul(5).div(100).div(_totalWhiteListThree);
    }

    /// @notice Initilises the airdrop with token address, trader address and endtime
    function startAirdrop(
        address nfpTokenAddress,
        address tNfpTraderAddress,
        uint256 endTime
    ) public onlyOwner {
        _endTime = block.timestamp + endTime;
        _nfpToken = IERC20(nfpTokenAddress);
        _tNfpTrader = TnfpTrader(tNfpTraderAddress);
        totalSupply = _nfpToken.balanceOf(address(this));
        require(totalSupply > 0, "Cannot start airdrop, no fund supplied");
        _startTime = block.timestamp;
    }

    /// @notice Allows withdrawl of unclaimed tokens after airdrop is over
    function widthdraw() public onlyOwner {
        require(
            _endTime < block.timestamp,
            "Cannot withdraw until airdrop has ended"
        );
        _nfpToken.transfer(msg.sender, _nfpToken.balanceOf(address(this)));
    }

    /// @notice Modifier to check airdrop is still active
    modifier airdropIsActive() {
        require(_startTime != 0, "Airdrop has not started");
        require(_endTime > block.timestamp, "Airdrop has ended");
        _;
    }
}
