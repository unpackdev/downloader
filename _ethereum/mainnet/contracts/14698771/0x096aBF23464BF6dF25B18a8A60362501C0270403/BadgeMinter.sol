// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./console.sol";

contract BadgeMinter is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable
{
    address public badgeAddress;
    address public feeCollectorAddress;
    address public signer;
    uint256 public requiredClaimFee;
    bytes32 public _CLAIM_TYPEHASH;
        
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
    }

    function initialize(
        address _badgeAddress, 
        address _feeCollectorAddress
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __EIP712_init("BadgeMinter", "1.0.0");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setBadgeAddress(_badgeAddress);
        _setFeeCollectorAddress(_feeCollectorAddress);

        signer = msg.sender;
        requiredClaimFee = 0;
        _CLAIM_TYPEHASH = keccak256(
            "Claim(address owner,uint256 badgeId)"
        );
    }

    function setBadgeAddress(address _badgeAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBadgeAddress(_badgeAddress);
    }

    function setFeeCollectorAddress(address _feeCollectorAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setFeeCollectorAddress(_feeCollectorAddress);
    }

    function setSigner(address _signer) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        signer = _signer;
    }

    function setClaimFee(uint256 _claimFee) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        requiredClaimFee = _claimFee;
    }

    function claim(
        uint256 badgeId,
        bytes memory signature
    ) public payable {
        address _to = msg.sender;
        _verify(_to, badgeId, signature);
        _claim(_to, badgeId);
    }

    function getBadgeAddress() public view returns (address) {
        return badgeAddress;
    }

    function getFeeCollectorAddress() public view returns (address) {
        return feeCollectorAddress;
    }

    function getClaimFee() public view returns (uint256) {
        return requiredClaimFee;
    }

    function getSigner() public view returns (address) {
        return signer;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _setBadgeAddress(address _badgeAddress)
        private
    {
        badgeAddress = _badgeAddress;
    }

    function _setFeeCollectorAddress(address _feeCollectorAddress)
        private
    {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function _verify(
        address owner,
        uint256 badgeId,
        bytes memory signature
    ) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _CLAIM_TYPEHASH,
                    owner,
                    badgeId
                )
            )
        );

        address _signer = ECDSAUpgradeable.recover(digest, signature);
        console.log("recovered signer: %s", _signer);
        console.log("expected signer: %s", signer);
        require(_signer == signer, "_verify: invalid signature");
        require(_signer != address(0), "ECDSA: invalid signature");
    }

    function _claim(
      address to,
      uint256 badgeId
    ) private {
        require(msg.value >= requiredClaimFee, "_claim: fee is not enough");
        require(feeCollectorAddress != address(0), "_claim: !feeCollectorAddress");
        require(badgeAddress != address(0), "_claim: !badgeAddress");
        
        AddressUpgradeable.functionCallWithValue(
            feeCollectorAddress, 
            abi.encodeWithSignature(
                "collect(uint256,address)", 
                badgeId, 
                to
            ), 
            msg.value, 
            "_claim: collect() failed"
        );

        AddressUpgradeable.functionCall(
            badgeAddress, 
            abi.encodeWithSignature(
                "mint(address,uint256,uint256,bytes)", 
                to,
                badgeId, 
                1, 
                ""
            ),
            "_claim: mint() failed"
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
