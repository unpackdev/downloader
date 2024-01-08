/*
    Copyright 2021 Memento Blockchain Pte. Ltd. 

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ISetToken.sol";
import "./ISetToken.sol";
import "./ICore.sol";
import "./BasicIssuanceModule.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract DextfV2Migration is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    /* ============ Events ============ */
    event FundMigrated(
        address indexed _fundV1,
        address indexed _fundV2,
        address _to,
        uint256 _value
    );

    event Transferred(
        address indexed _token,
        address indexed _to,
        uint256 _value
    );

    /* ============ State Variables ============ */

    ICore public coreV1;
    BasicIssuanceModule public basicIssuanceModuleV2;
    uint256 constant feeMultiplier = 999900000000000000; // 99.99% in base 1e18
    uint256 constant percentageMultiplier = 1e18; // 100.0% in base 1e18

    /* ============ Constructor ============ */

    /**
     * Initializes the migration contract
     *
     * @param _coreV1                       Address of v1 core contract
     * @param _basicIssuanceModuleV2        Address of v2 basic issuance module
     */
    constructor(ICore _coreV1, BasicIssuanceModule _basicIssuanceModuleV2)
        public
    {
        coreV1 = _coreV1;
        basicIssuanceModuleV2 = _basicIssuanceModuleV2;
    }

    /* ============ External Functions ============ */

    /**
     * Migrate token fund from v1 to v2
     * Before calling the function, make sure the _fundV1 and _fundV2 has the same amount of component
     * Otherwise left over can remains in this contract
     */
    function migrateFund(
        address _fundV1,
        ISetTokenV2 _fundV2,
        address _to,
        uint256 _value
    ) external nonReentrant {

        uint256 value2 = _value.mul(feeMultiplier).div(percentageMultiplier);
        require(value2>0, "Fund quantity too small");

        // Approval is required
        // We first transfer the fund token to the migration contract and redeem to the contract address
        IERC20(_fundV1).transferFrom(_msgSender(), address(this), _value);
        
        coreV1.redeemAndWithdrawTo(_fundV1, address(this), _value, 0);

        // For each of the component of the new fund contract, we approve the componentQuantities
        (address[] memory components, uint256[] memory componentQuantities) =
            basicIssuanceModuleV2.getRequiredComponentUnitsForIssue(
                _fundV2,
                value2
            );

        for (uint256 i = 0; i < components.length; i++) {
            SafeERC20.safeApprove(
                IERC20(components[i]),
                address(basicIssuanceModuleV2),
                componentQuantities[i]
            );
        }

        // Issue the fund back to the user
        basicIssuanceModuleV2.issue(_fundV2, value2, _to);

        emit FundMigrated(_fundV1, address(_fundV2), _to, value2);
    }

    /**
     * Send tokens owned by the contract to an address.
     * Only owner can perform this operation.
     */
    function transfer(
        IERC20 token,
        address _to,
        uint256 _value
    ) external nonReentrant onlyOwner {
        token.transfer(_to, _value);
        emit Transferred(address(token), _to, _value);
    }

    /**
     * returns the number of that tokens held by the smart contract
     */
    function tokensHeld(address _fund)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory components = ISetTokenV1(_fund).getComponents();
        uint256[] memory values = new uint256[](components.length);
        for (uint256 index = 0; index < components.length; index++) {
            values[index] = IERC20(_fund).balanceOf(address(this));
        }
        return (components, values);
    }

    /**
     * returns the number of that tokens held by the smart contract
     */
    function tokenHeld(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
}
