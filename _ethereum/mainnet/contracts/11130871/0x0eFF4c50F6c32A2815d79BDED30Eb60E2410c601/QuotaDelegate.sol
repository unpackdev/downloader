// File: contracts/components/Owned.sol

/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//

pragma solidity ^0.4.24;

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    constructor() public {
        owner = msg.sender;
    }

    address public newOwner;

    function transferOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}

// File: contracts/components/Halt.sol

/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//

pragma solidity ^0.4.24;


contract Halt is Owned {

    bool public halted = false;

    modifier notHalted() {
        require(!halted, "Smart contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted, "Smart contract is not halted");
        _;
    }

    /// @notice function Emergency situation that requires
    /// @notice contribution period to stop or not.
    function setHalt(bool halt)
        public
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts/lib/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath div 0"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub b > a");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath add overflow");

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath mod 0");
        return a % b;
    }
}

// File: contracts/lib/BasicStorageLib.sol

pragma solidity ^0.4.24;

library BasicStorageLib {

    struct UintData {
        mapping(bytes => mapping(bytes => uint))           _storage;
    }

    struct BoolData {
        mapping(bytes => mapping(bytes => bool))           _storage;
    }

    struct AddressData {
        mapping(bytes => mapping(bytes => address))        _storage;
    }

    struct BytesData {
        mapping(bytes => mapping(bytes => bytes))          _storage;
    }

    struct StringData {
        mapping(bytes => mapping(bytes => string))         _storage;
    }

    /* uintStorage */

    function setStorage(UintData storage self, bytes memory key, bytes memory innerKey, uint value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(UintData storage self, bytes memory key, bytes memory innerKey) internal view returns (uint) {
        return self._storage[key][innerKey];
    }

    function delStorage(UintData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* boolStorage */

    function setStorage(BoolData storage self, bytes memory key, bytes memory innerKey, bool value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(BoolData storage self, bytes memory key, bytes memory innerKey) internal view returns (bool) {
        return self._storage[key][innerKey];
    }

    function delStorage(BoolData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* addressStorage */

    function setStorage(AddressData storage self, bytes memory key, bytes memory innerKey, address value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(AddressData storage self, bytes memory key, bytes memory innerKey) internal view returns (address) {
        return self._storage[key][innerKey];
    }

    function delStorage(AddressData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* bytesStorage */

    function setStorage(BytesData storage self, bytes memory key, bytes memory innerKey, bytes memory value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(BytesData storage self, bytes memory key, bytes memory innerKey) internal view returns (bytes memory) {
        return self._storage[key][innerKey];
    }

    function delStorage(BytesData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* stringStorage */

    function setStorage(StringData storage self, bytes memory key, bytes memory innerKey, string memory value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(StringData storage self, bytes memory key, bytes memory innerKey) internal view returns (string memory) {
        return self._storage[key][innerKey];
    }

    function delStorage(StringData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

}

// File: contracts/components/BasicStorage.sol

pragma solidity ^0.4.24;


contract BasicStorage {
    /************************************************************
     **
     ** VARIABLES
     **
     ************************************************************/

    //// basic variables
    using BasicStorageLib for BasicStorageLib.UintData;
    using BasicStorageLib for BasicStorageLib.BoolData;
    using BasicStorageLib for BasicStorageLib.AddressData;
    using BasicStorageLib for BasicStorageLib.BytesData;
    using BasicStorageLib for BasicStorageLib.StringData;

    BasicStorageLib.UintData    internal uintData;
    BasicStorageLib.BoolData    internal boolData;
    BasicStorageLib.AddressData internal addressData;
    BasicStorageLib.BytesData   internal bytesData;
    BasicStorageLib.StringData  internal stringData;
}

// File: contracts/quota/QuotaStorage.sol

/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//

pragma solidity 0.4.26;



contract QuotaStorage is BasicStorage {
    
    /// @dev Math operations with safety checks
    using SafeMath for uint;

    struct Quota {
        /// amount of original token to be received, equals to amount of WAN token to be minted
        uint debt_receivable;
        /// amount of WAN token to be burnt
        uint debt_payable;
        /// amount of original token has been exchanged to the wanchain
        uint _debt;
        /// amount of original token to be received, equals to amount of WAN token to be minted
        uint asset_receivable;
        /// amount of WAN token to be burnt
        uint asset_payable;
        /// amount of original token has been exchanged to the wanchain
        uint _asset;
        /// data is active
        bool _active;
    }

    /// @dev the denominator of deposit rate value
    uint public constant DENOMINATOR = 10000;

    /// @dev mapping: tokenId => storemanPk => Quota
    mapping(uint => mapping(bytes32 => Quota)) quotaMap;

    /// @dev mapping: storemanPk => tokenIndex => tokenId, tokenIndex:0,1,2,3...
    mapping(bytes32 => mapping(uint => uint)) storemanTokensMap;

    /// @dev mapping: storemanPk => token count
    mapping(bytes32 => uint) storemanTokenCountMap;

    /// @dev mapping: htlcAddress => exist
    mapping(address => bool) public htlcGroupMap;

    /// @dev save deposit oracle address (storeman admin or oracle)
    address public depositOracleAddress;

    /// @dev save price oracle address
    address public priceOracleAddress;

    /// @dev deposit rate use for deposit amount calculate
    uint public depositRate;

    /// @dev deposit token's symbol
    string public depositTokenSymbol;

    /// @dev token manger contract address
    address public tokenManagerAddress;

    /// @dev oracle address for check other chain's debt clean
    address public debtOracleAddress;

    /// @dev limit the minimize value of fast cross chain
    uint public fastCrossMinValue;

    modifier onlyHtlc() {
        require(htlcGroupMap[msg.sender], "Not in HTLC group");
        _;
    }
}

// File: contracts/interfaces/IOracle.sol

pragma solidity 0.4.26;

interface IOracle {
  function getDeposit(bytes32 smgID) external view returns (uint);
  function getValue(bytes32 key) external view returns (uint);
  function getValues(bytes32[] keys) external view returns (uint[] values);
  function getStoremanGroupConfig(
    bytes32 id
  ) external view returns(bytes32 groupId, uint8 status, uint deposit, uint chain1, uint chain2, uint curve1, uint curve2, bytes gpk1, bytes gpk2, uint startTime, uint endTime);
}

// File: contracts/quota/QuotaDelegate.sol

/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//

pragma solidity 0.4.26;

/**
 * Math operations with safety checks
 */




interface _ITokenManager {
    function getAncestorSymbol(uint id) external view returns (string symbol, uint8 decimals);
}

interface _IStoremanGroup {
    function getDeposit(bytes32 id) external view returns(uint deposit);
}

interface IDebtOracle {
    function isDebtClean(bytes32 storemanGroupId) external view returns (bool);
}


contract QuotaDelegate is QuotaStorage, Halt {

    modifier checkMinValue(uint tokenId, uint value) {
        if (fastCrossMinValue > 0) {
            string memory symbol;
            uint decimals;
            (symbol, decimals) = getTokenAncestorInfo(tokenId);
            uint price = getPrice(symbol);
            require(price > 0, "Price is zero");
            uint count = fastCrossMinValue.mul(10**decimals).div(price);
            require(value >= count, "value too small");
        }
        _;
    }
    
    /// @notice                         config params for owner
    /// @param _priceOracleAddr         token price oracle contract address
    /// @param _htlcAddr                HTLC contract address
    /// @param _depositOracleAddr       deposit oracle address, storemanAdmin or oracle
    /// @param _depositRate             deposit rate value, 15000 means 150%
    /// @param _depositTokenSymbol      deposit token symbol, default is WAN
    /// @param _tokenManagerAddress     token manager contract address
    function config(
        address _priceOracleAddr,
        address _htlcAddr,
        address _fastHtlcAddr,
        address _depositOracleAddr,
        address _tokenManagerAddress,
        uint _depositRate,
        string _depositTokenSymbol
    ) external onlyOwner {
        priceOracleAddress = _priceOracleAddr;
        htlcGroupMap[_htlcAddr] = true;
        htlcGroupMap[_fastHtlcAddr] = true;
        depositOracleAddress = _depositOracleAddr;
        depositRate = _depositRate;
        depositTokenSymbol = _depositTokenSymbol;
        tokenManagerAddress = _tokenManagerAddress;
    }

    function setDebtOracle(address oracle) external onlyOwner {
        debtOracleAddress = oracle;
    }

    function setFastCrossMinValue(uint value) external onlyOwner {
        fastCrossMinValue = value;
    }

    /// @notice                                 lock quota in mint direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userMintLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        
        uint mintQuota = getUserMintQuota(tokenId, storemanGroupId);
        require(
            mintQuota >= value,
            "Quota is not enough"
        );

        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }

        quota.asset_receivable = quota.asset_receivable.add(value);
    }

    /// @notice                                 lock quota in mint direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgMintLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        
        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }

        quota.debt_receivable = quota.debt_receivable.add(value);
    }

    /// @notice                                 revoke quota in mint direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userMintRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_receivable = quota.asset_receivable.sub(value);
    }

    /// @notice                                 revoke quota in mint direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgMintRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.debt_receivable = quota.debt_receivable.sub(value);
    }

    /// @notice                                 redeem quota in mint direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userMintRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.debt_receivable = quota.debt_receivable.sub(value);
        quota._debt = quota._debt.add(value);
    }

    /// @notice                                 redeem quota in mint direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgMintRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_receivable = quota.asset_receivable.sub(value);
        quota._asset = quota._asset.add(value);
    }

    /// @notice                                 perform a fast crosschain mint
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userFastMint(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc checkMinValue(tokenId, value) {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        
        uint mintQuota = getUserMintQuota(tokenId, storemanGroupId);
        require(
            mintQuota >= value,
            "Quota is not enough"
        );

        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }
        quota._asset = quota._asset.add(value);
    }

    /// @notice                                 perform a fast crosschain mint
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgFastMint(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        
        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }
        quota._debt = quota._debt.add(value);
    }

    /// @notice                                 perform a fast crosschain burn
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userFastBurn(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc checkMinValue(tokenId, value) {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        require(quota._debt.sub(quota.debt_payable) >= value, "Value is invalid");
        quota._debt = quota._debt.sub(value);
    }

    /// @notice                                 perform a fast crosschain burn
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgFastBurn(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota._asset = quota._asset.sub(value);
    }

    /// @notice                                 lock quota in burn direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userBurnLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        require(quota._debt.sub(quota.debt_payable) >= value, "Value is invalid");
        quota.debt_payable = quota.debt_payable.add(value);
    }

    /// @notice                                 lock quota in burn direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgBurnLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_payable = quota.asset_payable.add(value);
    }

    /// @notice                                 revoke quota in burn direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userBurnRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.debt_payable = quota.debt_payable.sub(value);
    }

    /// @notice                                 revoke quota in burn direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgBurnRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_payable = quota.asset_payable.sub(value);
    }

    /// @notice                                 redeem quota in burn direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function userBurnRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota._asset = quota._asset.sub(value);
        quota.asset_payable = quota.asset_payable.sub(value);
    }

    /// @notice                                 redeem quota in burn direction
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    /// @param value                            amount of exchange token
    function smgBurnRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota._debt = quota._debt.sub(value);
        quota.debt_payable = quota.debt_payable.sub(value);
    }

    /// @notice                                 source storeman group lock the debt transaction,update the detailed quota info. of the storeman group
    /// @param srcStoremanGroupId               PK of source storeman group
    /// @param dstStoremanGroupId               PK of destination storeman group
    function debtLock(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        // TODO gas out of range
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];

            require( src.debt_receivable == uint(0) && src.debt_payable == uint(0),
                "There are debt_receivable or debt_payable in src storeman"
            );

            if (src._debt == 0) {
                continue;
            }

            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            if (!dst._active) {
                dst._active = true;
                storemanTokensMap[dstStoremanGroupId][storemanTokenCountMap[dstStoremanGroupId]] = id;
                storemanTokenCountMap[dstStoremanGroupId] = storemanTokenCountMap[dstStoremanGroupId]
                    .add(1);
            }

            dst.debt_receivable = dst.debt_receivable.add(src._debt);
            src.debt_payable = src.debt_payable.add(src._debt);
        }
    }

    /// @notice                                 destination storeman group redeem the debt transaction,update the detailed quota info. of the storeman group
    /// @param srcStoremanGroupId               PK of source storeman group
    /// @param dstStoremanGroupId               PK of destination storeman group
    function debtRedeem(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._debt == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            /// Adjust quota record
            dst.debt_receivable = dst.debt_receivable.sub(src.debt_payable);
            dst._debt = dst._debt.add(src._debt);

            src.debt_payable = 0;
            src._debt = 0;
        }
    }

    /// @notice                                 source storeman group revoke the debt transaction,update the detailed quota info. of the storeman group
    /// @param srcStoremanGroupId               PK of source storeman group
    /// @param dstStoremanGroupId               PK of destination storeman group
    function debtRevoke(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._debt == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            
            dst.debt_receivable = dst.debt_receivable.sub(src.debt_payable);
            src.debt_payable = 0;
        }
    }

    /// @notice                                 source storeman group lock the debt transaction,update the detailed quota info. of the storeman group
    /// @param srcStoremanGroupId               PK of source storeman group
    /// @param dstStoremanGroupId               PK of destination storeman group
    function assetLock(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];

            require( src.asset_receivable == uint(0) && src.asset_payable == uint(0),
                "There are asset_receivable or asset_payable in src storeman"
            );

            if (src._asset == 0) {
                continue;
            }

            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            if (!dst._active) {
                dst._active = true;
                storemanTokensMap[dstStoremanGroupId][storemanTokenCountMap[dstStoremanGroupId]] = id;
                storemanTokenCountMap[dstStoremanGroupId] = storemanTokenCountMap[dstStoremanGroupId]
                    .add(1);
            }

            dst.asset_receivable = dst.asset_receivable.add(src._asset);
            src.asset_payable = src.asset_payable.add(src._asset);
        }
    }

    /// @notice                                 destination storeman group redeem the debt transaction,update the detailed quota info. of the storeman group
    /// @param srcStoremanGroupId               PK of source storeman group
    /// @param dstStoremanGroupId               PK of destination storeman group
    function assetRedeem(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._asset == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            /// Adjust quota record
            dst.asset_receivable = dst.asset_receivable.sub(src.asset_payable);
            dst._asset = dst._asset.add(src._asset);

            src.asset_payable = 0;
            src._asset = 0;
        }
    }

    /// @notice                                 source storeman group revoke the debt transaction,update the detailed quota info. of the storeman group
    /// @param srcStoremanGroupId               PK of source storeman group
    /// @param dstStoremanGroupId               PK of destination storeman group
    function assetRevoke(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._asset == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            
            dst.asset_receivable = dst.asset_receivable.sub(src.asset_payable);
            src.asset_payable = 0;
        }
    }

    /// @notice                                 get user mint quota of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getUserMintQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint)
    {
        string memory symbol;
        uint decimals;
        uint tokenPrice;

        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        tokenPrice = getPrice(symbol);
        if (tokenPrice == 0) {
            return 0;
        }

        uint fiatQuota = getUserFiatMintQuota(storemanGroupId, symbol);

        return fiatQuota.div(tokenPrice).mul(10**decimals).div(1 ether);
    }

    /// @notice                                 get smg mint quota of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getSmgMintQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint)
    {
        string memory symbol;
        uint decimals;
        uint tokenPrice;

        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        tokenPrice = getPrice(symbol);
        if (tokenPrice == 0) {
            return 0;
        }

        uint fiatQuota = getSmgFiatMintQuota(storemanGroupId, symbol);

        return fiatQuota.div(tokenPrice).mul(10**decimals).div(1 ether);
    }

    /// @notice                                 get user burn quota of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getUserBurnQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint burnQuota)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        burnQuota = quota._debt.sub(quota.debt_payable);
    }

    /// @notice                                 get smg burn quota of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getSmgBurnQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint burnQuota)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        burnQuota = quota._asset.sub(quota.asset_payable);
    }

    /// @notice                                 get asset of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getAsset(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint asset, uint asset_receivable, uint asset_payable)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        return (quota._asset, quota.asset_receivable, quota.asset_payable);
    }

    /// @notice                                 get debt of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getDebt(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint debt, uint debt_receivable, uint debt_payable)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        return (quota._debt, quota.debt_receivable, quota.debt_payable);
    }

    /// @notice                                 get debt clean state of storeman
    /// @param storemanGroupId                  PK of source storeman group
    function isDebtClean(bytes32 storemanGroupId) external view returns (bool) {
        uint tokenCount = storemanTokenCountMap[storemanGroupId];
        if (tokenCount == 0) {
            if (debtOracleAddress == address(0)) {
                return true;
            } else {
                IDebtOracle debtOracle = IDebtOracle(debtOracleAddress);
                return debtOracle.isDebtClean(storemanGroupId);
            }
        }

        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[storemanGroupId][i];
            Quota storage src = quotaMap[id][storemanGroupId];
            if (src._debt > 0 || src.debt_payable > 0 || src.debt_receivable > 0) {
                return false;
            }

            if (src._asset > 0 || src.asset_payable > 0 || src.asset_receivable > 0) {
                return false;
            }
        }
        return true;
    }

    /// @dev get minimize token count for fast cross chain
    function getFastMinCount(uint tokenId) public view returns (uint, string, uint, uint, uint) {
        if (fastCrossMinValue == 0) {
            return (0, "", 0, 0, 0);
        }
        string memory symbol;
        uint decimals;
        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        uint price = getPrice(symbol);
        uint count = fastCrossMinValue.mul(10**decimals).div(price);
        return (fastCrossMinValue, symbol, decimals, price, count);
    }

    // ----------- Private Functions ---------------



    /// @notice                                 get storeman group's deposit value in USD
    /// @param storemanGroupId                  storeman group ID
    function getFiatDeposit(bytes32 storemanGroupId) private view returns (uint) {
        uint deposit = getDepositAmount(storemanGroupId);
        return deposit.mul(getPrice(depositTokenSymbol));
    }

    /// get mint quota in Fiat/USD decimals: 18
    function getUserFiatMintQuota(bytes32 storemanGroupId, string rawSymbol) private view returns (uint) {
        string memory symbol;
        uint decimals;

        uint totalTokenUsedValue = 0;
        for (uint i = 0; i < storemanTokenCountMap[storemanGroupId]; i++) {
            uint id = storemanTokensMap[storemanGroupId][i];
            (symbol, decimals) = getTokenAncestorInfo(id);
            Quota storage q = quotaMap[id][storemanGroupId];
            uint tokenValue = q.asset_receivable.add(q._asset).mul(getPrice(symbol)).mul(1 ether).div(10**decimals); /// change Decimals to 18 digits
            totalTokenUsedValue = totalTokenUsedValue.add(tokenValue);
        }
        
        return getLastDeposit(storemanGroupId, rawSymbol, totalTokenUsedValue);
    }

    function getLastDeposit(bytes32 storemanGroupId, string rawSymbol, uint totalTokenUsedValue) private view returns (uint depositValue) {
        // keccak256("WAN") = 0x28ba6d5ac5913a399cc20b18c5316ad1459ae671dd23558d05943d54c61d0997
        if (keccak256(rawSymbol) == bytes32(0x28ba6d5ac5913a399cc20b18c5316ad1459ae671dd23558d05943d54c61d0997)) {
            depositValue = getFiatDeposit(storemanGroupId);
        } else {
            depositValue = getFiatDeposit(storemanGroupId).mul(DENOMINATOR).div(depositRate); // 15000 = 150%
        }

        if (depositValue <= totalTokenUsedValue) {
            depositValue = 0;
        } else {
            depositValue = depositValue.sub(totalTokenUsedValue); /// decimals: 18
        }
    }

    /// get mint quota in Fiat/USD decimals: 18
    function getSmgFiatMintQuota(bytes32 storemanGroupId, string rawSymbol) private view returns (uint) {
        string memory symbol;
        uint decimals;

        uint totalTokenUsedValue = 0;
        for (uint i = 0; i < storemanTokenCountMap[storemanGroupId]; i++) {
            uint id = storemanTokensMap[storemanGroupId][i];
            (symbol, decimals) = getTokenAncestorInfo(id);
            Quota storage q = quotaMap[id][storemanGroupId];
            uint tokenValue = q.debt_receivable.add(q._debt).mul(getPrice(symbol)).mul(1 ether).div(10**decimals); /// change Decimals to 18 digits
            totalTokenUsedValue = totalTokenUsedValue.add(tokenValue);
        }

        uint depositValue = 0;
        if (keccak256(rawSymbol) == keccak256("WAN")) {
            depositValue = getFiatDeposit(storemanGroupId);
        } else {
            depositValue = getFiatDeposit(storemanGroupId).mul(DENOMINATOR).div(depositRate); // 15000 = 150%
        }

        if (depositValue <= totalTokenUsedValue) {
            return 0;
        }

        return depositValue.sub(totalTokenUsedValue); /// decimals: 18
    }

    function getDepositAmount(bytes32 storemanGroupId)
        private
        view
        returns (uint)
    {
        _IStoremanGroup smgAdmin = _IStoremanGroup(depositOracleAddress);
        return smgAdmin.getDeposit(storemanGroupId);
    }

    function getTokenAncestorInfo(uint tokenId)
        private
        view
        returns (string ancestorSymbol, uint decimals)
    {
        _ITokenManager tokenManager = _ITokenManager(tokenManagerAddress);
        (ancestorSymbol,decimals) = tokenManager.getAncestorSymbol(tokenId);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getPrice(string symbol) private view returns (uint price) {
        IOracle oracle = IOracle(priceOracleAddress);
        price = oracle.getValue(stringToBytes32(symbol));
    }
}