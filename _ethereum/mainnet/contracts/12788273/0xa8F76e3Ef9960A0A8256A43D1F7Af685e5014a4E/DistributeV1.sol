// SPDX-License-Identifier: GPL-3.0-or-later
// KPR Liquidity Mining
// Copyright (C) 2020 Talo Research Pte. Ltd.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.9;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./CanReclaimTokens.sol";

contract DistributeV1 is CanReclaimTokens {
    using SafeMath for uint256;

    address accountManager;
    IERC20 kprToken;
    mapping (address => uint256) public lastUsedNonce;
    mapping(address => uint256) public claimedAmount;

    event Claimed(address indexed _redeemer, uint256 _amount);
    event AccountManagerChanged(address indexed _oldAccountManager, address indexed _newAccountManager);

    constructor(IERC20 _kprToken, address _accountManager) public {
        kprToken = _kprToken;
        accountManager = _accountManager;
        blacklistRecoverableToken(address(_kprToken));
    }

    /// @notice update the AccountManager address, this keypair is responsible to sign the user claims.
    function updateAccountManager(address _newAccountManager) external onlyOwner {
        emit AccountManagerChanged(accountManager, _newAccountManager);
        accountManager = _newAccountManager;
    }

    /// @notice calculate the hash that will be signed from the data.
    function hashForSignature(address _owner, uint256 _earningsToDate, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encode(_owner, _earningsToDate, _nonce));
    }

    /// @notice Claim accumulated earnings.
    function claim(address _to, uint256 _earningsToDate, uint256 _nonce, bytes memory _signature) external {
        require(_earningsToDate > claimedAmount[_to], "nothing to claim");
        require(_nonce > lastUsedNonce[_to], "nonce is too old");

        address signer = ECDSA.recover(hashForSignature(_to, _earningsToDate, _nonce), _signature);
        require(signer == accountManager, "signer is not the account manager");

        lastUsedNonce[_to] = _nonce;
        uint256 claimableAmount = _earningsToDate.sub(claimedAmount[_to]);
        claimedAmount[_to] = _earningsToDate;

        kprToken.transfer(_to, claimableAmount);
        emit Claimed(_to, claimableAmount);
    }
}

contract KeeperDistributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract LPDistributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract LPPreDistributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract LPQ2Distributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract HidingGameDistributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract LPQ3Distributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract HidingGame2Distributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract HidingGame3Distributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract HidingGame4Distributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}

contract CompoundLenderDistributor is DistributeV1 {
    constructor(IERC20 _kprToken, address _accountManager) public DistributeV1(_kprToken, _accountManager) { }
}