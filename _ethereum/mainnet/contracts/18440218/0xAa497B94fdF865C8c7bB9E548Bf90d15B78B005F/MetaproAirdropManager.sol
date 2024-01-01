// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./IAirdropERC1155.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./console.sol";

contract AirdropManager_Test is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;

    event AirdropSent(
        address indexed tokenAddress,
        address indexed tokenOwner,
        uint256 _tokenId,
        IAirdropERC1155.AirdropContent[] contents
    );

    // Mapping to store admin status per wallet address.
    mapping(address => bool) public isAdmin;
    // Treasury address to receive airdrop fee.
    address payable public treasuryAddress;
    // Fee per airdrop recipient in wei.
    uint256 public feePerAirdropRecipient = 0.00000001 ether;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "OnlyAdmin: Only admin can call this.");
        _;
    }

    constructor(address _treasuryAddress) {
        treasuryAddress = payable(_treasuryAddress);
        isAdmin[msg.sender] = true;
    }

    // Function to get airdrop fee in wei.
    function getAirdropFee(
        IAirdropERC1155.AirdropContent[] calldata _contents
    ) public view returns (uint256) {
        return _contents.length.mul(feePerAirdropRecipient);
    }

    // Function to airdrop ERC1155 tokens to multiple recipients.
    function airdropERC1155(
        address _tokenAddress,
        uint256 _tokenId,
        IAirdropERC1155.AirdropContent[] calldata _contents
    ) external payable nonReentrant {
        uint256 len = _contents.length;
        uint256 tokensToTransfer = 0;

        for (uint256 i = 0; i < len; i++) {
            tokensToTransfer += _contents[i].amount;
        }

        require(
            IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId) >=
                tokensToTransfer,
            "MetaproAirdropManager: Not enough airdrop token balance"
        );

        IERC1155(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            tokensToTransfer,
            ""
        );

        if (!isAdmin[msg.sender]) {
            uint256 airdropFee = getAirdropFee(_contents);
            require(
                msg.value >= airdropFee,
                "MetaproAirdropManager: Not enough airdrop fee"
            );
            treasuryAddress.transfer(airdropFee);
        }

        for (uint256 i = 0; i < len; i++) {
            IERC1155(_tokenAddress).safeTransferFrom(
                address(this),
                _contents[i].recipient,
                _tokenId,
                _contents[i].amount,
                ""
            );
        }

        emit AirdropSent(_tokenAddress, msg.sender, _tokenId, _contents);
    }

    // Function to set admin status per wallet address.
    function toggleAdminStatus(
        address _admin,
        bool _status
    ) external onlyOwner {
        require(
            _admin != address(0),
            "ToggleAdminStatus: Invalid admin address."
        );
        isAdmin[_admin] = _status;
    }

    // Function to set treasury address.
    function setTreasuryAddress(
        address _newTreasuryAddress
    ) external onlyOwner {
        require(
            _newTreasuryAddress != address(0),
            "SetTreasuryAddress: Invalid treasury address."
        );
        treasuryAddress = payable(_newTreasuryAddress);
    }

    // Function to set fee per airdrop recipient in wei.
    function setFeePerAirdropRecipientInWei(
        uint256 _unitFeeInWei
    ) external onlyOwner {
        feePerAirdropRecipient = _unitFeeInWei;
    }
}
