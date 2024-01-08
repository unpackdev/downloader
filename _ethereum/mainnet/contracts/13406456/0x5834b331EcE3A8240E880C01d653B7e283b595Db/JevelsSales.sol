// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155TokenReceiver.sol";
import "./Ownable.sol";

contract JevelsSales is ERC1155TokenReceiver, Ownable {
    event UsedAuthorization(uint8 v, bytes32 r, bytes32 s);

    address authorizer;

    struct Authorization {
        address tokenContract;
        uint256 id;
        uint256 amount;
        uint256 validUntil;
    }

    struct AuthorizationBatch {
        address tokenContract;
        uint256[] ids;
        uint256[] amounts;
        uint256 validUntil;
    }

    struct AuthorizationBuy {
        address tokenContract;
        address seller;
        uint256 id;
        uint256 amount;
        uint256 cost;
        uint256 total;
        uint256 validUntil;
    }


    constructor() {
        authorizer = _msgSender();
    }

    function buy(uint8 v_, bytes32 r_, bytes32 s_, AuthorizationBuy calldata authorization_) public payable {
        require(msg.value >= authorization_.total, "Invalid eth amount");
        bytes memory PREFIX = "\x19Ethereum Signed Message:\n32";
        require(ecrecover(keccak256(
                abi.encodePacked(
                    PREFIX,
                    keccak256(
                        abi.encode(authorization_)
                    )
                )
            ), v_, r_, s_) == authorizer, "Message is not signed by authorizer");
        require((authorization_.validUntil > block.timestamp || authorization_.validUntil == 0), "Authorization no longer valid");

        ERC1155(authorization_.tokenContract).safeTransferFrom(address(this), _msgSender(), authorization_.id, authorization_.amount, "");

        payable(authorization_.seller).transfer(authorization_.cost);

        emit UsedAuthorization(v_, r_ ,s_);
    }


    function transfer(uint8 v_, bytes32 r_, bytes32 s_, Authorization calldata authorization_) public {
        bytes memory PREFIX = "\x19Ethereum Signed Message:\n32";
        require(ecrecover(keccak256(
                abi.encodePacked(
                    PREFIX,
                    keccak256(
                        abi.encode(authorization_)
                    )
                )
            ), v_, r_, s_) == authorizer, "Message is not signed by authorizer");
        require((authorization_.validUntil > block.timestamp || authorization_.validUntil == 0), "Authorization no longer valid");

        ERC1155(authorization_.tokenContract).safeTransferFrom(address(this), _msgSender(), authorization_.id, authorization_.amount, "");

        emit UsedAuthorization(v_, r_ ,s_);
    }

    function batchTransfer(uint8 v_, bytes32 r_, bytes32 s_, AuthorizationBatch calldata authorization_) public {
        bytes memory PREFIX = "\x19Ethereum Signed Message:\n32";
        require(ecrecover(keccak256(
                abi.encodePacked(
                    PREFIX,
                    keccak256(
                        abi.encode(authorization_)
                    )
                )
            ), v_, r_, s_) == authorizer, "Message is not signed by authorizer");
        require(authorization_.validUntil > block.timestamp || authorization_.validUntil == 0, "Authorization no longer valid");

        ERC1155(authorization_.tokenContract).safeBatchTransferFrom(address(this), _msgSender(), authorization_.ids, authorization_.amounts, "");

        emit UsedAuthorization(v_, r_ ,s_);
    }

    function setAuthorizer(address authorizer_) public onlyOwner {
        authorizer = authorizer_;
    }

    function withdrawFees() public onlyOwner {
        payable(owner()).transfer(collectedFees());
    }

    function collectedFees() public view returns (uint256) {
        return address(this).balance;
    }
}
