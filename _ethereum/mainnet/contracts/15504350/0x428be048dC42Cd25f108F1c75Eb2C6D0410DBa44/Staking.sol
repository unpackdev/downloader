//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ReceiverUpgradeable.sol";
import "./TrackerUpgradeable.sol";
import "./SignerUpgradeable.sol";
import "./AdminManagerUpgradable.sol";
import "./Initializable.sol";
import "./IERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract Staking is Initializable, ReceiverUpgradeable, AdminManagerUpgradable, SignerUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    struct Request {
        uint256[] ids;
        address owner;
    }

    bytes32 private constant REQUEST_TYPE_HASH = keccak256("Request(uint256[] ids,address owner)");

    event Staked(uint256[] ids, address indexed owner);
    event Unstaked(uint256[] ids, address indexed owner);

    function initialize(
        IERC721Upgradeable nft,
        string memory name,
        string memory version,
        address signer
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __AdminManager_init();
        __Receiver_init(nft);        
        __Signer_init_unchained(name, version, signer);
    }

    function stake(Request calldata request_, bytes calldata signature_) external whenNotPaused {
        require(verify(request_, signature_), "Invalid Signature");
        uint256[] memory ids = request_.ids;
        uint256 length = ids.length;
        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids[i];
            _receive(current, msg.sender);
        }
        emit Staked(ids, msg.sender);
    }

    function unstake(Request calldata request_, bytes calldata signature_) external whenNotPaused {
        require(verify(request_, signature_), "Invalid Signature");
        uint256[] memory ids = request_.ids;
        uint256 length = ids.length;
        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids[i];
            _return(current, msg.sender);
        }
        emit Unstaked(ids, msg.sender);
    }

    function verify(Request calldata request_, bytes calldata signature_) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    REQUEST_TYPE_HASH, 
                    keccak256(abi.encodePacked(request_.ids)),
                    msg.sender
                )
            )
        );
        return _verify(digest, signature_);
    }

    function setNFT(IERC721Upgradeable _nft) external onlyAdmin {
        nft = _nft;
    }
}
