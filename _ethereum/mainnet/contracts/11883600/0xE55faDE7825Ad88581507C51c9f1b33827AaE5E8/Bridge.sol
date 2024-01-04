// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC20.sol";

contract Bridge is Ownable {
    event ReceivedETH(address indexed sender, uint256 value);
    event SentETH(address indexed sender, uint256 value);
    event Redeem(uint64 id);
    using ECDSA for bytes32;
    address[] public signers;
    mapping(uint64 => bool) public redeems;

    constructor(address[] memory _signers, address owner) public {
        signers = _signers;
        transferOwnership(owner);
    }

    function setSigners(address[] memory _signers) public onlyOwner {
        signers = _signers;
    }

    function redeem(
        uint64 amount,
        ERC20 token,
        uint64 experationBlockNumber,
        uint64 redeemId,
        bytes memory signature,
        uint16 signerId
    ) public {
        require(block.number <= experationBlockNumber, "expired");
        require(!redeems[redeemId], "already redeemed");
        require(
            validSignature(
                msg.sender,
                amount,
                token,
                experationBlockNumber,
                redeemId,
                address(this),
                signers[signerId],
                signature
            ), "invalid signature");
        redeems[redeemId] = true;
        uint256 scaledAmount = scaleUp(amount, token);

        if (address(token) == address(0)) {
            transferETH(msg.sender, scaledAmount);
        } else {
            token.transfer(msg.sender, scaledAmount);
        }
        emit Redeem(redeemId);
    }

    function scaleUp(uint64 amount, ERC20 token)
        public
        view
        returns (uint256)
    {
        return amount * uint256(10)**(tokenDecimals(token) - 6);
    }

    function tokenDecimals(ERC20 token) internal view returns (uint8) {
        if (address(token) == address(0)) {
            return 18;
        } else {
            return token.decimals();
        }
    }

    function encodeRedeem(
        address sender,
        uint64 amount,
        ERC20 token,
        uint64 experationBlockNumber,
        uint64 redeemId,
        address contractAddress
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
                sender,
                amount,
                address(token),
                experationBlockNumber,
                redeemId,
                contractAddress
                );
    }

    function validSignature(
        address sender,
        uint64 amount,
        ERC20 token,
        uint64 experationBlockNumber,
        uint64 redeemId,
        address contractAddress,
        address signer,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                sender,
                amount,
                address(token),
                experationBlockNumber,
                redeemId,
                contractAddress
            )
        );
        return hash.recover(signature) == signer;
    }

    function resetRedeems(uint64 lastRedeemId) public onlyOwner {
        for (uint64 i = 0; i <= lastRedeemId; i++) {
            delete redeems[i];
        }
    }

    function withdraw(uint256 amount, ERC20 token) public onlyOwner {
        if (address(token) == address(0)) {
            transferETH(owner(), amount);
        } else {
            token.transfer(owner(), amount);
        }
    }

    function transferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "Ether transfer failed");
        emit SentETH(to, amount);
    }

    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }
}
