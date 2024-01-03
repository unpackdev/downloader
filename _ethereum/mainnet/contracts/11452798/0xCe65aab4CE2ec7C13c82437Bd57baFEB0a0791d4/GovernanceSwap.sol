// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./IGovernanceSwap.sol";
import "./IDexHandler.sol";
import "./IDefaultHandler.sol";

import "./Governable.sol";
import "./CollectableDust.sol";

/*
 * GovernanceSwap 
 */

contract GovernanceSwap is Governable, CollectableDust, IGovernanceSwap {
    using SafeMath for uint256;

    address public defaultHandler;
    // Dex handlers mapping
    mapping(address => address) internal dexHandlers;

    // in => out defaults
    mapping(address => mapping(address => address)) internal defaultPairDex;
    mapping(address => mapping(address => bytes)) internal defaultPairData;

    constructor() public Governable(msg.sender) CollectableDust() {
    }

    function isGovernanceSwap() external pure override returns (bool) {
        return true;
    }

    /*
        Governance Functions:

        - setDefaultHandler(_defaultHandler)
        - addDexHandler(_dex, _handler)
        - removeDexHandler(_dex, _handler)
        - setPairDefaults(_in, _out, _dex, _data)

     */


    function setDefaultHandler(address _defaultHandler) external override onlyGovernor {
        require(_defaultHandler != address(0), 'governance-swap::set-default-handler:handler-cannot-be-0');
        require(IDexHandler(_defaultHandler).isDexHandler(), 'governance-swap::set-default-handler:contract-is-not-handler');
        defaultHandler = _defaultHandler;
    }

    function addDexHandler(address _dex, address _handler) external override onlyGovernor {
        require(dexHandlers[_dex] == address(0), 'governance-swap::add-dex:dex-already-exists');
        require(IDexHandler(_handler).isDexHandler(), 'governance-swap::add-dex:contract-is-not-handler');
        dexHandlers[_dex] = _handler;
    }

    function removeDexHandler(address _dex) external override onlyGovernor {
        require(dexHandlers[_dex] != address(0), 'governance-swap::add-dex:dex-does-not-exists');
        dexHandlers[_dex] = address(0);
    }

    function setPairDefaults(address _in, address _out, address _dex, bytes memory _data) public override onlyGovernor {
        require(dexHandlers[_dex] != address(0), 'governance-swap::set-pair-defaults:dex-does-not-have-handler');
        require(_in != _out, 'governance-swap::set-pair-defaults:in-equals-out');
        defaultPairDex[_in][_out] = _dex;
        defaultPairData[_in][_out] = _data;
    }



    /*
        Getter Functions:

        - getPairDefaultDex(_in, _out, _strict) returns (address _dex)
        - getPairDefaultDexHandler(_in, _out, _strict) returns (address _handler)
        - getDexHandler(_dex, _strict) returns (address _handler)
        - getPairDefaultData(_in, _out, _strict) returns (bytes memory _data)
            
        -     

     */
  
    function getPairDefaultDex(address _in, address _out, bool _strict) public view override returns (address _dex) {
        if (_strict) return defaultPairDex[_in][_out];
        return defaultPairDex[_in][_out] != address(0) ?
            defaultPairDex[_in][_out] :
            IDefaultHandler(defaultHandler).getPairDefaultDex(_in, _out);
    }
    function getPairDefaultDexHandler(address _in, address _out, bool _strict) public view override returns (address _handler) {
        if (_strict) return dexHandlers[defaultPairDex[_in][_out]];
        return dexHandlers[defaultPairDex[_in][_out]] != address(0) ?
            dexHandlers[defaultPairDex[_in][_out]] :
            defaultHandler;
    }
    function getDexHandler(address _dex, bool _strict) public view override returns (address _handler) {
        if (_strict) return dexHandlers[_dex];
        return dexHandlers[_dex] != address(0) ?
            dexHandlers[_dex] :
            defaultHandler;
    }
    function getPairDefaultData(address _in, address _out, bool _strict) public view override returns (bytes memory _data) {
        if (_strict) return defaultPairData[_in][_out];
        return defaultPairData[_in][_out].length > 0 ?
            defaultPairData[_in][_out] :
            IDefaultHandler(defaultHandler).getPairDefaultData(_in, _out);
    }


    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }

}
