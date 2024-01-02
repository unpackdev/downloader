// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseOFTV2.sol";
import "./SafeERC20.sol";
import "./Ownable2Step.sol";

// Token Proxy for LayerZero Bridging
// Should emulate full native layerzero token functionality

contract LzOftProxy is BaseOFTV2, Ownable2Step {

    IERC20 internal immutable innerToken;
    uint internal immutable ld2sdRate;

    constructor(
        address _token,
        uint8 _sharedDecimals,
        address _lzEndpoint
    ) BaseOFTV2(_sharedDecimals, _lzEndpoint) {
        innerToken = IERC20(_token);

        (bool success, bytes memory data) = _token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        require(success, "ProxyOFT: failed to get token decimals");
        uint8 decimals = abi.decode(data, (uint8));

        require(
            _sharedDecimals <= decimals,
            "ProxyOFT: sharedDecimals must be <= decimals"
        );
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /************************************************************************
     * public functions
     ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return innerToken.totalSupply() - innerToken.balanceOf(address(this));
    }

    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    /************************************************************************
     * internal functions
     ************************************************************************/
    function _debitFrom(
        address _from,
        uint16,
        bytes32,
        uint _amount
    ) internal virtual override returns (uint) {
        require(_from == _msgSender(), "not from sender");
        innerToken.transferFrom(_from, address(this), _amount);
        return _amount;
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override returns (uint) {
        innerToken.transfer(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        uint before = innerToken.balanceOf(_to);
        if (_from == address(this)) {
            innerToken.transfer(_to, _amount);
        } else {
            require(_from == _msgSender(), "not from sender");
            innerToken.transferFrom(_from, _to, _amount);
        }
        return innerToken.balanceOf(_to) - before;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }

    /************************************************************************
     * admin functions
     ************************************************************************/

    // fully exit to a new address
    function exit(address _newAddress) external onlyOwner {
        innerToken.transfer(
            _newAddress,
            innerToken.balanceOf(address(this))
        );
    }

    // conversion from ownable to ownable2step
    function transferOwnership(
        address newOwner
    ) public override(Ownable, Ownable2Step) onlyOwner {
        Ownable2Step.transferOwnership(newOwner);
    }

    function _transferOwnership(
        address newOwner
    ) internal override(Ownable, Ownable2Step) {
        Ownable2Step._transferOwnership(newOwner);
    }
}
