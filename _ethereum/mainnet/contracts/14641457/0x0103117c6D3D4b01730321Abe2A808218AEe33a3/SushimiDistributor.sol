// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./MerkleVerifier.sol";
import "./ISushimiToken.sol";

contract SushimiDistributor is Ownable, MerkleVerifier {
    ISushimiToken public immutable sushimiToken;

    mapping(address => uint16) public boughtAmounts;

    uint256 public constant MERKLE_PRICE = 3 * 1e16; // 0.03 ETH
    uint256 public constant PUBLIC_PRICE = 5 * 1e16; // 0.05 ETH

    constructor(ISushimiToken _sushimiToken, bytes32 _merkleRoot)
        MerkleVerifier(_merkleRoot)
    {
        sushimiToken = _sushimiToken;
    }

    function buy(uint8 _amount) public payable {
        require(_amount * PUBLIC_PRICE <= msg.value, "Insufficient value");
        sushimiToken.transfer(msg.sender, _amount * 1e18);
    }

    function buyMerkle(
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint8 _amountToBuy
    ) public payable {
        require(_amountToBuy * MERKLE_PRICE <= msg.value, "Insufficient value");

        boughtAmounts[_account] += _amountToBuy;
        require(boughtAmounts[_account] <= _amount, "Bought too many");

        // Reverts if invalid
        verifyClaim(_index, _account, _amount, _merkleProof);

        sushimiToken.transfer(_account, _amountToBuy * 1e18);
    }

    function rescue() external onlyOwner {
        sushimiToken.transfer(
            msg.sender,
            sushimiToken.balanceOf(address(this))
        );
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
