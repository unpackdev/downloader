//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract DAOVerifier is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MAX_UINT128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    address public immutable STPT_ADDRESS;

    uint256[] private _verifiedDaoIds;
    // @dev 128 bits: index slot
    // @dev 128 bits: timestamp slot
    mapping(uint256 => uint256) _verifiedDaoIndexesAndTimestamp;

    uint256 public cumulativeStaked;
    uint256 public verificationThreshold;
    mapping(uint256 => uint256) public amountByDaoId;
    mapping(uint256 => mapping(address => uint256)) amountByDaoIdAndAccount;

    mapping(address => uint256[]) private _daoIdsByAccount;


    // @dev response model
    struct StakedDao {
        uint256 daoId;
        uint256 verifiedTimestamp;
        uint256 stakedAmount;
        uint256 stakedAmountTotal;
    }

    constructor(address stptAddress_) {
        STPT_ADDRESS = stptAddress_;
    }

    function initialize(uint256 verificationThreshold_) external initializer {
        verificationThreshold = verificationThreshold_;
        OwnableUpgradeable.__Ownable_init();
    }

    // @dev stake an amount of STPT for ${daoId}
    function stake(uint256 daoId_, uint256 amount_) external {
        uint256 _amountCurrentDao = amountByDaoId[daoId_];
        uint256 _amountCurrentAccount = amountByDaoIdAndAccount[daoId_][msg.sender];

        _amountCurrentDao += amount_;
        if (_amountCurrentDao >= verificationThreshold && _verifiedDaoIndexesAndTimestamp[daoId_] == 0) {
            _verifiedDaoIds.push(daoId_);
            _verifiedDaoIndexesAndTimestamp[daoId_] = (_verifiedDaoIds.length << 128) + block.timestamp;
        }

        cumulativeStaked += amount_;
        amountByDaoId[daoId_] = _amountCurrentDao;
        amountByDaoIdAndAccount[daoId_][msg.sender] = _amountCurrentAccount + amount_;
        if (_amountCurrentAccount == 0 && amount_ > 0) {
            _daoIdsByAccount[msg.sender].push(daoId_);
        }

        IERC20Upgradeable(STPT_ADDRESS).safeTransferFrom(msg.sender, address(this), amount_);
    }

    // @dev un stake
    function unstake(uint256 daoId_, uint256 amount_) external {
        uint256 _amountCurrentAccount = amountByDaoIdAndAccount[daoId_][msg.sender];
        require(_amountCurrentAccount >= amount_, 'DAOVerifier: amount should not exceed staked amount.');

        uint256 _indexAndTimestamp = _verifiedDaoIndexesAndTimestamp[daoId_];
        uint256 _amountCurrentDao = amountByDaoId[daoId_];
        _amountCurrentDao -= amount_;
        if (_amountCurrentDao < verificationThreshold && _indexAndTimestamp > 0) {
            _verifiedDaoIndexesAndTimestamp[daoId_] = 0;

            uint256 _index = (_indexAndTimestamp >> 128) - 1;
            uint256 _tailIndex = _verifiedDaoIds.length - 1;
            if (_index < _tailIndex) {
                uint256 _tailDaoId = _verifiedDaoIds[_tailIndex];
                _verifiedDaoIds[_index] = _tailDaoId;
                _verifiedDaoIndexesAndTimestamp[_tailDaoId] = ((_index + 1) << 128) + (_verifiedDaoIndexesAndTimestamp[_tailDaoId] & MAX_UINT128);
            }
            _verifiedDaoIds.pop();
        }

        cumulativeStaked -= amount_;
        amountByDaoId[daoId_] -= amount_;
        amountByDaoIdAndAccount[daoId_][msg.sender] = _amountCurrentAccount - amount_;
        if (_amountCurrentAccount == amount_) {
            uint256[] memory _stakedDaoIds = _daoIdsByAccount[msg.sender];
            uint256 _stakedDaoLength = _stakedDaoIds.length;
            for (uint256 _index = 0; _index < _stakedDaoLength; _index++) {
                if (daoId_ == _stakedDaoIds[_index]) {
                    if (_index < _stakedDaoLength - 1) {
                        _daoIdsByAccount[msg.sender][_index] = _stakedDaoIds[_stakedDaoLength - 1];
                    }
                    _daoIdsByAccount[msg.sender].pop();
                    break;
                }
            }
        }

        IERC20Upgradeable(STPT_ADDRESS).safeTransfer(msg.sender, amount_);
    }


    /** ---------- public getting ---------- **/
    function getVerifiedDao(address account_) view public returns (StakedDao[] memory) {
        uint256 _daoLength = _verifiedDaoIds.length;
        StakedDao[] memory _result = new StakedDao[](_daoLength);

        for (uint256 _index = 0; _index < _daoLength; _index++) {
            uint256 _daoId = _verifiedDaoIds[_index];
            _result[_index] = StakedDao({
                daoId: _daoId,
                verifiedTimestamp: _verifiedDaoIndexesAndTimestamp[_daoId] & MAX_UINT128,
                stakedAmount: amountByDaoIdAndAccount[_daoId][account_],
                stakedAmountTotal: amountByDaoId[_daoId]
            });
        }

        return _result;
    }

    function getVerifiedDaoByIds(uint256[] calldata daoIds_, address account_) view public returns (StakedDao[] memory) {
        uint256 _daoLength = daoIds_.length;
        StakedDao[] memory _result = new StakedDao[](_daoLength);

        for (uint256 _index = 0; _index < _daoLength; _index++) {
            uint256 _daoId = daoIds_[_index];
            _result[_index] = StakedDao({
                daoId: _daoId,
                verifiedTimestamp: _verifiedDaoIndexesAndTimestamp[_daoId] & MAX_UINT128,
                stakedAmount: amountByDaoIdAndAccount[_daoId][account_],
                stakedAmountTotal: amountByDaoId[_daoId]
            });
        }

        return _result;
    }

    function getMyStakedDao(address account_) view public returns (StakedDao[] memory) {
        uint256[] memory _daoIds = _daoIdsByAccount[account_];
        uint256 _daoLength = _daoIds.length;
        StakedDao[] memory _result = new StakedDao[](_daoLength);

        for (uint256 _index = 0; _index < _daoLength; _index++) {
            uint256 _daoId = _daoIds[_index];
            _result[_index] = StakedDao({
                daoId: _daoId,
                verifiedTimestamp: _verifiedDaoIndexesAndTimestamp[_daoId] & MAX_UINT128,
                stakedAmount: amountByDaoIdAndAccount[_daoId][account_],
                stakedAmountTotal: amountByDaoId[_daoId]
            });
        }

        return _result;
    }

}
