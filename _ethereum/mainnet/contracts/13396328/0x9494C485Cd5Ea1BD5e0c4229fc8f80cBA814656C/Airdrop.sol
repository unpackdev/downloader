// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
    address public signer;
    IERC20 public token;
    mapping(address => bool) public processedAirdrops;

    event ClaimTokens(address recipient, uint amount);

    constructor(address _token, address _signer) {
        token = IERC20(_token);
        signer = _signer;
    }

    function claimTokens(address recipient, uint amount, bytes calldata signature) external {
        require(processedAirdrops[recipient] == false, 'airdrop already processed');
        bytes32 message = keccak256(abi.encodePacked(recipient, amount));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        address recoveredAddr = ECDSA.recover(messageHash, signature);
        require(recoveredAddr == signer, "Invalid signature");

        processedAirdrops[recipient] = true;
        token.transfer(recipient, amount);
        emit ClaimTokens(recipient, amount);
    }

    function returnLeftoverToken(address _recipient) external onlyOwner {
        token.transfer(_recipient, token.balanceOf(address(this)));
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
}
