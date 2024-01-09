// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @summary: Forked & Modified Vether (vetherasset.io) contract for Public Sale
 * @author: Boot Finance
 */

import "IERC721.sol";
import "SafeERC20.sol";
import "Ownable.sol";
import "Pausable.sol";

interface IVesting {
   /**
    * @dev Interface to vesting contract. 30% tokens are released instantly, 70% are locked.
    * @param _beneficiary Beneficiary of the locked tokens.
    * @param _amount Amount to be locked in vesting contract.
    */
   function vest(address _beneficiary, uint256 _amount) external payable;
}

interface IMintable {
    function mint(address _to, uint256 _value) external;
}

library SafeMath {
    /**
     * @dev SafeMath library
     * @param a First variable
     * @param b Second variable
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

contract BasicAuction is Ownable, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable mainToken;  //          BOOT token
    IERC721 public immutable nft;       // NFT contract required for early access

    // Public Parameters
    uint public constant decimals = 18;
    uint public constant coin = 10 ** decimals;
    uint public constant firstEra = 1;

    // project-specific multisig address where raised funds will be sent
    address payable destAddress;

    uint public secondsPerAuction;
    uint public auctionsPerEra;
    uint public firstPublicAuction;
    uint public totalSupply;        // MainToken supply allocated to public sale
    uint public remainingSupply;
    uint public initialEmission;
    uint public emissionDecayRate; // e.g. 1_000 constant, 0_618 golden ratio decay
    uint public currentEra;
    uint public currentAuction;
    uint public nextEraTime;
    uint public nextAuctionTime;
    uint public totalContributed;
    uint public totalEmitted;
    uint public ewma;
    uint private emission;

    // The emission for all auctions within a particular era.
    mapping(uint => uint) public mapEra_Emission;
    // The number of participants in a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_MemberCount;
    // The participants in a particular auction in a particular era.
    mapping(uint => mapping(uint => address[])) public mapEraAuction_Members;
    // The total units contributed in a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_Units;
    // The remaining unclaimed units from a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_UnitsRemaining;
    // The remaining unclaimed tokens from a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_EmissionRemaining;
    // Participant's remaining (unclaimed) units for a particular auction in a particular era
    mapping(uint => mapping(uint => mapping(address => uint))) public mapEraAuction_MemberUnitsRemaining;
    // Participant's particular auctions for a particular era.
    mapping(address => mapping(uint => uint[])) public mapMemberEra_Auctions;

    // Events
    event NewEra(uint era, uint emission, uint time, uint totalContributed);
    event NewAuction(uint era, uint auction, uint time, uint previousAuctionTotal, uint previousAuctionMembers, uint historicEWMA);
    event Contribution(address indexed payer, address indexed member, uint era, uint auction, uint units, uint dailyTotal);
    event Withdrawal(address indexed caller, address indexed member, uint era, uint auction, uint value, uint remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        IERC20 _mainToken,
        IERC721 _nft,
        uint _secondsPerAuction,
        uint _auctionsPerEra,
        uint _firstPublicAuction,
        uint _totalSupply,
        uint _initialEmission,
        uint _emissionDecayRate,
        address payable _destAddress)
    {
        require(address(_mainToken) != address(0), "Invalid _mainToken address");
        require(address(_nft) != address(0), "Invalid _nft address");
        require(address(_destAddress) != address(0), "Invalid _destAddress");

        mainToken = _mainToken;
        nft = _nft;

        currentEra = 1;
        currentAuction = 1;
        totalContributed = 0;
        totalEmitted = 0;

        secondsPerAuction = _secondsPerAuction;
        auctionsPerEra = _auctionsPerEra;
        firstPublicAuction = _firstPublicAuction;
        totalSupply = _totalSupply;
        initialEmission = _initialEmission;
        emissionDecayRate = _emissionDecayRate;

        emission = initialEmission; // current auction's theoretical emission regardless of actual supply
        remainingSupply = _totalSupply; // remaining actual supply including for the current auction

        destAddress = _destAddress;

        nextEraTime = block.timestamp + secondsPerAuction * auctionsPerEra;
        nextAuctionTime = block.timestamp + secondsPerAuction;
        mapEra_Emission[currentEra] = emission;
        mapEraAuction_EmissionRemaining[currentEra][currentAuction] = emission;
    }

    function setDestination(address payable _destAddress) public onlyOwner {
        require(address(_destAddress) != address(0), "Invalid _destAddress");
        destAddress = _destAddress;
    }

    receive() external payable whenNotPaused {
        // Any ETH sent is assumed to be for the token sale.
        _contributeForMember(msg.sender);
    }

    function contributeForMember(address member) external payable whenNotPaused {
        _contributeForMember(member);
    }

    function _contributeForMember(address member) private {
        require(msg.value > 0, "Some ether should be sent");
        _updateEmission();
        require(remainingSupply > 0, "public sale has ended");
        if (currentEra == 1 && currentAuction < firstPublicAuction) {
            // Initially only accounts with the specific NFT may participate.
            //
            require(nft.balanceOf(member) > 0, "NFT required to participate.");
        }
        _withdrawPrior(member);
        _recordContribution(msg.sender, member, currentEra, currentAuction, msg.value);
        (bool success, /*bytes memory data*/) = destAddress.call{value: msg.value}("");
        require(success, "");
    }

    function _recordContribution(address _payer, address _member, uint _era, uint _auction, uint _eth) private {
        if (mapEraAuction_MemberUnitsRemaining[_era][_auction][_member] == 0) {
            // If hasn't contributed to this Auction yet
            mapMemberEra_Auctions[_member][_era].push(_auction);
            mapEraAuction_MemberCount[_era][_auction] += 1;
            mapEraAuction_Members[_era][_auction].push(_member);
        }
        mapEraAuction_MemberUnitsRemaining[_era][_auction][_member] += _eth;
        mapEraAuction_Units[_era][_auction] += _eth;
        mapEraAuction_UnitsRemaining[_era][_auction] += _eth;
        totalContributed += _eth;
        emit Contribution(_payer, _member, _era, _auction, _eth, mapEraAuction_Units[_era][_auction]);
    }

    function getAuctionsContributedForEra(address member, uint era) public view returns(uint) {
        return mapMemberEra_Auctions[member][era].length;
    }

    function withdrawShare(uint era, uint auction) external returns (uint) {
        require(era >= 1, "era must be >= 1");
        require(auction >= 1, "auction must be >= 1");
        require(auction <= auctionsPerEra, "auction must be <= auctionsPerEra");
        _updateEmission();
        return _withdrawShare(era, auction, msg.sender);                           
    }

    function batchWithdraw(uint era, uint[] memory arrayAuctions) external returns (uint value) {
        _updateEmission();
        for (uint i = 0; i < arrayAuctions.length; ++i) {
            value += _prepareWithdrawShare(era, arrayAuctions[i], msg.sender);
        }
        _mint(value, msg.sender);
    }

    function _withdrawPrior(address member) private {
        for (uint era = currentEra; era >= 1; --era) {
            uint i = mapMemberEra_Auctions[member][era].length;
            while (i > 0) {
                --i;
                uint auction = mapMemberEra_Auctions[member][era][i];
                if (era != currentEra || auction != currentAuction) {
                    uint units = mapEraAuction_MemberUnitsRemaining[era][auction][member];
                    if (units > 0) {
                        uint value = _prepareWithdrawUnits(era, auction, member, units);
                        _mint(value, member);
                        //
                        // If a prior auction is found, then it is the only prior auction
                        // that has not already been withdrawn, so there's nothing left to do.
                        //
                        return;
                    }
                }
            }
        }
    }

    function withdrawAll(uint era) external returns (uint value) {
        _updateEmission();
        uint length = mapMemberEra_Auctions[msg.sender][era].length;
        for (uint i = 0; i < length; ++i) {
            uint auction = mapMemberEra_Auctions[msg.sender][era][i];
            value += _prepareWithdrawShare(era, auction, msg.sender);
        }
        _mint(value, msg.sender);
    }

    function withdrawAll() external returns (uint value) {
        _updateEmission();
        for (uint era = 1; era <= currentEra; ++era) {
            uint length = mapMemberEra_Auctions[msg.sender][era].length;
            for (uint i = 0; i < length; ++i) {
                uint auction = mapMemberEra_Auctions[msg.sender][era][i];
                value += _prepareWithdrawShare(era, auction, msg.sender);
            }
        }
        _mint(value, msg.sender);
    }

    function _mint(uint value, address _member) private {
        IMintable(address(mainToken)).mint(_member, value);
    }

    function _prepareWithdrawShare (uint _era, uint _auction, address _member) private returns (uint value) {
        if (_era < currentEra) {
            // Allow if in previous Era
            value = _prepareWithdrawal(_era, _auction, _member);
        }
        else if (_era == currentEra && _auction < currentAuction) {
            // Allow if in current Era and previous Auction
            value = _prepareWithdrawal(_era, _auction, _member);
        }
    }

    function _withdrawShare (uint _era, uint _auction, address _member) private returns (uint value) {
        // allowed from prior Era
        if (_era < currentEra) {
            value = _prepareWithdrawal(_era, _auction, _member);
            _mint(value, _member);
        }
        // allowed from prior Auction in current Era
        else if (_era == currentEra && _auction < currentAuction) {
            value = _prepareWithdrawal(_era, _auction, _member);
            _mint(value, _member);
        }  
    }

    function _prepareWithdrawal (uint _era, uint _auction, address _member) private returns (uint value) {
        uint memberUnits = mapEraAuction_MemberUnitsRemaining[_era][_auction][_member];
        if (memberUnits != 0) {
            value = _prepareWithdrawUnits(_era, _auction, _member, memberUnits);
        }
    }

    function _prepareWithdrawUnits(uint _era, uint _auction, address _member, uint memberUnits) private returns (uint value) {
        uint totalUnits = mapEraAuction_UnitsRemaining[_era][_auction];
        uint emissionRemaining = mapEraAuction_EmissionRemaining[_era][_auction];
        value = (emissionRemaining * memberUnits) / totalUnits;
        mapEraAuction_MemberUnitsRemaining[_era][_auction][_member] = 0; // since it will be withdrawn
        mapEraAuction_UnitsRemaining[_era][_auction] = mapEraAuction_UnitsRemaining[_era][_auction].sub(memberUnits);
        mapEraAuction_EmissionRemaining[_era][_auction] = mapEraAuction_EmissionRemaining[_era][_auction].sub(value);
        emit Withdrawal(msg.sender, _member, _era, _auction, value, mapEraAuction_EmissionRemaining[_era][_auction]);
    }

    // remaining emission share
    function getEmissionShare(uint era, uint auction, address member) public view returns (uint value) {
        uint memberUnits = mapEraAuction_MemberUnitsRemaining[era][auction][member];
        if (memberUnits != 0) {
            uint totalUnits = mapEraAuction_UnitsRemaining[era][auction];
            uint emissionRemaining = mapEraAuction_EmissionRemaining[era][auction];
            value = (emissionRemaining * memberUnits) / totalUnits;
        }
    }
    
    function _updateEmission() private {
        uint _now = block.timestamp;
        if (_now >= nextAuctionTime) {
            uint members = mapEraAuction_MemberCount[currentEra][currentAuction];
            uint units = mapEraAuction_Units[currentEra][currentAuction];
			if (units > 0) {
				uint price = 10**9 * (units / (emission / 10**9));
				ewma = ewma == 0 ? price : (3 * price + 2 * ewma) / 5; // apha = 0.6
			}
            if (remainingSupply > emission) {
                remainingSupply -= emission;
            }
            else {
                remainingSupply = 0;
            }
            if (currentAuction >= auctionsPerEra) {
                currentEra += 1;
                currentAuction = 0;
                nextEraTime = _now + secondsPerAuction * auctionsPerEra;
                emission = getNextEraEmission();
                mapEra_Emission[currentEra] = emission;
                emit NewEra(currentEra, emission, nextEraTime, totalContributed);
            }
            currentAuction += 1;
            nextAuctionTime = _now + secondsPerAuction;
            if (remainingSupply < emission) {
                // final auction
                emission = remainingSupply;
            }
            mapEraAuction_EmissionRemaining[currentEra][currentAuction] = emission;

            emit NewAuction(currentEra, currentAuction, nextAuctionTime, units, members, ewma);
        }
    }

    function getImpliedPriceEWMA(bool includeCurrentEra) public view returns (uint) {
        if (ewma == 0 || includeCurrentEra) {
            uint price = 10**9 * (mapEraAuction_Units[currentEra][currentAuction] / (emission / 10**9));
			return ewma == 0 ? price : (3 * price + 2 * ewma) / 5; // apha = 0.6
        }
        else {
            return ewma;
        }
    }

    function updateEmission() external {
        _updateEmission();
    }

    function getNextEraEmission() public view returns (uint) {
        if (emissionDecayRate == 1000) {
            return emission;
        }
        else {
            // decays only on first auction of this next era
            return emission * emissionDecayRate / 1000;
        }
    }

    function getAuctionEmission() public view returns (uint) {
        return emission;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}

contract Auction is BasicAuction {
    constructor(IERC20 _mainToken, IERC721 _nft)
        BasicAuction(
            _mainToken,
            _nft,

            7 * 86400, // secondsPerAuction

            52, // auctionsPerEra
            5,  // firstPublicAuction

            12_499_968_000000000000000000, // totalSupply for entire sale period
                80_128_000000000000000000, // initial auction emission = totalSupply / 3 / 52

            1_000, // decay rate per era

            payable(address(0x03Df4ADDfB568b338f6a0266f30458045bbEFbF2)))
    {}
}
