// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.13;

import "./UUPSUpgradeable.sol";

contract JCETHPlaceholderBase is UUPSUpgradeable {
    ////////////////////////////////////////////////////////////////////////////
    // Fields
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Account number this contract belongs to
     */
    uint256 private _accountNumber;

    /**
     * @dev The JC-ETH proxy address.
     */
    address private _jcEth;

    ////////////////////////////////////////////////////////////////////////////
    // function modifier
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Here we use a function instead of a modifier to reduce generated IRs
     */
    function _jcEthOnly() internal view {
        require(msg.sender == _jcEth, "Un-authorized call");
    }

    ////////////////////////////////////////////////////////////////////////////
    // constructor
    ////////////////////////////////////////////////////////////////////////////

    function initialize(address jcEth_, uint256 accountNumber_)
        public
        reinitializer(1)
    {
        _jcEth = jcEth_;
        _accountNumber = accountNumber_;
    }

    ////////////////////////////////////////////////////////////////////////////
    // JC-ETH interfaces
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Conduction contraction proposal through placaholder.
     * Only jcEth can call this via proposal execution. Otherwise, all call will be rejected.
     * This cannot be override.
     */
    function _call(address target_, bytes calldata data)
        public
        returns (bool, bytes memory)
    {
        _jcEthOnly();
        return target_.call(data);
    }

    /**
     * @dev Conduction transfer proposal through placaholder.
     * Only jcEth can call this via proposal execution. Otherwise, all call will be rejected.
     * This cannot be override.
     */
    function _transfer(address target_, uint256 amountInWei_)
        public
        returns (bool, bytes memory)
    {
        _jcEthOnly();
        return (payable(target_).send(amountInWei_), "");
    }

    ////////////////////////////////////////////////////////////////////////////
    // UUPS
    ////////////////////////////////////////////////////////////////////////////

    function _authorizeUpgrade(address) internal view override {
        _jcEthOnly();
    }

    ////////////////////////////////////////////////////////////////////////////
    // public  interfaces
    ////////////////////////////////////////////////////////////////////////////

    function accountNumber() public view returns (uint256) {
        return _accountNumber;
    }

    function jcEth() public view returns (address) {
        return _jcEth;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                abi.encodeWithSignature(
                    "onERC721Received(address,address,uint256,bytes)"
                )
            );
    }

    receive() external payable {}
}
