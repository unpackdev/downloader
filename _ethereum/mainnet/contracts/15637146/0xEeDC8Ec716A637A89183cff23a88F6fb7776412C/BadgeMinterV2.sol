// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./console.sol";

contract BadgeMinterV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable
{
    using SafeMathUpgradeable for uint256;

    address public badgeAddress;
    address public feeCollectorAddress;
    address public signer;
    uint256 public requiredClaimFee;
    bytes32 public _CLAIM_TYPEHASH;
    bytes32 public _MIGRATE_TYPEHASH;

    modifier isSufficientBalance(uint256 burnTokenCnt) {
        require((address(this).balance >= requiredClaimFee.mul(burnTokenCnt)), "BadgeMinterV2: Insuffient balance to refund");

        _;
    }
        
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
    }

    function initializeV2() reinitializer(2) public {
        __EIP712_init("BadgeMinterV2", "2.0.0");

        _MIGRATE_TYPEHASH = keccak256(
            "Migrate(address owner,uint256[] burnBadgeIds,uint256 claimBadgeId)"
        );
    }


    function setBadgeAddress(address _badgeAddress)
        external virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBadgeAddress(_badgeAddress);
    }

    function setFeeCollectorAddress(address _feeCollectorAddress)
        external virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setFeeCollectorAddress(_feeCollectorAddress);
    }

    function setSigner(address _signer) 
        external virtual
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        signer = _signer;
    }

    function setClaimFee(uint256 _claimFee) 
        external virtual
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        requiredClaimFee = _claimFee;
    }

    function transferEther() 
        public payable 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
    }

    function claim(
        uint256 badgeId,
        bytes memory signature
    ) public payable virtual {
        address _to = msg.sender;
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _CLAIM_TYPEHASH,
                    _to,
                    badgeId
                )
            )
        );
        _verify(digest, signature);
        _claim(_to, badgeId);
    }

    function migrate(
        uint256[] memory burnBadgeIds,
        uint256 claimBadgeId,
        bytes memory signature
    ) public payable virtual isSufficientBalance(burnBadgeIds.length) {
        address _to = msg.sender;
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodedata
        // Must encode array
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _MIGRATE_TYPEHASH,
                    _to,
                    keccak256(abi.encodePacked(burnBadgeIds)),
                    claimBadgeId
                )
            )
        );
        _verify(digest, signature);
        _migrate(_to, burnBadgeIds, claimBadgeId);
    }

    function getBadgeAddress() public view virtual returns (address) {
        return badgeAddress;
    }

    function getFeeCollectorAddress() public view virtual returns (address) {
        return feeCollectorAddress;
    }

    function getClaimFee() public view virtual returns (uint256) {
        return requiredClaimFee;
    }

    function getSigner() public view virtual returns (address) {
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
        bytes32 digest,
        bytes memory signature
    ) internal virtual {
        address _signer = ECDSAUpgradeable.recover(digest, signature);
        console.log("recovered signer: %s", _signer);
        console.log("expected signer: %s", signer);
        require(_signer == signer, "_verify: invalid signature");
        require(_signer != address(0), "ECDSA: invalid signature");
    }

    function _claim(
      address to,
      uint256 badgeId
    ) internal virtual {
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

    function _migrate(
      address to,
      uint256[] memory burnBadgeIds,
      uint256 claimBadgeId
    ) internal {
        require(burnBadgeIds.length > 0,  "_migrate: burnBadgeIds is empty");
        require(badgeAddress != address(0), "_migrate: !badgeAddress");

        uint256[] memory amounts = new uint256[](burnBadgeIds.length);
        uint256 noneMintBadgeId = 0;

        for (uint256 i=0; i<burnBadgeIds.length; i++) {
          amounts[i] = 1;
        }
        AddressUpgradeable.functionCall(
          badgeAddress, 
          abi.encodeWithSignature(
              "burnBatch(address,uint256[],uint256[])", 
              to,
              burnBadgeIds,
              amounts
          ),
          "_migrate: burnBatch() failed"
        );
        if (claimBadgeId != noneMintBadgeId) {
            AddressUpgradeable.functionCall(
                badgeAddress, 
                abi.encodeWithSignature(
                    "mint(address,uint256,uint256,bytes)", 
                    to,
                    claimBadgeId, 
                    1, 
                    ""
                ),
                "_migrate: mint() failed"
            );  
        }
        uint256 amount = claimBadgeId == noneMintBadgeId ? requiredClaimFee.mul(burnBadgeIds.length) : requiredClaimFee.mul(burnBadgeIds.length - 1);
        AddressUpgradeable.sendValue(payable(to), amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function getVersion() public pure virtual returns (string memory) {
        return "2.0.0";
    }
}
