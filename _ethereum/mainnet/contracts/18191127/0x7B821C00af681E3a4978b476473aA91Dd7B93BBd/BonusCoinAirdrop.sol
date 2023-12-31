// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract BonusCoinAirdrop is ReentrancyGuard, Ownable {
    bytes32 merkleRoot;
    address public tokenAirdrop;
    bool public  AIRDROP_START = false;
    mapping(address => bool) public userClaimed;
    uint public TOTAL_AIRDROP = 250000000 * 10 ** 18;
    uint INIT_AMOUNT_AIRDROP = 100000 * 10 ** 18;
    uint256 PERCENT_EACH_REDUCE_TIME = 80;

    event ClaimAirdrop(
        address account,
        uint amount
    );

    constructor(address _tokenAirdrop) {
        tokenAirdrop = _tokenAirdrop;
    }

    function claim(bytes32[] calldata _merkleProf, address _referrer) external payable nonReentrant {
        require(!userClaimed[msg.sender], 'CLAIMED BEFORE');
        require(AIRDROP_START, 'WAIT FOR START AIRDROP');
        require(_verify(_merkleProf, msg.sender), "ACCOUNT IS NOT AIRDROP LIST");

        uint _amount = _calculateAmount();
        require(IERC20(tokenAirdrop).balanceOf(address(this)) > _amount, 'INSUFFICIENT PAYMENT');

        userClaimed[msg.sender] = true;
        IERC20(tokenAirdrop).transfer(msg.sender, _amount);

        if(_referrer != address(0) && _referrer != msg.sender && userClaimed[_referrer]) {
            require(IERC20(tokenAirdrop).balanceOf(address(this)) > _amount / 10, 'INSUFFICIENT PAYMENT');
            IERC20(tokenAirdrop).transfer(_referrer, _amount / 10);
        }
        emit ClaimAirdrop(msg.sender, _amount);
    }

    function _calculateAmount() internal view returns (uint) {
        uint totalClaimed = TOTAL_AIRDROP - IERC20(tokenAirdrop).balanceOf(address(this));
        uint amount = INIT_AMOUNT_AIRDROP;

        uint reduceTime = (totalClaimed * 100 / TOTAL_AIRDROP) / 5;

        for (uint i = 0; i < reduceTime; i ++) {
            amount = amount * PERCENT_EACH_REDUCE_TIME / 100;
        }

        return amount;
    }

    function _verify(bytes32[] calldata _merkleProof, address _sender) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function totalClaimed() external view returns (uint) {
        return TOTAL_AIRDROP - IERC20(tokenAirdrop).balanceOf(address(this));
    }

    function currentAmountClaim() external view returns (uint) {
        return _calculateAmount();
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
        AIRDROP_START = status;
    }

    function adminUpdatePercentEachReduceTime(uint percent) external onlyOwner{
        PERCENT_EACH_REDUCE_TIME = percent;
    }

    function adminUpdateInitTotalAirdrop(uint amount) external onlyOwner{
        TOTAL_AIRDROP = amount;
    }

    function adminUpdateInitAmountAirdrop(uint amount) external onlyOwner{
        INIT_AMOUNT_AIRDROP = amount;
    }
}
