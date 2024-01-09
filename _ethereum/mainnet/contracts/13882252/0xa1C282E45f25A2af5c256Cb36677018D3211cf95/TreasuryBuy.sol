//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

$$$$$$$\  $$$$$$$$\  $$$$$$\  $$$$$$$$\  $$$$$$\   $$$$$$\  
$$  __$$\ $$  _____|$$  __$$\ $$  _____|$$  __$$\ $$  __$$\ 
$$ |  $$ |$$ |      $$ /  \__|$$ |      $$ /  \__|$$ /  \__|
$$$$$$$  |$$$$$\    $$ |      $$$$$\    \$$$$$$\  \$$$$$$\  
$$  __$$< $$  __|   $$ |      $$  __|    \____$$\  \____$$\ 
$$ |  $$ |$$ |      $$ |  $$\ $$ |      $$\   $$ |$$\   $$ |
$$ |  $$ |$$$$$$$$\ \$$$$$$  |$$$$$$$$\ \$$$$$$  |\$$$$$$  |
\__|  \__|\________| \______/ \________| \______/  \______/ 
                                                                                                                   
*/

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract TreasuryBuy is Ownable {
    uint256 public constant MIN_TOKENS = 1000 * (10**18);
    uint256 public constant MAX_TOKENS = 3000 * (10**18);
    uint256 public constant BONUS_PERCENT = 15;

    IERC20 private _token;
    uint256 private _tokensPerWei;
    bytes32 private _merkleRoot;

    mapping(string => bool) referralCodeUsed;

    event TokensPurchased(
        address indexed purchaser,
        uint256 weiSpent,
        uint256 purchaserTokensReceived,
        address indexed referrer,
        uint256 referrerTokensReceived
    );

    constructor(
        IERC20 token,
        uint256 tokensPerWei,
        bytes32 merkleRoot
    ) {
        _token = token;
        setTokensPerWei(tokensPerWei);
        setMerkleRoot(merkleRoot);
    }

    function buyTokens(
        uint256 tokenAmount,
        address referrerAddress,
        string calldata referralCode,
        bytes32[] calldata merkleProof
    ) external payable {
        require(tokenAmount >= MIN_TOKENS, 'Tried to buy less than token minimum.');
        require(tokenAmount <= MAX_TOKENS, 'Tried to buy more than token maximum.');

        require(!referralCodeUsed[referralCode], 'Referral code has already been used');
        bytes32 leafNode = keccak256(abi.encodePacked(referrerAddress, referralCode));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leafNode), 'Invalid merkleProof.');

        uint256 requiredValue = tokenAmount / _tokensPerWei;
        require(msg.value == requiredValue, 'Sent wrong amount of ETH.');
        referralCodeUsed[referralCode] = true;
        uint256 bonusAmount = (tokenAmount * BONUS_PERCENT) / 100;
        uint256 purchaserTokensReceived = tokenAmount + bonusAmount;
        _token.transfer(_msgSender(), purchaserTokensReceived);
        _token.transfer(referrerAddress, bonusAmount);
        emit TokensPurchased(
            _msgSender(),
            msg.value,
            purchaserTokensReceived,
            referrerAddress,
            bonusAmount
        );
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}('');
        require(success, 'Withdraw failed.');
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(_msgSender(), balance);
    }

    function exchangeRate() public view returns (uint256) {
        return _tokensPerWei;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setTokensPerWei(uint256 tokensPerWei) public onlyOwner {
        _tokensPerWei = tokensPerWei;
    }
}
