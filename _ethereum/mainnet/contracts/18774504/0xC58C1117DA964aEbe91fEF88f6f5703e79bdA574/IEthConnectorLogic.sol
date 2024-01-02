// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./ScriptTypesEnum.sol";
import "./TeleOrdinalLib.sol";

interface IEthConnectorLogic {

    // Events

    event MsgSent(
        string functionName,
        bytes data 
    );

    function setPolyConnector(address _polyConnector) external; 

    function setAcross(address _across) external; 

    function setMinAmount(address _token, uint _minAmount) external;

    function setMinModifier(uint _minModifier) external;

    function putBidAcross(
        TeleOrdinalLib.Loc calldata _loc,
        bytes memory _buyerBTCScript,
        ScriptTypes _scriptType,
        uint _amount,
        address _token,
        int64 _relayerFeePercentage
    ) external payable;

    function increaseBidAcross(
        TeleOrdinalLib.Loc calldata _loc,
        uint _bidIdx,
        uint _addedAmount,
        address _token,
        int64 _relayerFeePercentage
    ) external payable;

    function withdrawToken(
        address _token,
        address _to,
        uint _amount
    ) external;

}