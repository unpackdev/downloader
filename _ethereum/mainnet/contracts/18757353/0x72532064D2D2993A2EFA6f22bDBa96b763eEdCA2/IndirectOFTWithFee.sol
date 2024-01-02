// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseOFTWithFeeL3USD.sol";
import "./SafeERC20.sol";
import "./IElevatedMinterBurner.sol";

contract IndirectOFTWithFee is BaseOFTWithFeeL3USD {
    using SafeERC20 for IERC20;
    IElevatedMinterBurner public immutable minterBurner;
    mapping(address => mapping(uint => uint)) public bridgeFromHistory;
    mapping(address => uint) public bridgeFromCounters;
    IERC20 internal immutable innerToken;
    uint internal immutable ld2sdRate;

    constructor(address _token, IElevatedMinterBurner _minterBurner, uint8 _sharedDecimals, address _lzEndpoint) BaseOFTWithFeeL3USD(_sharedDecimals, _lzEndpoint) {
        innerToken = IERC20(_token);
        minterBurner = _minterBurner;

        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "IndirectOFTWithFee: failed to get token decimals");
        uint8 decimals = abi.decode(data, (uint8));

        require(_sharedDecimals <= decimals, "IndirectOFTWithFee: sharedDecimals must be <= decimals");
        ld2sdRate = 10**(decimals - _sharedDecimals);
    }

    /************************************************************************
     * public functions
     ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return innerToken.totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    function refund(address _who, uint _counter) public onlyOwnerOrAllowed {
        uint amount = bridgeFromHistory[_who][_counter];
        bridgeFromHistory[_who][_counter] = 0;
        minterBurner.mint(0, _who, amount);
    }

    function setAllowed(address _who, bool _value) public onlyOwner {
        allowed[_who] = _value;
    }

    /************************************************************************
     * internal functions
     ************************************************************************/
    function _debitFrom(address _from, uint16 dstChain, bytes32, uint _amount) internal virtual override returns (uint) {
        require(_from == _msgSender(), "IndirectOFTWithFee: owner is not send caller");

        _amount = _transferFrom(_from, address(minterBurner), _amount);

        // _amount still may have dust if the token has transfer fee, then give the dust back to the sender
        (uint amount, uint dust) = _removeDust(_amount);
        if (dust > 0) innerToken.safeTransfer(_from, dust);

        bridgeFromCounters[_from]++;
        bridgeFromHistory[_from][bridgeFromCounters[_from]] = amount;

        minterBurner.burn(dstChain, _from, _amount); //custom checks for future flexibility 

        return amount;
    }

    function _creditTo(uint16 srcChain, address _toAddress, uint _amount) internal virtual override returns (uint) {

        if (_toAddress == address(this)) {
            return _amount;
        }

        minterBurner.mint(srcChain, _toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        uint before = innerToken.balanceOf(_to);
        if (_from == address(this)) {
            //minterBurner.mint(0, _to, _amount);
            revert(); //shouldnt ever happen
        } else {
            innerToken.safeTransferFrom(_from, _to, _amount);
        }
        return innerToken.balanceOf(_to) - before;
    }

    function _transferFromWithChainId(uint16 _srcChainId, address _from, address _to, uint _amount) internal virtual override returns (uint) {
        uint before = innerToken.balanceOf(_to);
        if (_from == address(this)) {
            minterBurner.mint(_srcChainId, _to, _amount);
        } else {
            revert(); //shouldnt ever happen
        }
        return innerToken.balanceOf(_to) - before;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
}
