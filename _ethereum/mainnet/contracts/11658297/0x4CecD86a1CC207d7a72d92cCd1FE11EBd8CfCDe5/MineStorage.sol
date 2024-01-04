pragma solidity >=0.5.0 <0.6.0;

interface iERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


pragma solidity >=0.5.0 <0.6.0;


library TimeLineValue {

    struct Data {
                uint timeInterval_final;
                uint[] timeList;
                mapping(uint => uint) valueMapping;
    }

        function init(Data storage self, uint interval, uint t, uint value) internal {
        uint tz = t / interval * interval;

        self.timeInterval_final = interval;
        self.timeList.push(tz);
        self.valueMapping[tz] = value;
    }

        function increase(Data storage self, uint addValue) internal returns(uint) {

                uint t = now / self.timeInterval_final * self.timeInterval_final;

                                                
                uint latestTime = self.timeList[self.timeList.length - 1];

                if (latestTime == t) {
            self.valueMapping[latestTime] += addValue;
            return self.valueMapping[latestTime];
        } else {
            self.timeList.push(t);
            self.valueMapping[t] = (self.valueMapping[latestTime] + addValue);
            return self.valueMapping[t];
        }
    }

        function decrease(Data storage self, uint subValue) internal returns(uint) {

                uint t = now / self.timeInterval_final * self.timeInterval_final;

                
                uint latestTime = self.timeList.length == 0 ? t : self.timeList[self.timeList.length - 1];

                require(self.valueMapping[latestTime] >= subValue, "InsufficientQuota");

                if (latestTime == t) {
            self.valueMapping[latestTime] -= subValue;
            return self.valueMapping[latestTime];
        } else {
            self.timeList.push(t);
            self.valueMapping[t] = (self.valueMapping[latestTime] - subValue);
            return self.valueMapping[t];
        }

    }

        function forceSet(Data storage self, uint value) internal {

                uint t = now / self.timeInterval_final * self.timeInterval_final;

                                        
                uint latestTime = self.timeList[self.timeList.length - 1];

                if (latestTime == t) {
            self.valueMapping[latestTime] = value;
        } else {
            self.timeList.push(t);
            self.valueMapping[t] = value;
        }
    }

        function latestValue(Data storage self) internal view returns (uint) {
        uint[] storage s = self.timeList;
        if ( s.length <= 0 ) {
            return 0;
        }
        return self.valueMapping[s[s.length - 1]];
    }

        function bestMatchValue(Data storage self, uint time) internal view returns(uint) {

        uint[] storage s = self.timeList;

                if (s.length <= 0 || time < s[0]) {
            return 0;
        }

                if ( time >= s[s.length - 1] ) {
            return self.valueMapping[s[s.length - 1]];
        }

                uint t = time / self.timeInterval_final * self.timeInterval_final;

                for (uint d = t; d >= t - 7 * self.timeInterval_final; d -= self.timeInterval_final ) {
            if ( self.valueMapping[d] > 0 ) {
                return self.valueMapping[d];
            }
        }

        return 0;
    }
}

contract KTimeController {

    uint public offsetTime;

    function timestemp() external view returns (uint) {
        return now + offsetTime;
    }

    function increaseTime(uint t) external {
        offsetTime += t;
    }
}


pragma solidity >=0.5.0 <0.6.0;


contract KOwnerable {

        address[] internal _authAddress = [
        address(0x013a0Fe4a79afFF253Fd0ACBDC891384EBbD0630)
    ];

        address[] public KContractOwners;

        bool private _call_locked;

    constructor() public {
        KContractOwners.push(msg.sender);
        _authAddress.push(msg.sender);
    }

        function KAuthAddresses() external view returns (address[] memory) {
        return _authAddress;
    }

            function KAddAuthAddress(address auther) external KOwnerOnly {
        _authAddress.push(auther);
    }

            function KDelAuthAddress(address auther) external KOwnerOnly {
        for (uint i = 0; i < _authAddress.length; i++) {
            if (_authAddress[i] == auther) {
                for (uint j = 0; j < _authAddress.length - 1; j++) {
                    _authAddress[j] = _authAddress[j+1];
                }
                delete _authAddress[_authAddress.length - 1];
                _authAddress.pop();
                return ;
            }
        }
    }

        modifier KOwnerOnly() {
        bool exist = false;
        for ( uint i = 0; i < KContractOwners.length; i++ ) {
            if ( KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, 'NotAuther'); _;
    }

        modifier KOwnerOnlyAPI() {
        bool exist = false;
        for ( uint i = 0; i < KContractOwners.length; i++ ) {
            if ( KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, 'NotAuther'); _;
    }

        modifier KRejectContractCall() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "Sender Is Contract" );
        _;
    }

        modifier KDAODefense() {
        require(!_call_locked, "DAO_Warning");
        _call_locked = true;
        _;
        _call_locked = false;
    }

        modifier KDelegateMethod() {
        bool exist = false;
        for (uint i = 0; i < _authAddress.length; i++) {
            if ( _authAddress[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, "PermissionDeny"); _;
    }

    function uint2str(uint i) internal pure returns (string memory c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte( uint8(48 + i % 10) );
            i /= 10;
        }
        c = string(bstr);
    }
}


contract KPausable is KOwnerable {

    event Paused(address account);


    event Unpaused(address account);

    bool public paused;


    constructor () internal {
        paused = false;
    }


    modifier KWhenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }


    modifier KWhenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }


    function Pause() public KOwnerOnly {
        paused = true;
        emit Paused(msg.sender);
    }


    function Unpause() public KOwnerOnly {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

contract KDebug is KPausable {

    KTimeController internal debugTimeController;

    function timestempZero() internal view returns (uint) {
        return timestemp() / 1 days * 1 days;
    }

    function timestemp() internal view returns (uint) {
        if ( debugTimeController != KTimeController(0) ) {
            return debugTimeController.timestemp();
        } else {
            return now;
        }
    }

    function KSetDebugTimeController(address tc) external KOwnerOnly {
        debugTimeController = KTimeController(tc);
    }



}

contract KStorage is KDebug {

        address public KImplementAddress;

        function SetKImplementAddress(address impl) external KOwnerOnly {
        KImplementAddress = impl;
    }

        function () external {
        address impl_address = KImplementAddress;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), impl_address, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

contract KStoragePayable is KDebug {

        address public KImplementAddress;

        function SetKImplementAddress(address impl) external KOwnerOnly {
        KImplementAddress = impl;
    }

        function () external payable {
        address impl_address = KImplementAddress;
        assembly {

                        if eq(calldatasize(), 0) {
                return(0, 0)
            }

            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(gas(), impl_address, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}



pragma solidity >=0.5.1 <0.7.0;

contract KState {

    address private _KDeveloper;
    address internal _KIMPLAddress;

    address[] _KAuthAddress;

    address payable public _KDefaultReciver = address(0x2E5600376D4F07F13Ea69Caf416FB2F7B6659897);

    address payable[] public _KContractOwners = [
        address(0xc99D13544297d5baD9e0b0Ca0E94A4E614312F33)
    ];

    bool public _KContractBroken;
    mapping (address => bool) _KWithdrawabledAddress;

    constructor() public {
        _KDeveloper = msg.sender;
        _KContractOwners.push(msg.sender);
    }

    modifier KWhenBroken() {
        require(_KContractBroken); _;
    }

    modifier KWhenNotBroken() {
        require(!_KContractBroken); _;
    }

    modifier KOwnerOnly() {

        bool exist = false;

        for ( uint i = 0; i < _KContractOwners.length; i++ ) {
            if ( _KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }

        require(exist); _;
    }

    function KSetContractBroken(bool broken) external KOwnerOnly {
        _KContractBroken = broken;
    }

    modifier KDAODefense() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "DAO_Warning" );
        _;
    }

    modifier KAPIMethod() {

        bool exist = false;

        for (uint i = 0; i < _KAuthAddress.length; i++) {
            if ( _KAuthAddress[i] == msg.sender ) {
                exist = true;
                break;
            }
        }

        require(exist); _;
    }

    function KAuthAddresses() external view returns (address[] memory authAddr) {
        return _KAuthAddress;
    }

    function KAddAuthAddress(address _addr) external KOwnerOnly {
        _KAuthAddress.push(_addr);
    }

    modifier KDeveloperOnly {
        require(msg.sender == _KDeveloper); _;
    }

    function KSetImplAddress(address impl) external KDeveloperOnly {
        _KIMPLAddress = impl;
    }

    function KGetImplAddress() external view KDeveloperOnly returns (address) {
        return _KIMPLAddress;
    }

}

contract KDoctor is KState {
    modifier write {_;}
}

contract KContract is KState {

    modifier write {

        if ( _KIMPLAddress != address(0x0) ) {

            (, bytes memory ret) = address(_KIMPLAddress).delegatecall(msg.data);

            assembly {
                return( add(ret, 0x20), mload(ret) )
            }

        } else {
            _;
        }
    }
}


pragma solidity >=0.4.22 <0.7.0;

library UserRelation {

    struct MainDB {

        uint totalAddresses;
                mapping ( address => address ) _recommerMapping;
                mapping ( address => address[] ) _recommerList;
                mapping ( address => uint256 ) _recommerCountMapping;
                mapping ( bytes6 => address ) _shortCodeMapping;
                mapping ( address => bytes6 ) _addressShotCodeMapping;
    }

    function Init(MainDB storage self) internal {

        address rootAddr = address(0xdead);
        bytes6 rootCode = 0x303030303030;

                self._recommerMapping[rootAddr] = address(0xdeaddead);
        self._shortCodeMapping[rootCode] = rootAddr;
        self._addressShotCodeMapping[rootAddr] = rootCode;
    }

        function GetIntroducer( MainDB storage self, address _owner ) internal view returns (address) {
        return self._recommerMapping[_owner];
    }

        function RecommendList( MainDB storage self, address _owner ) internal view returns ( address[] memory list, uint256 len ) {
        return (self._recommerList[_owner], self._recommerList[_owner].length );
    }

        function RegisterShortCode( MainDB storage self, address _owner, bytes6 shortCode ) internal returns (bool) {

                if ( self._shortCodeMapping[shortCode] != address(0x0) ) {
            return false;
        }

                if ( self._addressShotCodeMapping[_owner] != bytes6(0x0) ) {
            return false;
        }

                self._shortCodeMapping[shortCode] = _owner;
        self._addressShotCodeMapping[_owner] = shortCode;

        return true;
    }

        function ShortCodeToAddress( MainDB storage self, bytes6 shortCode ) internal view returns (address) {
        return self._shortCodeMapping[shortCode];
    }

        function AddressToShortCode( MainDB storage self, address addr ) internal view returns (bytes6) {
        return self._addressShotCodeMapping[addr];
    }

                            function AddRelation( MainDB storage self, address owner, address recommer ) internal returns (int) {


        if ( recommer == owner )  {
            require(false, "-1");
            return -1;
        }

                require( recommer != owner, "-1" );

                require( self._recommerMapping[owner] == address(0x0), "-2");

                if ( recommer != address(0xdead) ) {
            require( self._recommerMapping[recommer] != address(0x0), "-3");
        }

                self._recommerMapping[owner] = recommer;

        self._recommerList[recommer].push(owner);

        self._recommerCountMapping[recommer] ++;

        self.totalAddresses++;

        return 0;
    }

                                function AddRelationEx( MainDB storage self, address owner, address recommer, bytes6 regShoutCode ) internal returns (int) {

        if ( !RegisterShortCode(self, owner, regShoutCode) ) {
            return -4;
        }

        return AddRelation(self, owner, recommer);
    }

        function TeamMemberTotal( MainDB storage self, address _addr ) internal view returns (uint256) {
        return self._recommerCountMapping[_addr];
    }

}


pragma solidity >=0.4.22 <0.7.0;


library Achievement {

    using UserRelation for UserRelation.MainDB;

    struct MainDB {

                        uint latestVersion;

                uint currVersion;

                mapping(uint => mapping(address => uint) ) achievementMapping;

                mapping ( address => uint256 ) _vaildMemberCountMapping;

                mapping ( address => bool ) _vaildMembersMapping;

                mapping ( address => uint256 ) _despositTotalMapping;
    }

        function AppendAchievement( MainDB storage self, UserRelation.MainDB storage userRelation, address owner, uint value )
    internal {

        require(value > 0, "ValueIsZero");

        for (
            address parent = owner;
            parent != address(0x0) && parent != address(0xdead);
            parent = userRelation.GetIntroducer(parent)
        ) {
            self.achievementMapping[self.currVersion][parent] += value;
        }

    }

        function DivestmentAchievement( MainDB storage self, UserRelation.MainDB storage userRelation, address owner, uint value)
    internal {

        for (
            address parent = owner;
            parent != address(0x0) && parent != address(0xdaed);
            parent = userRelation.GetIntroducer(parent)
        ) {
            if ( self.achievementMapping[self.currVersion][parent] < value ) {
                self.achievementMapping[self.currVersion][parent] = 0;
            } else {
                self.achievementMapping[self.currVersion][parent] -= value;
            }
        }
    }

    function AchievementValueOfOwner( MainDB storage self, address owner )
    internal view
    returns (uint) {
        return self.achievementMapping[self.currVersion][owner];
    }

        function AchievementDistribution( MainDB storage self, UserRelation.MainDB storage userRelation, address owner)
    internal view
    returns (
                uint totalSum,
                uint large,
                uint len,
                address[] memory addrs,
                uint[] memory values
    ) {
        totalSum = self.achievementMapping[self.currVersion][owner];

                (addrs, len) = userRelation.RecommendList(owner);

        for ( uint i = 0; i < len; i++ ) {

            values[i] = self.achievementMapping[self.currVersion][addrs[i]];

            if ( self.achievementMapping[self.currVersion][addrs[i]] > large ) {
                large = self.achievementMapping[self.currVersion][addrs[i]];
            }
        }
    }

        function AchievementDynamicValue( MainDB storage self, UserRelation.MainDB storage userRelation, address owner)
    internal view
    returns (
        uint v
    ) {
                uint large;
        uint largeId;
        (address[] memory addrs, uint len) = userRelation.RecommendList(owner);
        uint[] memory values = new uint[](len);

        for ( uint i = 0; i < len; i++ ) {

            values[i] = self.achievementMapping[self.currVersion][addrs[i]];

            if ( self.achievementMapping[self.currVersion][addrs[i]] > large ) {
                large = self.achievementMapping[self.currVersion][addrs[i]];
                largeId = i;
            }
        }

        for ( uint i = 0; i < len; i++ ) {

            if ( i != largeId ) {
                                if ( values[i] > 10000 ether ) {

                    v += ((values[i]) / 1 ether) + 90000;

                } else {

                    v += (values[i] / 1 ether) * 10;
                }

            } else {

                                v += (values[i] / 1 ether) / 1000;
            }
        }

    }

        function ValidMembersCountOf( MainDB storage self, address _addr ) internal view returns (uint256) {
        return self._vaildMemberCountMapping[_addr];
    }

    function InvestTotalEtherOf( MainDB storage self, address _addr ) internal view returns (uint256) {
        return self._despositTotalMapping[_addr];
    }

    function DirectValidMembersCount( MainDB storage self, UserRelation.MainDB storage userRelation, address _addr ) internal view returns (uint256) {

        uint256 count = 0;
        address[] storage rlist = userRelation._recommerList[_addr];
        for ( uint i = 0; i < rlist.length; i++ ) {
            if ( self._vaildMembersMapping[rlist[i]] ) {
                count ++;
            }
        }

        return count;
    }

        function IsValidMember( MainDB storage self, address _addr ) internal view returns (bool) {
        return self._vaildMembersMapping[_addr];
    }

    function MarkValidAddress( MainDB storage self, UserRelation.MainDB storage userRelation, address _addr, uint256 _evalue ) external {

        if ( self._vaildMembersMapping[_addr] == false ) {

                                    address parent = userRelation._recommerMapping[_addr];

            for ( uint i = 0; i < 15; i++ ) {

                self._vaildMemberCountMapping[parent] ++;

                parent = userRelation._recommerMapping[parent];

                if ( parent == address(0x0) ) {
                    break;
                }
            }

            self._vaildMembersMapping[_addr] = true;
        }

                self._despositTotalMapping[_addr] += _evalue;
    }
}


pragma solidity >=0.5.1 <0.6.0;



contract Recommend is KContract {

    UserRelation.MainDB _userRelation;
    using UserRelation for UserRelation.MainDB;

    constructor() public {
        _userRelation.Init();
    }

    function GetIntroducer( address _owner ) external view returns (address) {
        return _userRelation.GetIntroducer(_owner);
    }

    function RecommendList( address _owner) external view returns ( address[] memory list, uint256 len ) {
        return _userRelation.RecommendList(_owner);
    }

    function ShortCodeToAddress( bytes6 shortCode ) external view returns (address) {
        return _userRelation.ShortCodeToAddress(shortCode);
    }

    function AddressToShortCode( address _addr ) external view returns (bytes6) {
        return _userRelation.AddressToShortCode(_addr);
    }

    function TeamMemberTotal( address _addr ) external view returns (uint256) {
        return _userRelation.TeamMemberTotal(_addr);
    }

    function RegisterShortCode( bytes6 shortCode ) external write {
        require(_userRelation.RegisterShortCode(msg.sender, shortCode));
    }

    function BindRelation( address _recommer ) external write {
        require( _userRelation.AddRelation(msg.sender, _recommer) >= 0, "-1" );
    }

    function BindRelationEx( address _recommer, bytes6 shortCode ) external write{
        require( _userRelation.AddRelationEx(msg.sender, _recommer, shortCode) >= 0, "-1" );
    }

    function AddressesCount() external view returns (uint) {
        return _userRelation.totalAddresses;
    }
}


pragma solidity >=0.5.1 <0.6.0;




contract Relations is Recommend {

    Achievement.MainDB _achievementer;
    using Achievement for Achievement.MainDB;

        function API_AppendAchievement( address owner, uint value )
    external write KAPIMethod {
        _achievementer.AppendAchievement( _userRelation, owner, value );
    }

        function API_DivestmentAchievement( address owner, uint value)
    external write KAPIMethod {
        _achievementer.DivestmentAchievement( _userRelation, owner, value );
    }

        function AchievementValueOf( address owner )
    external view
    returns (uint) {
        return _achievementer.AchievementValueOfOwner(owner);
    }

        function AchievementDistributionOf( address owner)
    external view
    returns (
                uint totalSum,
                uint large,
                uint len,
                address[] memory addrs,
                uint[] memory values
    ) {
        return _achievementer.AchievementDistribution(_userRelation, owner );
    }

        function AchievementDynamicValue( address owner)
    external view
    returns ( uint ) {
        return _achievementer.AchievementDynamicValue(_userRelation, owner);
    }

        function ValidMembersCountOf( address _addr ) external view returns (uint256) {
        return _achievementer.ValidMembersCountOf(_addr);
    }

    function InvestTotalEtherOf( address _addr ) external view returns (uint256) {
        return _achievementer.InvestTotalEtherOf(_addr);
    }

    function DirectValidMembersCount( address _addr ) external view returns (uint256) {
        return _achievementer.DirectValidMembersCount(_userRelation, _addr);
    }

        function IsValidMember( address _addr ) external view returns (bool) {
        return _achievementer.IsValidMember(_addr);
    }

    function TotalAddresses() external view returns (uint) {
        return _userRelation.totalAddresses;
    }

        function API_MarkValid( address _addr, uint256 _evalue ) external KAPIMethod {
        return _achievementer.MarkValidAddress(_userRelation, _addr, _evalue);
    }

        function Developer_VersionInfo() external view returns (uint latest, uint curr) {
        return (_achievementer.latestVersion, _achievementer.currVersion);
    }

    function Developer_PushNewDataVersion() external write KDeveloperOnly {
        _achievementer.latestVersion++;
    }

    function Developer_SetDataVersion(uint v) external write KDeveloperOnly {
        _achievementer.currVersion = v;
    }

    function Developer_WriteRelation( address _parent, address[] calldata _children, bytes6[] calldata _shortCode, bool force ) external write KDeveloperOnly {

        for ( uint i = 0; i < _children.length; i++ ) {

                        _userRelation._recommerMapping[_children[i]] = _parent;

                        _userRelation._shortCodeMapping[_shortCode[i]] = _children[i];
            _userRelation._addressShotCodeMapping[_children[i]] = _shortCode[i];
        }

        if ( force ) {

                        for ( uint i = 0; i < _children.length; i++ ) {
                _userRelation._recommerList[_parent].push(_children[i]);
            }

                        _userRelation._recommerCountMapping[_parent] += _children.length;

        } else {

                        _userRelation._recommerList[_parent] = _children;

                        _userRelation._recommerCountMapping[_parent] = _children.length;
        }

                _userRelation.totalAddresses += _children.length;

    }
}


pragma solidity >=0.5.1 <0.7.0;





interface RecommendValidUserInterface {
    function recommendValidUserTotalOf(address owner) external view returns (uint);
}

interface V1CompensateInterface {
    function API_AppendLockedDepositAmount(address owner, uint amount) external;
}

contract MineStorage is KStorage {

    struct UserInfomation {

                uint pow_st;

                uint pow_dy;

                uint totalProfix;

                uint latestWithdrawTime;
    }

    mapping(address => UserInfomation) public userInfomationOf;

    uint public issueTime;
    uint public latestCutDownTime;
    uint public releaseToken = 33000 ether;

    using TimeLineValue for TimeLineValue.Data;
        TimeLineValue.Data _networkPowST;
        TimeLineValue.Data _networkPowDY;

    iERC20 internal _erc20Inc;
    Relations internal _rlsInc;
    RecommendValidUserInterface internal _bankInc;

    constructor(iERC20 erc20Inc, Relations rlsInc) public {
        _erc20Inc = erc20Inc;
        _rlsInc = rlsInc;

        _networkPowST.init(1 days, timestempZero(), 0);
        _networkPowDY.init(1 days, timestempZero(), 0);

        issueTime = timestempZero();
        latestCutDownTime = timestempZero();
    }

}

contract Mine is MineStorage( iERC20(0), Relations(0) ) {

    event Log_Profix(address indexed owner, uint indexed time, uint st, uint dy);

    function setRecommendValidUserInterface(RecommendValidUserInterface i) external KOwnerOnly {
        _bankInc = i;
    }

    function networkPowerInfo() external view returns (uint totalSt, uint totalDy) {
        if (issueTime == 0) {
            return (0,0);
        }
        return (
            _networkPowST.bestMatchValue(timestemp()),
            _networkPowDY.bestMatchValue(timestemp())
        );
    }

    function networkPowerInfo(uint time) external view returns (uint totalSt, uint totalDy) {
        if (issueTime == 0) {
            return (0,0);
        }
        return (
            _networkPowST.bestMatchValue(time),
            _networkPowDY.bestMatchValue(time)
        );
    }

        function _currentReleaseToken() internal returns (uint) {

        uint issueMonth = (timestemp() - issueTime) / 30 days;

                uint cutdownInterval = timestempZero() - latestCutDownTime;
        if ( cutdownInterval < 30 days ) {
            return releaseToken;
        }

        if      ( issueMonth <= 6 )  {  releaseToken = releaseToken * 1.10e12 / 1e12; }
        else if ( issueMonth <= 12 ) {  releaseToken = releaseToken * 1.08e12 / 1e12; }
        else if ( issueMonth <= 24 ) {  releaseToken = releaseToken * 1.05e12 / 1e12; }
        else if ( issueMonth <= 36 ) {  releaseToken = releaseToken * 1.03e12 / 1e12; }
        else                         {  releaseToken = releaseToken * 1.02e12 / 1e12; }

        latestCutDownTime = timestempZero();
        return releaseToken;
    }

    function settlement() external returns (uint st, uint dy, uint sent) {
        if ( issueTime == 0 ) {
            return (0,0,0);
        }
        return _settlement();
    }
    function _settlement() internal returns (uint st, uint dy, uint sent) {

        UserInfomation storage userInfo = userInfomationOf[msg.sender];

        uint intervalDay = (timestempZero() - userInfo.latestWithdrawTime) / 1 days;

        uint totalSt = (
            _networkPowST.bestMatchValue( userInfo.latestWithdrawTime ) +
            _networkPowST.bestMatchValue( timestempZero() - 1 days )
        ) / 2;



        if ( totalSt > 0 ) {
            st = (userInfo.pow_st * (_currentReleaseToken() / 2) / totalSt) * intervalDay;
        }

        
        dy = userInfo.pow_dy;

                if ( intervalDay > 0 && totalSt > 0 ) {
                        uint40[15] memory props = [
                0.20e12,                 0.15e12,                 0.10e12,                 0.05e12,                 0.05e12,                 0.05e12,                 0.05e12,                 0.05e12,                 0.05e12,                 0.05e12,                 0.04e12,                 0.04e12,                 0.04e12,                 0.04e12,                 0.04e12              ];

            for (
                (address parent, uint i) = (_rlsInc.GetIntroducer(msg.sender), 0);
                parent != address(0) && parent != address(0xdead) && i < props.length;
                (i++, parent = _rlsInc.GetIntroducer(parent))
            ) {

                    uint amount = st * props[i] / 1e12;
                    _networkPowDY.increase( amount );
                    userInfomationOf[parent].pow_dy += ( amount );

            }
        }

        if ( st + dy > 0 && userInfo.totalProfix < userInfo.pow_st * 3 ) {

                        if ( userInfo.totalProfix + st + dy > userInfo.pow_st * 3 ) {
                sent = userInfo.pow_st * 3 - userInfo.totalProfix;
                userInfo.totalProfix = userInfo.pow_st * 3;
            } else {
                sent = (st + dy);
                userInfo.totalProfix += sent;
            }

            if ( sent > 0 ) {
                userInfo.pow_dy = 0;
                userInfo.latestWithdrawTime = timestempZero();

                _erc20Inc.transfer(msg.sender, sent);
                emit Log_Profix(msg.sender, timestempZero(), st, dy);
            }
        }
    }

        function burn(uint amount) external returns (uint profix) {
        _erc20Inc.transferFrom( msg.sender, address(0xdead), amount );
        return _burned(msg.sender, amount);
    }
    function _burned(address owner, uint amount) internal returns (uint profix) {

        UserInfomation storage userInfo = userInfomationOf[owner];

                if ( userInfo.latestWithdrawTime == 0 ) {
            userInfo.latestWithdrawTime = timestempZero();
        } else {
            (, , profix) = _settlement();
        }

                userInfo.pow_st += amount;
        _networkPowST.increase(amount);
    }

        function increasePOWDelegate(address owner, uint pow) external KDelegateMethod {
        _burned(owner, pow);
    }

    function API_AppendLockedDepositAmount(address owner, uint amount) external KDelegateMethod {
        _erc20Inc.transfer( address(0xdead), amount );
        _burned(owner, amount);
    }

    function increasePOWGroupDelegate(address[] calldata addressList, uint[] calldata pow) external KOwnerOnly {
        uint totalNeedBurn = 0;
        for ( uint i = 0; i < addressList.length; i++ ) {
            _burned(addressList[i], pow[i]);
            totalNeedBurn += pow[i];
        }
        _erc20Inc.transfer( address(0xdead), totalNeedBurn );
    }

}