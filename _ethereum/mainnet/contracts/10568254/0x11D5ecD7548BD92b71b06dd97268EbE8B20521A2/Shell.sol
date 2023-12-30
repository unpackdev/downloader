//        .__           .__  .__                    __         .__        
//   _____|  |__   ____ |  | |  |     _____ _____ _/  |________|__|__  ___
//  /  ___/  |  \_/ __ \|  | |  |    /     \\__  \\   __\_  __ \  \  \/  /
//  \___ \|   Y  \  ___/|  |_|  |__ |  Y Y  \/ __ \|  |  |  | \/  |>    < 
// /____  >___|  /\___  >____/____/ |__|_|  (____  /__|  |__|  |__/__/\_ \
//      \/     \/     \/                  \/     \/                     \/
//
//                   .-.         .-.  .-.                      
//                   : :         : :  : :                      
//              .--. : `-.  .--. : :  : :      .--. .--.  .--. 
//             `._-.': .. :' '_.': :_ : :_  _ ' .; :: ..'' .; :
//             `.__.':_;:_;`.__.'`.__;`.__;:_;`.__.':_;  `._. ;
//                                                        .-. :
//                                                        `._.'
//

pragma solidity >=0.5.0 <0.6.0;

interface USDT {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ShellBase is Context {
    struct X3 {
        uint uplineID;
        uint[] partners;
        uint reinvestCount;
        uint missed;
        uint totalPartners;
        bool active;
    }

    struct X6 {
        uint uplineID;
        uint[] firstLevelPartners;
        uint[] secondLevelPartners;
        uint[] thirdLevelPartners;
        uint reinvestCount;
        uint missed;
        uint totalPartners;
        bool active;
    }

    struct User {
        uint id;
        uint referrerId;
        uint contribution;
        uint earned;
        address wallet;

        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }

    USDT public usdt;
    address public owner;
    uint public totalUser;
    uint public totalEarned;
    uint8 public MAX_LEVEL;

    mapping(uint => User) public users;
    mapping(address => uint) public ids;
    mapping(uint8 => uint) public levelPrices;

    event Registration(address indexed user, address indexed referrer, uint userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, uint caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewPartner(address indexed referrer, uint userID, uint8 matrix, uint8 level, uint8 place);
    event MissPartner(address indexed referrer, uint userID, uint8 matrix, uint8 level);
    event SendDividends(address indexed from, address indexed to, uint payer, uint8 matrix, uint8 level);

    function isRegistered(address _user) public view returns (bool) {
        return (ids[_user] != 0);
    }

    function isValidID(uint _userID) public view returns (bool) {
        return (users[_userID].wallet != address(0) && users[_userID].id > 0);
    }

    function getUserWallet(uint _userID) public view returns (address) {
        return (users[_userID].wallet);
    }

    function getReferrerID(uint _userID) public view returns (uint) {
        return (users[_userID].referrerId);
    }

    function getReferrerWallet(uint _userID) public view returns (address) {
        uint _referrerId = getReferrerID(_userID);
        return (getUserWallet(_referrerId));
    }

    function getUserContribution(uint _userID) public view returns (uint) {
        return (users[_userID].contribution);
    }

    function getUserX3Level(uint _userID) public view returns (uint8) {
        uint8 X3Lv = 0;
        for (uint8 i = 1; i <= MAX_LEVEL; i++) {
            if (users[_userID].x3Matrix[i].active) {
                X3Lv = i;
            }
        }
        return (X3Lv);
    }

    function getUserX6Level(uint _userID) public view returns (uint8) {
        uint8 X6Lv = 0;
        for (uint8 i = 1; i <= MAX_LEVEL; i++) {
            if (users[_userID].x6Matrix[i].active) {
                X6Lv = i;
            }
        }
        return (X6Lv);
    }

    function getUserX3Matrix(uint _userID, uint8 _level) public view returns (uint, uint, uint, uint, bool) {
        uint uplineID = users[_userID].x3Matrix[_level].uplineID;
        uint reinvestCount = users[_userID].x3Matrix[_level].reinvestCount;
        uint missed = users[_userID].x3Matrix[_level].missed;
        uint totalPartners = users[_userID].x3Matrix[_level].totalPartners;
        bool active = users[_userID].x3Matrix[_level].active;
        return (uplineID, reinvestCount, missed, totalPartners, active);
    }

    function getUserX6Matrix(uint _userID, uint8 _level) public view returns (uint, uint, uint, uint, bool) {
        uint uplineID = users[_userID].x6Matrix[_level].uplineID;
        uint reinvestCount = users[_userID].x6Matrix[_level].reinvestCount;
        uint missed = users[_userID].x6Matrix[_level].missed;
        uint totalPartners = users[_userID].x6Matrix[_level].totalPartners;
        bool active = users[_userID].x6Matrix[_level].active;
        return (uplineID, reinvestCount, missed, totalPartners, active);
    }

    function getUserX3Partners(uint _userID, uint8 _level) public view returns (uint[] memory) {
        return (users[_userID].x3Matrix[_level].partners);
    }

    function getUserX6Partners(uint _userID, uint8 _level) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        return (
            users[_userID].x6Matrix[_level].firstLevelPartners,
            users[_userID].x6Matrix[_level].secondLevelPartners,
            users[_userID].x6Matrix[_level].thirdLevelPartners
        );
    }
}

contract Shell is ShellBase {

    constructor(address _owner, address _tether) public {
        totalUser = 0;
        MAX_LEVEL = 12;
        owner = _owner;
        usdt = USDT(_tether);

        levelPrices[1] = 10*1000000;
        for (uint8 i = 2; i <= MAX_LEVEL; i++) {
            levelPrices[i] = levelPrices[i-1] * 2;
        }

        uint _id = totalUser+1;

        User memory user = User({
            id: _id,
            referrerId: uint(0),
            contribution: uint(0),
            earned: uint(0),
            wallet: owner
        });

        users[_id] = user;
        ids[owner] = _id;
        totalUser++;

        for (uint8 i = 1; i <= MAX_LEVEL; i++) {
            users[_id].x3Matrix[i].active = true;
            users[_id].x6Matrix[i].active = true;
        }
    }

    function() external payable {
      revert("Disable fallback.");
    }

    function register(uint _referrerID) external {
        require(!isRegistered(_msgSender()), "User is already registered.");
        require(isValidID(_referrerID), "Referrer ID is invalid.");
        require(usdt.allowance(_msgSender(), address(this)) >= levelPrices[2], "Registration fee exceeds USDT allowance!");
        _register(_msgSender(), _referrerID);
    }

    function upgrade(uint8 _matrix) external {
        require(isRegistered(_msgSender()), "User is not registered.");
        _upgrade(_matrix);
    }

    function _register(address _userAddress, uint _referrerID) private {
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "Cannot be a contract");

        uint _userID = totalUser+1;
        address _referrerAddress = getUserWallet(_referrerID);

        uint x3Upline = _getX3Upline(_userID, _referrerID, 1);
        uint x6Upline = _getX6Upline(_userID, _referrerID, 1);
        _placeUserToX3(_userID, x3Upline, 1);
        _placeUserToX6(_userID, x6Upline, 1);

        User memory user = User({
            id: _userID,
            referrerId: _referrerID,
            contribution: uint(0),
            earned: uint(0),
            wallet: _userAddress
        });

        users[_userID] = user;
        ids[_userAddress] = _userID;
        totalUser++;
        users[_userID].x3Matrix[1].active = true;
        users[_userID].x6Matrix[1].active = true;

        users[_referrerID].contribution += 2;

        emit Registration(_userAddress, _referrerAddress, _userID, _referrerID);
    }

    function _upgrade(uint8 _matrix) private {
        uint8 _level = MAX_LEVEL;
        uint _userID = ids[_msgSender()];
        if (_matrix==3) {
            _level = getUserX3Level(_userID);
        } else if (_matrix==6) {
            _level = getUserX6Level(_userID);
        } else {
            revert("Something is wrong!");
        }
        _level++;

        require(_level>1 && _level<=MAX_LEVEL, "Invalid level, can not upgrade!");
        require(usdt.allowance(_msgSender(), address(this)) >= levelPrices[_level], "Upgrading fee exceeds USDT allowance!");

        if (_matrix==3) {
            _upgradeX3(_userID, _level);
        } else if (_matrix==6) {
            _upgradeX6(_userID, _level);
        } else {
            revert("Something is wrong!");
        }

    }

    function _upgradeX3(uint _userID, uint8 _level) private {
        uint _referrerID = users[_userID].referrerId;
        uint _x3Upline = _getX3Upline(_userID, _referrerID, _level);
        _placeUserToX3(_userID, _x3Upline, _level);
        users[_referrerID].contribution += 2**uint(_level-1);
    }

    function _upgradeX6(uint _userID, uint8 _level) private {
        uint _referrerID = users[_userID].referrerId;
        uint _x6Upline = _getX6Upline(_userID, _referrerID, _level);
        _placeUserToX6(_userID, _x6Upline, _level);
        users[_referrerID].contribution += 2**uint(_level-1);
    }

    function _getX3Upline(uint _userID, uint _referrerID, uint8 _level) private returns(uint) {
        uint _id = _referrerID;
        while (true) {
            if (users[_id].x3Matrix[_level].active) {
                return _id;
            } else {
                users[_id].x3Matrix[_level].missed++;
                address _addr = getUserWallet(_id);
                emit MissPartner(_addr, _userID, 3, _level);
                _id = users[_id].referrerId;
            }
        }
    }

    function _getX6Upline(uint _userID, uint _referrerID, uint8 _level) private returns(uint) {
        uint _id = _referrerID;
        while (true) {
            if (users[_id].x6Matrix[_level].active) {
                return _id;
            } else {
                users[_id].x6Matrix[_level].missed++;
                address _addr = getUserWallet(_id);
                emit MissPartner(_addr, _userID, 6, _level);
                _id = users[_id].referrerId;
            }
        }
    }

    function _placeUserToX3(uint _userID, uint _upline, uint8 _level) private {
        if (users[_upline].x3Matrix[_level].partners.length < 2) {
            users[_upline].x3Matrix[_level].partners.push(_userID);
            emit NewPartner(users[_upline].wallet, _userID, 3, _level, uint8(users[_upline].x3Matrix[_level].partners.length));
            users[_upline].x3Matrix[_level].totalPartners += 1;
            _sendDividends(_userID, _upline, 3, _level);
        } else {
            users[_upline].x3Matrix[_level].partners = new uint[](0);
            uint _higher = users[_upline].x3Matrix[_level].uplineID;
            address _higherAddr = users[_higher].wallet;
            emit Reinvest(users[_upline].wallet, _higherAddr, _userID, 3, _level);
            _sendDividends(_upline, _higher, 3, _level);
        }

        users[_userID].x3Matrix[_level].uplineID = _upline;
        users[_userID].x3Matrix[_level].partners = new uint[](0);
        users[_userID].x3Matrix[_level].reinvestCount = 0;
        users[_userID].x3Matrix[_level].missed = 0;
        users[_userID].x3Matrix[_level].totalPartners = 0;
        users[_userID].x3Matrix[_level].active = true;
    }

    function _placeUserToX6(uint _userID, uint _upline, uint8 _level) private {
        _placeToX6(_userID, _upline, _level);
    }

    function _placeToX6(uint _userID, uint _upline, uint8 _level) private {
        uint _lenFirst = users[_upline].x6Matrix[_level].firstLevelPartners.length;
        if (_lenFirst<2) {
            // up - 1
            users[_upline].x6Matrix[_level].firstLevelPartners.push(_userID);
            emit NewPartner(users[_upline].wallet, _userID, 6, _level, uint8(_lenFirst));
            users[_upline].x6Matrix[_level].totalPartners += 1;

            uint _higher = users[_upline].x6Matrix[_level].uplineID;
            if (_higher==0) {
                _sendDividends(_upline, 1, 6, _level);
                users[_userID].x6Matrix[_level].uplineID = _upline;
                users[_userID].x6Matrix[_level].firstLevelPartners = new uint[](0);
                users[_userID].x6Matrix[_level].secondLevelPartners = new uint[](0);
                users[_userID].x6Matrix[_level].thirdLevelPartners = new uint[](0);
                users[_userID].x6Matrix[_level].reinvestCount = 0;
                users[_userID].x6Matrix[_level].missed = 0;
                users[_userID].x6Matrix[_level].totalPartners = 0;
                users[_userID].x6Matrix[_level].active = true;
                return;
            }
            uint _lengHiSecond = users[_higher].x6Matrix[_level].secondLevelPartners.length;
            uint _lengHiThird = users[_higher].x6Matrix[_level].thirdLevelPartners.length;

            // higher - 2
            if (users[_higher].x6Matrix[_level].firstLevelPartners[0] == _upline && _lengHiSecond<2) {
                users[_higher].x6Matrix[_level].secondLevelPartners.push(_userID);
                emit NewPartner(users[_higher].wallet, _userID, 6, _level, uint8(_lengHiSecond)+2);
                users[_higher].x6Matrix[_level].totalPartners += 1;
            } else if (users[_higher].x6Matrix[_level].firstLevelPartners[1] == _upline && _lengHiThird<2) {
                users[_higher].x6Matrix[_level].thirdLevelPartners.push(_userID);
                emit NewPartner(users[_higher].wallet, _userID, 6, _level, uint8(_lengHiThird)+4);
                users[_higher].x6Matrix[_level].totalPartners += 1;
            }

            // reinvest
            if (users[_higher].x6Matrix[_level].secondLevelPartners.length>=2 && users[_higher].x6Matrix[_level].thirdLevelPartners.length>=2) {
                uint _highest = users[_higher].x6Matrix[_level].uplineID;
                _highest = users[_highest].x6Matrix[_level].uplineID;

                users[_higher].x6Matrix[_level].firstLevelPartners = new uint[](0);
                users[_higher].x6Matrix[_level].secondLevelPartners = new uint[](0);
                users[_higher].x6Matrix[_level].thirdLevelPartners = new uint[](0);
                emit Reinvest(users[_higher].wallet, users[_highest].wallet, _userID, 6, _level);
                _sendDividends(_upline, _highest, 6, _level);
            } else {
                _sendDividends(_userID, _higher, 6, _level);
            }
        } else {
            uint _lengSecond = users[_upline].x6Matrix[_level].secondLevelPartners.length;
            uint _lengThird = users[_upline].x6Matrix[_level].thirdLevelPartners.length;
            if (_lengSecond<2) {
                _placeUserToX6(_userID, users[_upline].x6Matrix[_level].secondLevelPartners[0], _level);
            } else if (_lengThird<2) {
                _placeUserToX6(_userID, users[_upline].x6Matrix[_level].secondLevelPartners[1], _level);
            } else {
                revert("Something is wrong!");
            }
            return;
        }

        users[_userID].x6Matrix[_level].uplineID = _upline;
        users[_userID].x6Matrix[_level].firstLevelPartners = new uint[](0);
        users[_userID].x6Matrix[_level].secondLevelPartners = new uint[](0);
        users[_userID].x6Matrix[_level].thirdLevelPartners = new uint[](0);
        users[_userID].x6Matrix[_level].reinvestCount = 0;
        users[_userID].x6Matrix[_level].missed = 0;
        users[_userID].x6Matrix[_level].totalPartners = 0;
        users[_userID].x6Matrix[_level].active = true;
    }

    function _sendDividends(uint _from, uint _to, uint8 _matrix, uint8 _level)  private {
        uint _amount = levelPrices[_level];
        address _fromAddr = getUserWallet(_from);
        address _toAddr = owner;
        totalEarned += _amount;
        if (_to>0) {
            _toAddr = users[_to].wallet;
            users[_to].earned += _amount;
        }
        usdt.transferFrom(_msgSender(), _toAddr, _amount);
        emit SendDividends(_fromAddr, _toAddr, ids[_msgSender()], _matrix, _level);
    }

}