// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./LGate.sol";
import "./IMarketorV1State.sol";
import "./TTSwapV1Marketor.sol";
import "./ITTSwapV1Gator.sol";

contract TTSwapV1Gator is ITTSwapV1Gator {
    //门户信息
    //Gateaddress=>GateInfo
    mapping(address => LGate.Info) public gateList;
    //Gateaddress=>GateInfo
    mapping(address => LGate.DetailInfo) public gateDetailList;
    //记录门户编号
    //GateNo=>Gateaddess
    mapping(uint128 => address) public gateNumbers;
    //记录市场中门户新增门户的编号
    uint128 public maxGateNumbers;

    //记录管理员合约地址
    address public override marketorContractAddress;
    //记录市场创建者地址
    address public marketCreator;

    //构建时
    constructor(address _marketorContractAddress, address _marketCreator) {
        marketorContractAddress = _marketorContractAddress;
        marketCreator = _marketCreator;
        maxGateNumbers = 1;
    }

    /// @notice 只能是通过市场管理员认证的门户可以调用
    /// @dev 只能是通过市场管理员认证的门户才可以调用
    modifier onlyGator() {
        require(
            gateList[msg.sender].marketunlock == true,
            "the caller must be valid gater"
        );
        _;
    }

    /// @notice 只能是市场创建者可以调用
    /// @dev 只能是市场创建者可以调用
    modifier onlyMarketCreator() {
        require(
            marketCreator == msg.sender,
            "the caller must be valid market creator"
        );
        _;
    }

    /// @notice 只能是通过市场认证的市场管理员户可以调用
    /// @dev 只能是通过市场认证的市场管理员户可以调用
    modifier onlyMarketor() {
        require(
            IMarketorV1State(marketorContractAddress).isValidMarketor(
                msg.sender
            ),
            "the caller must be valid market manager"
        );
        _;
    }

    /// @notice 设置门户合约的管理员合约
    /// @dev 设置门户合约的管理员合约
    function setGaterEnv(
        address _marketorContractAddress,
        address _marketCreator
    ) external override onlyMarketCreator {
        marketorContractAddress = _marketorContractAddress;
        marketCreator = _marketCreator;
    }

    /////////////////////////门户管理-市场////////////////////////////
    ///////////////////////// Gate Manage///////////////////////////
    /// @notice 市场管理员冻结门户
    /// @dev 市场管理员冻结门户
    function lockGatebyMarketor(
        address _gatoraddress
    ) external override onlyMarketor {
        require(
            gateList[_gatoraddress].isUsed == true,
            "the gator isnot exist"
        );
        gateList[_gatoraddress].marketunlock = false;
        emit e_lockGatebyMarketor(_gatoraddress, msg.sender);
    }

    /// @notice 市场管理员解冻门户
    /// @dev 市场管理员解冻门户
    function unlockGatebyMarketor(
        address _gatoraddress
    ) external override onlyMarketor {
        require(
            gateList[_gatoraddress].isUsed == true,
            "the gator isnot exist"
        );
        gateList[_gatoraddress].marketunlock = true;
        emit e_unlockGatebyMarketor(_gatoraddress, msg.sender);
    }

    /// @notice 市场管理员更新门户
    /// @dev 市场管理员更新门户
    function updateGatebyMarketor(
        LGate.Info memory _gator
    ) external override onlyMarketor {
        require(
            gateList[_gator.gateAddress].isUsed == true,
            "the gator is exister"
        );
        _gator.marketunlock = gateList[_gator.gateAddress].marketunlock;
        _gator.gateunlock = gateList[_gator.gateAddress].gateunlock;
        gateList[_gator.gateAddress] = _gator;
        emit e_updateGatebyMarketor(
            _gator.gateAddress,
            _gator.name,
            msg.sender
        );
    }

    /// @notice 市场管理员删除门户
    /// @dev 市场管理员删除门户
    function delGatebyMarketor(address _gator) external override onlyMarketor {
        require(gateList[_gator].isUsed == true, "the gator is exister");

        delete gateList[_gator];
        emit e_delGatebyMarketor(_gator, msg.sender);
    }

    ///////////////////////// 门户管理-门户////////////////////////////
    ///////////////////////// Gate Manage///////////////////////////
    /// @notice 市场认证后的门户临时冻结自己
    /// @dev 市场认证后的门户临时冻结自己
    function lockGatebyGater() external override onlyGator {
        require(
            gateList[msg.sender].isUsed == true &&
                gateList[msg.sender].gateAddress == msg.sender,
            "the gator isnot exist"
        );
        gateList[msg.sender].gateunlock = false;

        emit e_lockGatebyGater(msg.sender);
    }

    /// @notice 市场认证后的门户临时解冻自己
    /// @dev 市场认证后的门户临时解冻自己
    function unlockGatebyGater() external override onlyGator {
        require(
            gateList[msg.sender].isUsed == true &&
                gateList[msg.sender].gateAddress == msg.sender,
            "the gator isnot exist"
        );
        gateList[msg.sender].gateunlock = true;
        emit e_unlockGatebyGater(msg.sender);
    }

    /// @notice 市场认证后的门户临时更新自己
    /// @dev 市场认证后的门户临时更新自己
    function updateGatebyGator(bytes32 _name) external override onlyGator {
        gateList[msg.sender].name = _name;
        emit e_updateGatebyGator(msg.sender, _name);
    }

    /// @notice 申请成为门户
    /// @dev 申请成为门户
    function addGater(LGate.Info memory _gator) external override {
        require(
            gateList[_gator.gateAddress].isUsed != true,
            "the gator is exister"
        );
        require(_gator.gateAddress == msg.sender, "the gator is your");
        _gator.marketunlock = false; //默认是被冻结状态
        _gator.gateunlock = false; //默认是被冻结状态
        _gator.gateNo = maxGateNumbers; //门户编号
        _gator.createtimestamp = block.timestamp; //创建时间
        _gator.isUsed = true;
        require(maxGateNumbers + 1 > maxGateNumbers, "the gator is your");
        gateList[_gator.gateAddress] = _gator; //添加门户信息到门户列表
        gateNumbers[maxGateNumbers] = _gator.gateAddress;
        maxGateNumbers += 1;
        emit e_addGater(_gator.gateAddress, _gator.name);
    }

    /// @notice 门户添加门户详情信息
    /// @dev 门户添加门户详情信息
    function addGaterDetailInfo(
        LGate.DetailInfo memory _gatorDatailinfo
    ) external override {
        require(gateList[msg.sender].isUsed == true, "the gator is not exist");
        gateDetailList[msg.sender] = _gatorDatailinfo;
        emit e_addGaterDetail(msg.sender);
    }

    /// @notice 一次性添加门户信息
    /// @dev 一次性添加门户信息
    function addfullGater(
        LGate.Info memory _gator,
        LGate.DetailInfo memory _gatorDatailinfo
    ) external override {
        require(
            gateList[_gator.gateAddress].isUsed != true,
            "the gator is exister"
        );
        require(_gator.gateAddress == msg.sender, "the gator is your");

        _gator.marketunlock = false; //默认是被冻结状态
        _gator.gateunlock = false; //默认是被冻结状态
        _gator.gateNo = maxGateNumbers; //门户编号
        _gator.createtimestamp = block.timestamp; //创建时间
        _gator.isUsed = true; //创建时间
        require(maxGateNumbers + 1 > maxGateNumbers, "the gator is your");
        gateList[_gator.gateAddress] = _gator; //添加门户信息到门户列表
        gateNumbers[maxGateNumbers] = _gator.gateAddress;
        maxGateNumbers += 1;
        emit e_addGater(_gator.gateAddress, _gator.name);

        require(gateList[msg.sender].isUsed == true, "the gator is not exist");
        gateDetailList[msg.sender] = _gatorDatailinfo;
        emit e_addGaterDetail(msg.sender);
    }

    /// @notice 一次性更新门户信息
    /// @dev 一次性更新门户信息
    function updatefullGater(
        LGate.Info memory _gator,
        LGate.DetailInfo memory _gatorDatailinfo
    ) external override {
        require(
            gateList[_gator.gateAddress].isUsed == true,
            "the gator is not exist"
        );
        require(_gator.gateAddress == msg.sender, "the gator is your");
        gateList[msg.sender].name = _gator.name; //添加门户信息到门户列表
        emit e_updateGater(_gator.gateAddress, _gator.name);
        gateDetailList[msg.sender] = _gatorDatailinfo;
        emit e_updateGaterDetail(msg.sender);
    }

    /// @notice 判断调用者是否是市场已经认证门户
    /// @dev 判断调用者是否是市场已经认证门户
    function isValidGator() external view override returns (bool) {
        return gateList[msg.sender].marketunlock;
    }

    /// @notice 判断调用者是否是市场已经认证门户
    /// @dev 判断调用者是否是市场已经认证门户
    function isValidGator(
        address caller
    ) external view override returns (bool) {
        return gateList[caller].marketunlock;
    }

    /// @notice 调用者判断传入地址是否是市场已经认证门户
    /// @dev 调用者判断传入地址是否是市场已经认证门户
    function isValidGatorFromAddress(
        address vgaddress
    ) external view override returns (bool) {
        return gateList[vgaddress].marketunlock;
    }

    /// @notice 调用者判断传入地址是否是市场已经认证门户
    /// @dev 调用者判断传入地址是否是市场已经认证门户
    function isValidGatorWebFromAddress(
        address vgaddress,
        bytes32 webaddress
    ) external view override returns (bool) {
        require(
            webaddress == gateDetailList[vgaddress].OfficalIp,
            "address does not match the website"
        );
        return gateList[vgaddress].marketunlock;
    }

    /// @notice 获取门户调用者的门户编号
    /// @dev 获取门户调用者的门户编号
    function getGaterNo() external view override returns (uint128) {
        return gateList[msg.sender].gateNo;
    }

    /// @notice 调用者获取传入地址对应的门户编号
    /// @dev 调用者获取传入地址对应的门户编号
    function getGaterNoFromAddress(
        address _gateAddress
    ) external view override returns (uint128) {
        return gateList[_gateAddress].gateNo;
    }

    /// @notice 调用者获取门户编号对应的门户信息
    /// @dev 调用者获取门户编号对应的门户信息
    function getGaterInfo(
        uint8 _gateNumber
    ) external view override returns (LGate.Info memory) {
        return gateList[gateNumbers[_gateNumber]];
    }

    /// @notice 调用者获取门户地址对应的门户信息
    /// @dev 调用者获取门户地址对应的门户信息
    function getGaterInfo(
        address _gateaddress
    ) external view override returns (LGate.Info memory) {
        return gateList[_gateaddress];
    }

    /// @notice 通过门户地址获取门户详情
    /// @dev 通过门户地址获取门户详情
    function getGaterDetailInfo(
        address _gateaddress
    ) external view override returns (LGate.DetailInfo memory) {
        return gateDetailList[_gateaddress];
    }

    /// @notice 通过门户编号获取门户详情
    /// @dev 通过门户编号获取门户详情
    function getGaterDetailInfo(
        uint8 _gateNumber
    ) external view override returns (LGate.DetailInfo memory) {
        return gateDetailList[gateNumbers[_gateNumber]];
    }

    /// @notice 调用者获取市场最大门户编号、或者是下一个门户申请者的编号
    /// @dev 调用者获取市场最大门户编号、或者是下一个门户申请者的编号
    function getMaxGateNumber() external view override returns (uint128) {
        return maxGateNumbers;
    }
}
