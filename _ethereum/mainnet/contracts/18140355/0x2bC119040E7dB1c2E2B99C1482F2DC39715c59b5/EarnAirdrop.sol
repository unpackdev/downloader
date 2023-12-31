// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ReentrancyGuard.sol";
import "./Governable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract EarnAirdrop is ReentrancyGuard, Ownable {
    uint256 constant PRECISION = 1000;
    address tokenAirdrop;
    bytes32 merkleRoot;
    bool START_AIRDROP = false;
    mapping (address => bool) userClaimed;

    event ClaimAirdrop(
        address account,
        uint amount
    );

    constructor(address _tokenAirdrop) {
        tokenAirdrop = _tokenAirdrop;
    }

    function claim(bytes32[] calldata _merkleProf, uint _amount) external payable nonReentrant {
        require(!userClaimed[msg.sender], 'CLAIMED BEFORE');
        require(START_AIRDROP, 'WAIT FOR START AIRDROP');
        require(IERC20(tokenAirdrop).balanceOf(address(this)) > _amount, 'INSUFFICIENT PAYMENT');
        require(_verify(_merkleProf, msg.sender, _amount), "ACCOUNT IS NOT AIRDROP LIST");

        userClaimed[msg.sender] = true;

        IERC20(tokenAirdrop).transfer(msg.sender, _amount);
        emit ClaimAirdrop(msg.sender, _amount);
    }

    function _verify(bytes32[] calldata _merkleProof, address _sender, uint _amount) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_sender, _amount));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // ===================== ADMIN ========================

    /**
    * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token, uint amount) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance >= amount, "Operations: No token to recover");

        IERC20(_token).transfer(address(msg.sender), amount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function startAirdrop(bool status) external onlyOwner {
        START_AIRDROP = status;
    }
}
