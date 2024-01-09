// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC20.sol";
import "./ERC721.sol";
import "./StakeApe.sol";
import "./Team.sol";
import "./Rent.sol";
import "./IAgency.sol";

import "./console.sol";

interface ITokenBall {
    function mintReward(address recipient, uint256 amount) external;

    function burnMoney(address recipient, uint256 amount) external;
}

/**
 * Headquarter of the New Basketball Ape Young Crew Agency
 * Organize matches, stakes the Apes for available for rent, sends rewards, etc
 */
contract NbaycGame is ERC721 {
    bool closed = false;
    // uint256[] public arrStepPoints = [35, 55, 85, 105, 155];

    mapping(uint64 => uint8[]) allTimeIdToMinSkills;
    uint256 minBudgetPerStep = 10000;

    // Structs :
    struct PlayerApe {
        uint64 tokenId;
        uint8 strength;
        uint8 stamina;
        uint8 precision;
        uint8 charisma;
        uint8 style;
        uint128 league;
    }

    uint256 constant baseTrainingRewardRatePerMinute = 100;
    mapping(address => bool) admins;
    address _agencyAddress;
    address _ballAddress;

    address _signer;
    mapping(address => Rent) rentings;
    mapping(uint256 => uint256) idToRentPricePerDay;
    mapping(uint64 => PlayerApe) idToPlayer;

    constructor(
        address adminAddr,
        address _agency,
        address _ball
    ) ERC721("NBAYCGame", "NBAYCG") {
        admins[adminAddr] = true;
        _agencyAddress = _agency;
        _ballAddress = _ball;
        _signer = adminAddr;

        // strength, stamina, precision, charisma, style
        allTimeIdToMinSkills[1716] = [2, 4, 2, 15, 12];
        allTimeIdToMinSkills[2518] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[1223] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[3537] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[2271] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[2759] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[4693] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[2508] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[253] = [5, 5, 5, 5, 5];
        allTimeIdToMinSkills[3388] = [5, 5, 5, 5, 5];
    }

    //
    //// Utility functions
    //

    function putApesToAgency(uint256[] memory ids) external onlyOpenContract {
        IAgency(_agencyAddress).putApesToAgency(ids, msg.sender);
    }

    function getApesFromAgency(uint256[] memory ids) external onlyOpenContract {
        IAgency(_agencyAddress).getApesFromAgency(ids, msg.sender);
    }

    function startTraining(uint256[] memory ids) external onlyOpenContract {
        IAgency(_agencyAddress).setStateForApes(ids, msg.sender, "T");
    }

    function stopTraining(uint256[] memory ids) external onlyOpenContract {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 duration = IAgency(_agencyAddress).stopStateForApe(
                ids[i],
                msg.sender
            );
            totalReward += duration * baseTrainingRewardRatePerMinute; // Could change for lengedaries ? Rares ? Skills ?
        }
        console.log("Total reward : %s", totalReward);
        ITokenBall(_ballAddress).mintReward(msg.sender, totalReward);
    }

    //
    // Renting functions :
    //

    function makeApeAvailableForRenting(
        uint256[] memory ids,
        uint256 pricePerDay
    ) public onlyOpenContract {
        //
        // Require the token is owned by sender

        IAgency(_agencyAddress).setStateForApes(ids, msg.sender, "L");
    }

    function rentApe(uint256[] memory ids, uint8 nbDays)
        public
        onlyOpenContract
    {
        // Check the ape is for rent

        // Check the ape is not owned by me

        // Check sender has enough balls

        // Burn balls

        // Set ape to "rented" till a certain date

        IAgency(_agencyAddress).setStateForApes(ids, msg.sender, "D");
    }

    //
    // Match functions :
    //
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function verifyString(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address signer) {
        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }
        // Maximum length we support
        require(length <= 999999);
        // The length of the message's length in base-10
        uint256 lengthLength = 0;
        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;
        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            // Found a non-zero digit or non-leading zero digit
            lengthLength++;
            // Remove this digit from the message length's current value
            length -= digit * divisor;
            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }
        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function matchLost(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        address signer = verifyString(uint2str(amount), v, r, s);
        console.log("Signer recovered : ", signer, _signer);
        require(signer == _signer, "ECDSA: invalid signature ... cheater");

        require(
            ERC20(_ballAddress).balanceOf(msg.sender) >= amount,
            "You do not have enough balls to play man ;)"
        );
        require(
            amount >= 50000,
            "Cannot pay less than 50000 balls for a match ... cheater"
        );

        // Just pay my match ... I lost it ...
        bool sent = ERC20(_ballAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(sent == true, "Transfer Ko, maybe should be approved ?");
    }

    function matchWon(
        uint256 amount,
        uint64[] memory ids,
        uint64[] memory skills,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(
            ERC20(_ballAddress).balanceOf(msg.sender) >= amount,
            "You do not have enough balls to play man ;)"
        );
        require(
            amount >= 50000,
            "Cannot pay less than 50000 balls for a match ... cheater"
        );
        require(ids.length == 5, "...");
        require(skills.length == 5, "...");


        string memory message = uint2str(amount);
        for (uint i=0; i<5; i++) {
            message = string(abi.encodePacked(message, uint2str(ids[i]), uint2str(skills[i])));
        }
        address signer = verifyString(message, v, r, s);

        console.log("Signer :", signer, _signer);

        require(signer == _signer, "ECDSA: invalid signature ... cheater");

        // Pay my match
        ERC20(_ballAddress).transferFrom(msg.sender, address(this), amount);

        // Check Apes receiving skill points are mine
        for (uint8 i = 0; i < 5; i++) {
            if (skills[i] == 1) idToPlayer[ids[i]].strength++;
            if (skills[i] == 2) idToPlayer[ids[i]].stamina++;
            if (skills[i] == 3) idToPlayer[ids[i]].precision++;
            if (skills[i] == 4) idToPlayer[ids[i]].charisma++;
            if (skills[i] == 5) idToPlayer[ids[i]].style++;
        }
    }

    //
    // Admin functions :
    //

    function setClosed(bool c) public onlyAdmin {
        closed = c;
    }

    function getApePlayer(uint64 id)
        public
        view
        returns (
            uint64,
            uint8,
            uint8,
            uint8,
            uint8,
            uint8,
            uint128
        )
    {
        if (idToPlayer[id].tokenId == 0) {
            return (id, 0, 0, 0, 0, 0, 0);
        } else {
            PlayerApe memory a = idToPlayer[id];
            return (
                a.tokenId,
                a.strength,
                a.stamina,
                a.precision,
                a.charisma,
                a.style,
                a.league
            );
        }
    }

    function getApe(uint256 id)
        public
        view
        returns (
            uint256,
            address,
            bytes1,
            uint256
        )
    {
        return IAgency(_agencyAddress).getApe(id);
    }

    function getOwnerApes(address a) external view returns (uint256[] memory) {
        return IAgency(_agencyAddress).getOwnerApes(a);
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can call this");
        _;
    }

    function setAdmin(address addr) public {
        admins[addr] = true;
    }

    function unsetAdmin(address addr) public {
        delete admins[addr];
    }

    function rewardUser(address owner, uint256 amount) public onlyAdmin {
        ITokenBall(_ballAddress).mintReward(owner, amount);
    }

    function setContracts(address _agency, address _ball) external onlyAdmin {
        _agencyAddress = _agency;
        _ballAddress = _ball;
    }

    modifier onlyOpenContract() {
        require(!closed, "This contract is closed.");
        _;
    }
}
