//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AdminsControllerUpgradeable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./ECDSA.sol";
import "./draft-EIP712Upgradeable.sol";
import "./IFaction.sol";
import "./IERC721A.sol";

contract RequestManagerUpgradeable is Initializable, EIP712Upgradeable, AdminsControllerUpgradeable {
    address public signers;

    struct StakeRequest {
        uint256[] genOnes;
        uint256[] genTwos;
        uint256[] genOnesAmount;
        uint256[] genTwosAmount;
        address recipient;
    }

    struct UnstakeRequest {
        uint256[] genOnes;
        uint256[] genTwos;
        uint256[] genOnesAmount;
        uint256[] genTwosAmount;
        uint256[] exps;
        address recipient;
    }

    struct ClaimRequest {
        uint256[] genTwos;
        uint256[] exps;
        address recipient;
    }

    function __RequestManager_init(address _signer, IAdmins admins) internal onlyInitializing {
        signers = _signer;
        __AdminController_init(admins);
        __EIP712_init("ZOOVERSE_STAKING", "0.1.0");
    }

    function changeSigner(address _signer) external onlyAdmins {
        signers = _signer;
    }

    function verifyStake(StakeRequest calldata request, bytes calldata signature) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                keccak256("StakeRequest(uint256[] genOnes,uint256[] genTwos,uint256[] genOnesAmount,uint256[] genTwosAmount,address recipient)"), 
                keccak256(abi.encodePacked(request.genOnes)),
                keccak256(abi.encodePacked(request.genTwos)),
                keccak256(abi.encodePacked(request.genOnesAmount)),
                keccak256(abi.encodePacked(request.genTwosAmount)),
                msg.sender
            ))
        );
        address signer_ = ECDSA.recover(digest, signature);
        return signer_ == signers;
    }

    function verifyUnstake(UnstakeRequest calldata request, bytes calldata signature) public view returns (bool) {        
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                keccak256("UnstakeRequest(uint256[] genOnes,uint256[] genTwos,uint256[] genOnesAmount,uint256[] genTwosAmount,uint256[] exps,address recipient)"), 
                keccak256(abi.encodePacked(request.genOnes)),
                keccak256(abi.encodePacked(request.genTwos)),
                keccak256(abi.encodePacked(request.genOnesAmount)),
                keccak256(abi.encodePacked(request.genTwosAmount)),
                keccak256(abi.encodePacked(request.exps)),
                msg.sender
            ))
        );
        address signer_ = ECDSA.recover(digest, signature);
        return signer_ == signers;
    }

    function verifyClaim(ClaimRequest calldata request, bytes calldata signature) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                keccak256("ClaimRequest(uint256[] genTwos,uint256[] exps,address recipient)"), 
                keccak256(abi.encodePacked(request.genTwos)),
                keccak256(abi.encodePacked(request.exps)),
                msg.sender
            ))
        );
        address signer_ = ECDSA.recover(digest, signature);
        return signer_ == signers;
    }
}
