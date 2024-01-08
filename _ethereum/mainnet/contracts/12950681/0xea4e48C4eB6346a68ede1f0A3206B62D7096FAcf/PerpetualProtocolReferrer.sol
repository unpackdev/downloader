// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./PerpFiOwnableUpgrade.sol";

contract PerpetualProtocolReferrer is PerpFiOwnableUpgrade {
    enum UpsertAction{ ADD, REMOVE, UPDATE }

    struct Referrer {
        uint256 createdAt;
        string referralCode;
        address createdBy;
    }

    struct Referee {
        string referralCode;
        uint256 createdAt;
        uint256 updatedAt;
    }

    event OnReferralCodeCreated (
        address createdBy,
        address createdFor,
        uint256 timestamp,
        string referralCode
    );

    event OnReferralCodeUpserted (
        address addr,
        UpsertAction action,
        uint256 timestamp,
        string newReferralCode,
        string oldReferralCode
    );

    mapping(address => Referrer) public referrerStore;
    mapping(address => Referee) public refereeStore;
    mapping(string => address) public referralCodeToReferrerMap;

    constructor() public {
        __Ownable_init();
    }

    function createReferralCode(address createdFor, string memory referralCode) external onlyOwner {
        address sender = msg.sender;
        uint256 timestamp = block.timestamp;
        // the referrer for a code that already exists, used to check against a referral code
        // that has already been assigned
        address existingReferralCodeReferrer = referralCodeToReferrerMap[referralCode];
        // the referrer being assigned a new code cannot have an existing code - check using this
        Referrer memory existingReferrer = referrerStore[createdFor];
        require(bytes(referralCode).length > 0, "Provide a referral code.");
        require(createdFor != address(0x0), "Provide an address to create the code for.");
        require(existingReferralCodeReferrer == address(0x0), "This referral code has already been assigned to an address.");
        require(bytes(existingReferrer.referralCode).length == 0, "This address already has a referral code assigned.");

        referrerStore[createdFor] = Referrer(timestamp, referralCode, sender);
        referralCodeToReferrerMap[referralCode] = createdFor;
        emit OnReferralCodeCreated(sender, createdFor, timestamp, referralCode);
    }

    function getReferralCodeByReferrerAddress(address referralOwner) external view returns (string memory) {
        Referrer memory referrer = referrerStore[referralOwner];
        require(bytes(referrer.referralCode).length > 0, "Referral code doesn't exist");
        return (referrer.referralCode);
    }

    function getMyRefereeCode() public view returns (string memory) {
        Referee memory referee = refereeStore[msg.sender];
        require(bytes(referee.referralCode).length > 0, "You do not have a referral code");
        return (referee.referralCode);
    }

    function setReferralCode(string memory referralCode) public {
        address sender = msg.sender;
        address referrer = referralCodeToReferrerMap[referralCode];
        uint256 timestamp = block.timestamp;
        UpsertAction action;
        string memory oldReferralCode = referralCode;

        require(referrer != sender, "You cannot be a referee of a referral code you own");
        
        // the referee in we are performing the upserts for
        Referee storage referee = refereeStore[sender];

        // when referral code is supplied by the referee
        if (bytes(referralCode).length > 0) {
            // if mapping does not exist, referral code doesn't exist.
            require(referrer != address(0x0), "Referral code does not exist");

            // if there is a referral code already for that referee, update it with the supplied one
            if (bytes(referee.referralCode).length > 0) {
                oldReferralCode = referee.referralCode;
                referee.referralCode = referralCode;
                referee.updatedAt = timestamp;
                action = UpsertAction.UPDATE;
            } else {
                // if a code doesn't exist for the referee, create the referee
                refereeStore[sender] = Referee(referralCode, timestamp, timestamp);
                action = UpsertAction.ADD;
            }
        // if the referral is not supplied and referee exists, delete referee
        } else if (bytes(referee.referralCode).length > 0) {
            oldReferralCode = referee.referralCode;
            delete refereeStore[sender];
            action = UpsertAction.REMOVE;
        }

        if (bytes(referralCode).length == 0 && bytes(referee.referralCode).length == 0) {
            revert("No referral code was supplied or found.");
        }
        emit OnReferralCodeUpserted(sender, action, timestamp, referralCode, oldReferralCode);
    }
}