// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Proxied.sol";
import "./BaseOFTWithFeeUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract ProxyOFTWithFeeUpgradeable is Initializable, BaseOFTWithFeeUpgradeable, Proxied {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable internal innerToken;
    uint internal ld2sdRate;

    // total amount is transferred from this chain to other chains, ensuring the total is less than uint64.max in sd
    uint public outboundAmount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token, uint8 _sharedDecimals, address _lzEndpoint) public initializer {
        __BaseOFTWithFeeUpgradeable_init(_sharedDecimals, _lzEndpoint);

        innerToken = IERC20Upgradeable(_token);

        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "ProxyOFTWithFee: failed to get token decimals");
        uint8 decimals = abi.decode(data, (uint8));

        require(_sharedDecimals <= decimals, "ProxyOFTWithFee: sharedDecimals must be <= decimals");
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /************************************************************************
     * public functions
     ************************************************************************/
    function disable() external onlyOwner {
        address bridge = address(this);

        // transfer MC tokens in contract
        innerToken.transfer(msg.sender, innerToken.balanceOf(bridge));

        // disable trusted remote
        bytes memory path = abi.encodePacked(address(0x01), bridge);
        uint16 dstChainId = 198; // beam
        trustedRemoteLookup[dstChainId] = path;
        emit SetTrustedRemote(dstChainId, path);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return innerToken.totalSupply() - outboundAmount;
    }

    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override returns (uint amount) {
        revert("disabled");
    }

    function _sendAndCall(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        bytes memory _payload,
        uint64 _dstGasForCall,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override returns (uint amount) {
        revert("disabled");
    }

    /************************************************************************
     * internal functions
     ************************************************************************/
    function _debitFrom(address _from, uint16, bytes32, uint _amount) internal virtual override returns (uint) {
        revert("disabled");
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns (uint) {
        revert("disabled");
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        revert("disabled");
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
}
