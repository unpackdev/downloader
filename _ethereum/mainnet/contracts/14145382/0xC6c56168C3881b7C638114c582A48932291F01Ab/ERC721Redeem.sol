// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC721Mintable.sol";
import "./draft-EIP712.sol";
import "./Context.sol";
import "./AccessControl.sol";
import "./Pausable.sol";


contract ERC721Redeem is EIP712, Context, AccessControl, Pausable {

    bytes32 public constant ROLE_VOUCHER_AUTHORIZATION_MANAGER = keccak256("VOUCHER_AUTHORIZATION_MANAGER");
    bytes32 public constant ROLE_SECURITY = keccak256("SECURITY");

    mapping(address => mapping(address => bool)) private _voucherIssuers;
    mapping(address => bool) private _blockedTokenContracts;
    mapping(bytes32 => bool) private _redeemedVouchers;
    mapping(address => mapping(uint256 => bool)) private _lockedNonce;

    event VoucherRedeemed(uint256 nonce, address tokenContract, uint256 nftID, address from, address receiver);
    event VoucherInvalidate(uint256 nonce, address tokenContract, uint256 nftID);
    event TokenContractLockStatusChanged(address tokenContract, bool status);
    event TokenContractVoucherIssuerStatusChanged(address tokenContract, address issuer, bool status);
    event NonceLockStatus(uint256 nonce, address tokenContract, bool status);

    constructor(string memory Name, string memory Version) EIP712(Name, Version) {
        _setupRole(ROLE_VOUCHER_AUTHORIZATION_MANAGER, msg.sender);
        _setupRole(ROLE_SECURITY, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _getVoucherHash(uint256 nonce, address tokenContract, uint256 nftID, address from, address receiver) private view returns (bytes32) {
        return _hashTypedDataV4(keccak256(
                abi.encode(
                    keccak256(
                        "NftVoucher(uint256 nonce,address tokenContract,uint256 nftID,address from,address receiver)"
                    ),
                    nonce,
                    tokenContract,
                    nftID,
                    from,
                    receiver
                )));
    }

    function _getVoucherID(uint256 nonce, address tokenContract, uint256 nftID) private pure returns (bytes32) {
        return keccak256(abi.encode(
                nonce,
                tokenContract,
                nftID
            ));
    }

    function redeem(
        uint256 nonce,
        address tokenContract,
        uint256 nftID,
        address from,
        address receiver,
        uint8 v,
        bytes32 r,
        bytes32 s) public whenNotPaused {

        require(!_blockedTokenContracts[tokenContract], "token contract has locked");
        require(!_lockedNonce[tokenContract][nonce], "nonce has locked");
        bytes32 voucherID = _getVoucherID(nonce, tokenContract, nftID);

        require(_redeemedVouchers[voucherID] != true, "voucher already redeemed");

        bytes32 voucherHash = _getVoucherHash(nonce, tokenContract, nftID, from, receiver);
        address signerAddress = ECDSA.recover(voucherHash, v, r, s);

        require(_voucherIssuers[tokenContract][signerAddress] == true, "authorization_error: incorrect voucher signer");

        if (from == address(0)) {
            IERC721Mintable(tokenContract).safeMint(receiver, nftID);
        } else {
            IERC721Mintable(tokenContract).safeTransferFrom(from, receiver, nftID);
        }

        _redeemedVouchers[voucherID] = true;
        emit VoucherRedeemed(nonce, tokenContract, nftID, from, receiver);
    }

    function setLockNonce(address tokenContract, uint256 nonce, bool status) public onlyRole(ROLE_VOUCHER_AUTHORIZATION_MANAGER) {
        _lockedNonce[tokenContract][nonce] = status;
        emit NonceLockStatus(nonce, tokenContract, status);
    }

    function invalidateVoucher(
        uint256 nonce,
        address tokenContract,
        uint256 nftID) public onlyRole(ROLE_VOUCHER_AUTHORIZATION_MANAGER) {
        bytes32 voucherID = _getVoucherID(nonce, tokenContract, nftID);
        _redeemedVouchers[voucherID] = true;
        emit VoucherInvalidate(nonce, tokenContract, nftID);
    }

    function setVoucherIssuerStatus(address tokenContract, address issuer, bool status) public onlyRole(ROLE_VOUCHER_AUTHORIZATION_MANAGER) {
        _voucherIssuers[tokenContract][issuer] = status;
        emit TokenContractVoucherIssuerStatusChanged(tokenContract, issuer, status);
    }

    function setLockTokenContractStatus(address tokenContract, bool status) public onlyRole(ROLE_VOUCHER_AUTHORIZATION_MANAGER) {
        _blockedTokenContracts[tokenContract] = status;
        emit TokenContractLockStatusChanged(tokenContract, status);
    }

    function isVoucherIssuer(address tokenContract, address issuer) public view returns (bool) {
        return _voucherIssuers[tokenContract][issuer];
    }

    function pause() public onlyRole(ROLE_SECURITY) {
        _pause();
    }

    function unpause() public onlyRole(ROLE_SECURITY) {
        _unpause();
    }

}
