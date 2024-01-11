// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///////////////////////////////////
//       Minter Manager
///////////////////////////////////
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol" ;
import "@openzeppelin/contracts/security/Pausable.sol" ;
import "@openzeppelin/contracts/utils/Strings.sol" ;
import "@openzeppelin/contracts/utils/math/SafeMath.sol" ;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol" ;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol" ;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol" ;
import "./IERC721Receiver.sol";
contract BaseManager is AccessControlEnumerable, Pausable, EIP712, ReentrancyGuard {
    bytes32 public constant SIGN_ROLE = keccak256("SIGN_ROLE");

    // server sign
    mapping(address => bool) public signers;

    constructor(address sign, string memory name, string memory version) EIP712(name, version) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGN_ROLE, sign);
        signers[sign] = true ;
    }

    modifier onlySign() {
        require(signers[_msgSender()], "You have no permission to operate!") ;
        _;
    }

    // pause
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        _pause() ;
        return true ;
    }

    // unpause
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        _unpause() ;
        return true ;
    }

    // add signer
    function addSigner(address sign) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        signers[sign] = true ;
        _setupRole(SIGN_ROLE, sign);
        return true ;
    }

    // del signer
    function delSigner(address sign) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        signers[sign] = false ;
        _revokeRole(SIGN_ROLE, sign);
        return true ;
    }

    // recover pubKey
    function checkSign(bytes memory encodeData, bytes memory signature)
    internal view whenNotPaused returns(bool, address){
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_hashTypedDataV4(keccak256(encodeData)), signature);
        return (signers[recovered] && error == ECDSA.RecoverError.NoError, recovered) ;
    }

    function addressToString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(uint160(address(_addr))));

        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}
