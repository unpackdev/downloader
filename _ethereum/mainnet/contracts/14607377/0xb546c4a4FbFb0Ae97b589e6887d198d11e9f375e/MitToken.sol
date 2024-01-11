// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol" ;
import "@openzeppelin/contracts/utils/math/SafeMath.sol" ;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol" ;
contract MitToken is ERC20PresetMinterPauser {
    mapping(address => bool) public waivedAddr ;
    address public feeAddr ;
    uint256 public feeRate = 30;

    //////////////////////////////////////////////
    //              events
    //////////////////////////////////////////////
    event AddWaiveAddrEvent(address waiveAddr) ;
    event DelWaiveAddrEvent(address waiveAddr) ;
    event SetFeeAddrEvent(address oldFeeAddr, address newFeeAddr) ;
    event SetFeeRateEvent(uint256 oldFeeRate, uint256 newFeeRate) ;

    constructor(uint256 initialSupply, address _feeAddr) ERC20PresetMinterPauser("Meta Interstellar Token", "MIT"){
        // start init mint owner
        _mint(_msgSender(), formatDecimals(initialSupply)) ;

        // init fee
        feeAddr = _feeAddr ;
        waivedAddr[feeAddr] = true ;
        waivedAddr[_msgSender()] = true ;
        waivedAddr[address(this)] = true ;
    }

    function addWaiveAddr(address _waiveAddr) external returns(bool) {
        return _addWaiveAddr(_waiveAddr) ;
    }

    function batchAddWaiveAddr(address[] memory waiveAddrs) external returns(bool) {
        for(uint256 i = 0;i < waiveAddrs.length; i++){
            _addWaiveAddr(waiveAddrs[i]) ;
        }
        return true ;
    }

    function _addWaiveAddr(address _waiveAddr) private onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        waivedAddr[_waiveAddr] = true ;
        emit AddWaiveAddrEvent(_waiveAddr);
        return true ;
    }

    function delWaiveAddr(address _waiveAddr) external returns(bool) {
        return _delWaiveAddr(_waiveAddr) ;
    }

    function batchDelWaiveAddr(address[] memory waiveAddrs) external returns(bool) {
        for(uint256 i = 0;i < waiveAddrs.length; i++){
            _delWaiveAddr(waiveAddrs[i]) ;
        }
        return true ;
    }

    function _delWaiveAddr(address _waiveAddr) private onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        waivedAddr[_waiveAddr] = false ;
        emit DelWaiveAddrEvent(_waiveAddr);
        return true ;
    }

    // update feeAddr
    function setFeeAddr(address _feeAddr) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        address old = feeAddr ;
        feeAddr = _feeAddr ;
        emit SetFeeAddrEvent(old, feeAddr) ;
        return true ;
    }

    // update feeRate
    function setFeeRate(uint256 _feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
        require(_feeRate >= 0 && _feeRate < 50, "MitToken : The commission must be between [0%, 50%)!");
        uint256 old = feeRate ;
        feeRate = _feeRate ;
        emit SetFeeRateEvent(old, feeRate) ;
        return true ;
    }

    // cal amount by base
    function formatDecimals(uint256 _value) internal view returns (uint256) {
        return _value * 10 ** uint256(decimals());
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(ERC20) {

        uint256 feeAmount = 0;
        if(waivedAddr[sender] == false && waivedAddr[recipient] == false && feeAddr != address(0) && feeRate > 0) {
            // cal fee
            (bool ok, uint256 result) = SafeMath.tryMul(amount, feeRate) ;
            require(ok, "ERC20: transfer excessive amount of transfer!") ;
            feeAmount = SafeMath.div(result, uint256(100)) ;
            // transfer fee
            if(feeAmount > 0){
               super._transfer(sender, feeAddr, feeAmount) ;
            }
        }

        // transfer other
        super._transfer(sender, recipient, amount - feeAmount) ;
    }
}
