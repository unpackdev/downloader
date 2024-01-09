// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";

contract Locker is Context, AccessControl {
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
    uint256 public networkId = block.chainid;
    address public multiSignWallet;

    event LockerTransfer(
        address _nftContract,
        uint256 _nftTokenId,
        address _to,
        uint256 _when
    );

    constructor(address _multiSignWallet) {
        require(_multiSignWallet != address(0), "Locker:: Multi Sign Wallet Can not to be Zero Wallet");
        multiSignWallet = _multiSignWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, multiSignWallet);
    }

    function release(
        address _nftContract,
        uint256 _tokenId,
        address _to
    ) public {
        require(hasRole(LOCKER_ROLE, _msgSender()), "Locker:: Unauthorized Access, Only PawnMortgage allowed to release");
        IERC721(_nftContract).safeTransferFrom(address(this), _to, _tokenId);
        emit LockerTransfer(_nftContract, _tokenId, _to, block.timestamp);
    }
}