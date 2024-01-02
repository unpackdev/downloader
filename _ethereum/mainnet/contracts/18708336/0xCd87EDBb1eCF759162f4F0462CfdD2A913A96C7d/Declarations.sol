// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./AaveEvents.sol";

import "./IWETH.sol";
import "./IAave.sol";
import "./IWiseLending.sol";
import "./IWiseSecurity.sol";
import "./IPositionNFTs.sol";

import "./OwnableMaster.sol";

error AlreadySet();
error InvalidValue();
error InvalidAction();
error FailedInnerCall();

contract Declarations is OwnableMaster, AaveEvents {

    IAave internal immutable AAVE;
    IWETH internal immutable WETH;

    // This is used to prevent reentrancy attacks and public to ease building on top
    bool public sendingProgressAaveHub;

    uint16 internal constant REF_CODE = 0;

    IWiseLending immutable public WISE_LENDING;
    IPositionNFTs immutable public POSITION_NFT;

    IWiseSecurity public WISE_SECURITY;

    address immutable public WETH_ADDRESS;
    address immutable public AAVE_ADDRESS;

    uint256 internal constant PRECISION_FACTOR_E9 = 1E9;
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;
    uint256 internal constant MAX_AMOUNT = type(uint256).max;

    mapping(address => address) public aaveTokenAddress;

    constructor(
        address _master,
        address _aaveAddress,
        address _lendingAddress
    )
        OwnableMaster(
            _master
        )
    {
        if (_aaveAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        if (_lendingAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        AAVE_ADDRESS = _aaveAddress;

        WISE_LENDING = IWiseLending(
            _lendingAddress
        );

        WETH_ADDRESS = WISE_LENDING.WETH_ADDRESS();

        AAVE = IAave(
            AAVE_ADDRESS
        );

        WETH = IWETH(
            WETH_ADDRESS
        );

        POSITION_NFT = IPositionNFTs(
            WISE_LENDING.POSITION_NFT()
        );
    }

    function _checkOwner(
        uint256 _nftId
    )
        internal
        view
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );
    }

    function _checkPositionLocked(
        uint256 _nftId
    )
        internal
        view
    {
        WISE_LENDING.checkPositionLocked(
            _nftId,
            msg.sender
        );
    }

    function _checkDeposit(
        uint256 _nftId,
        address _underlyingToken,
        uint256 _depositAmount
    )
        internal
        view
    {
        WISE_LENDING.checkDeposit(
            _nftId,
            msg.sender,
            aaveTokenAddress[_underlyingToken],
            _depositAmount
        );
    }

    function _checksWithdraw(
        uint256 _nftId,
        address _underlyingToken,
        uint256 _withdrawAmount
    )
        internal
        view
    {
        WISE_SECURITY.checksWithdraw(
            _nftId,
            msg.sender,
            aaveTokenAddress[_underlyingToken],
            _withdrawAmount
        );
    }

    function _checksBorrow(
        uint256 _nftId,
        address _underlyingToken,
        uint256 _borrowAmount
    )
        internal
        view
    {
        WISE_SECURITY.checksBorrow(
            _nftId,
            msg.sender,
            aaveTokenAddress[_underlyingToken],
            _borrowAmount
        );
    }

    function _checksSolelyWithdraw(
        uint256 _nftId,
        address _underlyingToken,
        uint256 _withdrawAmount
    )
        internal
        view
    {
        WISE_SECURITY.checksSolelyWithdraw(
            _nftId,
            msg.sender,
            aaveTokenAddress[_underlyingToken],
            _withdrawAmount
        );
    }

    function setWiseSecurity(
        address _securityAddress
    )
        external
        onlyMaster
    {
        if (address(WISE_SECURITY) > ZERO_ADDRESS) {
            revert AlreadySet();
        }

        WISE_SECURITY = IWiseSecurity(
            _securityAddress
        );
    }
}
