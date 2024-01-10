// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./AccessControl.sol"; 
import "./IAddressController.sol";

contract PropyAddressController is AccessControl, IAddressController {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE"); //verifies addresses

    mapping(address => bool) public verifiedRecipients;

    constructor(address _propyControllerAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _propyControllerAddress);
        _setupRole(VERIFIER_ROLE, _propyControllerAddress);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PropyAddressController: Caller is not a Admin");
        _;
    }

    modifier onlyVerifier() {
        require(hasRole(VERIFIER_ROLE, msg.sender), "PropyAddressController: Caller is not a Verifier");
        _;
    }


    // let payload = ethers.utils.defaultAbiCoder.encode([ "address" ], [ addr2.address ]);
    // let payloadHash = ethers.utils.keccak256(payload);
    // let messageHashBytes = ethers.utils.arrayify(payloadHash)
    // let flatSig = await controller1.signMessage(messageHashBytes);
    // let sig = await ethers.utils.splitSignature(flatSig);
    // await propy.connect(addr1).setVerifiedAddress(addr2.address, sig.v, sig.r, sig.s);
    function setVerifiedAddressMeta(address userAddress, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 payloadHash = keccak256(abi.encode(userAddress));
        address signer = verifyHash(payloadHash, v, r, s);
        require(hasRole(VERIFIER_ROLE, signer) == true, "PropyAddressController: Invalid signature provided");
        verifiedRecipients[userAddress] = true;
        //emit event?
        emit AddressVerified(signer, userAddress);
    }

    function setVerifiedAddress(address _userAddress, bool _verified) public override onlyVerifier {
        verifiedRecipients[_userAddress] = _verified;
        if(_verified){
            emit AddressVerified(msg.sender, _userAddress);
        }else{
            emit AddressDelisted(msg.sender, _userAddress);
        }
    }

    function verifyHash(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address signer) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ecrecover(messageDigest, v, r, s);
    }

    function isVerified(address checkAddress) public override view returns (bool) {
        return verifiedRecipients[checkAddress];
    }

}