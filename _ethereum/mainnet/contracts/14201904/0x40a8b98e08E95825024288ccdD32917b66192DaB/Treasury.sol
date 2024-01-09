// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * What is WGLX?
 Like WSTR, but for galaxies. And without any involvement from Tlon.
 * How do I vote a galaxy?
 Buy up enough WGLX to withdraw the top galaxy, vote it, and hold it till the
 poll expires. Then you may redeposit it and get your WGLX back.
 * How do I know the top galaxy will be allowed to vote in a poll?
 The treasury forbids depositing a galaxy which has voted on any active poll.
 * What if several people want to pool their fractions of WGLX to vote together?
 They can use a straightforward contract to do this.
 * What if there is only 1 galaxy in the treasury?
 Actually withdrawing the bottom galaxy in the stack may be impossible due to
 outstanding WGLX being lost, burned, or just incommunicado. Thus, if there is
 exactly 1 galaxy deposited and you have more than half the outstanding WGLX, you
 can vote/manage it through the contract without withdrawing it.
 * Why would anyone be the first to deposit a galaxy?
 As a motivator to get liquidity off the ground, there is a bonus for the first
 few galaxy depositors. The 1st galaxy deposited earns 1,200,000 WGLX (and costs the
 same to withdraw). The 2nd galaxy is 1,100,000 WGLX and the third is 1,050,000.
 After that, subsquent galaxies are worth 1,000,000 WGLX each.
 * How many galaxies can be deposited?
 At most 128. If a majority of galaxies were deposited, the treasury would be
 able to upgrade itself, which seems too dangerous.
 * When can the contracts self-destruct?
 Only when there are zero deposited galaxies and zero outstanding WGLX. The
 contracts were directly deployed from an external account, so there is no
 CREATE2 risk of hijacking the address with a different coin.
 * What about censures and claims?
 It is possible that the top galaxy you withdraw will have censures or claims
 attached to it. Fortunately, nobody uses these for anything and they don't matter
 at all.
 * What about spawning?
 You should only expect "bare" galaxies (which have already spawned all their
 stars) to be deposited.
*/


import "./Context.sol";
import "./Ownable.sol";
import "./IAzimuth.sol";
import "./IEcliptic.sol";
import "./IPolls.sol";
import "./GalaxyToken.sol";

//  Treasury: Galaxy wrapper
//
//    This contract implements an extremely simple wrapper for galaxies.
//    It allows owners of Azimuth galaxy points to deposit them and mint new WGLX (wrapped galaxy) tokens,
//    and in turn to redeem WGLX tokens for Azimuth galaxies.

contract Treasury is Context, Ownable {
    // MODEL

    //  assets: galaxies currently held in this pool
    //  note: galaxies are 8 bit numbers and we always handle them as uint8.
    //  some azimuth and ecliptic calls (below) expect uint32 points. in these cases, solidity upcasts the uint8 to
    //  uint32, which is a safe operation.
    //
    uint8[] public assets;

    //  azimuth: points state data store
    //
    IAzimuth public immutable azimuth;

    // deploy a new token contract with no balance
    GalaxyToken public immutable galaxytoken;

    // bonuses for the first few depositors
    uint256 constant public FIRST_GALAXY = 1.2e24;
    uint256 constant public SECOND_GALAXY = 1.1e24;
    uint256 constant public THIRD_GALAXY = 1.05e24;
    uint256 constant public SUBSEQUENT_GALAXY = 1e24;
    uint256 constant public VOTE_FIRST_GALAXY = FIRST_GALAXY/ 2 + 1;

    // EVENTS

    event Deposit(
        uint8 indexed galaxy,
        address sender
    );

    event Redeem(
        uint8 indexed galaxy,
        address sender
    );

    // IMPLEMENTATION

    //  constructor(): configure the points data store and token contract
    // address
    constructor(IAzimuth _azimuth, GalaxyToken _galaxytoken) Ownable()
    {
        azimuth = _azimuth;
        galaxytoken = _galaxytoken;
    }

    //  getAllAssets(): return array of assets held by this contract
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getAllAssets()
        view
        external
        returns (uint8[] memory allAssets)
    {
        return assets;
    }

    //  getAssetCount(): returns the number of assets held by this contract
    //
    function getAssetCount()
        view
        external
        returns (uint256 count)
    {
        return assets.length;
    }

    function getTopGalaxyValue()
        view
        internal
        returns (uint256 value)
    {
        if (assets.length == 1) {
            return FIRST_GALAXY;
        } else if (assets.length == 2) {
            return SECOND_GALAXY;
        } else if (assets.length == 3) {
            return THIRD_GALAXY;
        } else {
            return SUBSEQUENT_GALAXY;
        }
    }

    function requireHasNotVotedOnAnyActivePoll(
        uint8 _galaxy, IPolls polls)
        view
        internal
    {
        uint256 i = polls.getDocumentProposalCount();
        while(i > 0) {
            i--;
            bytes32 proposal = polls.documentProposals(i);
            (uint256 start,
             uint16 yesVotes,
             uint16 noVotes,
             uint256 duration,
             uint256 cooldown) = polls.documentPolls(proposal);
            if (block.timestamp < start + duration) {
                require(!polls.hasVotedOnDocumentPoll(_galaxy, proposal),
                        "Treasury: Galaxy has voted on active document");
            }
        }
        i = polls.getUpgradeProposalCount();
        while(i > 0) {
            i--;
            address proposal = polls.upgradeProposals(i);
            (uint256 start,
             uint16 yesVotes,
             uint16 noVotes,
             uint256 duration,
             uint256 cooldown) = polls.upgradePolls(proposal);
            if (block.timestamp < start + duration) {
                require(!polls.hasVotedOnUpgradePoll(_galaxy, proposal),
                        "Treasury: Galaxy has voted on active upgrade");
            }
        }
    }

    //  deposit(galaxy): deposit a galaxy you own, receive a newly-minted wrapped galaxy token in exchange
    //
    function deposit(uint8 _galaxy) external
    {
        require(assets.length < 128, "Treasury: full");
        require(azimuth.getPointSize(_galaxy) == IAzimuth.Size.Galaxy, "Treasury: must be a galaxy");
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        requireHasNotVotedOnAnyActivePoll(_galaxy, ecliptic.polls());

        require(azimuth.getSpawnProxy(_galaxy) != 0x1111111111111111111111111111111111111111,
                "Treasury: No L2");
        require(azimuth.canTransfer(_galaxy, _msgSender()),
                "Treasury: can't transfer"); 
        // transfer ownership of the _galaxy to :this contract
        // note: _galaxy is uint8, ecliptic expects a uint32 point
        ecliptic.transferPoint(_galaxy, address(this), true);

        //  update state to include the deposited galaxy
        //
        assets.push(_galaxy);

        //  mint a galaxy token and grant it to the :msg.sender
        galaxytoken.mint(_msgSender(), getTopGalaxyValue());
        emit Deposit(_galaxy, _msgSender());
    }

    //  redeem(): burn one galaxy token, receive ownership of the most recently deposited galaxy in exchange
    //
    function redeem() external returns (uint8) {
        // there must be at least one galaxy in the asset list
        require(assets.length > 0, "Treasury: no galaxy available to redeem");

        // must have sufficient balance
        uint256 _topGalaxyValue = getTopGalaxyValue();
        require(galaxytoken.balanceOf(_msgSender()) >= _topGalaxyValue, "Treasury: Not enough balance");

        // remove the galaxy to be redeemed
        uint8 _galaxy = assets[assets.length-1];

        assets.pop();

        // burn the tokens
        galaxytoken.ownerBurn(_msgSender(), _topGalaxyValue);

        // transfer ownership
        // note: Treasury should be the owner of the point and able to transfer it. this check happens inside
        // transferPoint().

        // note: _galaxy is uint8, ecliptic expects a uint32 point
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        ecliptic.transferPoint(_galaxy, _msgSender(), true);

        emit Redeem(_galaxy, _msgSender());
        return _galaxy;
    }

    // When the treasury contains exactly 1 galaxy, anyone with more than half
    // its cost can vote/manage it.
    function setProxy(address _addr) external {
        require(assets.length == 1, "Treasury: needs 1 galaxy");
        require(galaxytoken.balanceOf(_msgSender()) >= VOTE_FIRST_GALAXY,
                "Treasury: Not enough balance");
        galaxytoken.ownerBurn(_msgSender(), VOTE_FIRST_GALAXY);
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        ecliptic.setVotingProxy(assets[0], _addr);
        ecliptic.setManagementProxy(assets[0], _addr);
    }

    function unsetProxy() external {
        require(assets.length >= 1, "Treasury: needs a galaxy");
        uint8 _gal = assets[0];
        require(azimuth.canVoteAs(_gal, _msgSender()),
                "Treasury: not voter");
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        requireHasNotVotedOnAnyActivePoll(_gal, ecliptic.polls());
        ecliptic.setVotingProxy(_gal, address(0));
        ecliptic.setManagementProxy(_gal, address(0));
        galaxytoken.mint(_msgSender(), VOTE_FIRST_GALAXY);
    }
    function destroyAndSend(address payable _recipient) external onlyOwner {
        require(galaxytoken.totalSupply()==0, "Treasury: not empty");
        selfdestruct(_recipient);
    }
}
