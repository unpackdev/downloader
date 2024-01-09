// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract TokenfyPlatform is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    uint256 public constant ETH = 1;
    uint256 public constant TKNFY = 2;

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    IERC20 public paymentToken;

    mapping(uint256 => bool) public projects;

    address private signerAddress;
    address private payoutAddress;

    event ProjectCreated(uint256 id, uint256 projectType, address creator);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setup(address paymentTokenAddress, address payout, address signer) external onlyOwner {
        paymentToken = IERC20(paymentTokenAddress);
        payoutAddress = payout;
        signerAddress = signer;
    }

    function createProjectETH(
        bytes memory sig, 
        bytes32 hash,
        uint256 id, 
        uint256 value,
        uint256 projectType
    ) payable public nonReentrant {
        require(msg.value == value, "TokenfyPlatform: wrong price");
        require(matchAddresSigner(hash, sig), "TokenfyPlatform: invalid signer");
		require(hashTransaction(msg.sender, id, projectType, ETH, value) == hash, "TokenfyPlatform: hash check failed");
        require(!projects[id], "TokenfyPlatform: project already exists");

        projects[id] = true;

        emit ProjectCreated(id, projectType, msg.sender);
    }

    function createProjectTKNFY(
        bytes memory sig, 
        bytes32 hash,
        uint256 id,
        uint256 value,
        uint256 projectType
    ) public nonReentrant {
        require(paymentToken.balanceOf(msg.sender) >= value, "TokenfyPlatform: insufficient funds");
        require(matchAddresSigner(hash, sig), "TokenfyPlatform: invalid signer");
		require(hashTransaction(msg.sender, id, projectType, TKNFY, value) == hash, "TokenfyPlatform: hash check failed");
        require(!projects[id], "TokenfyPlatform: project already exists");

        projects[id] = true;
        paymentToken.safeTransferFrom(msg.sender, payoutAddress, value);

        emit ProjectCreated(id, projectType, msg.sender);
    }

    function setPaymentToken(address newToken) external onlyOwner {
        paymentToken = IERC20(newToken);
    }

    function setPayoutAddress(address newAddress) external onlyOwner {
        payoutAddress = newAddress;
    }

    function setSigner(address newAddress) external onlyOwner {
        signerAddress = newAddress;
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
		return signerAddress == hash.recover(signature);
	}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	function hashTransaction(
        address sender, 
        uint256 id, 
        uint256 projectType, 
        uint256 currency,
        uint256 value
    ) private pure returns(bytes32) {
		bytes32 hash = keccak256(
			abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                keccak256(abi.encodePacked(sender, id, projectType, currency, value))
            )
		);
		return hash;
	}

}