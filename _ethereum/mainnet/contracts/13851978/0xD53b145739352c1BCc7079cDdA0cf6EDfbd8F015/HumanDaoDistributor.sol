pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./MerkleDistributor.sol";
import "./IERC20.sol";
import "./HumanDaoGenesisNFT.sol";

contract HumanDaoDistributor is MerkleDistributor {

    HumanDaoGenesisNFT public immutable humanDAONFT;

    constructor(address token_, bytes32 merkleRoot_, address humanDAOGenesisNFT_) MerkleDistributor(token_, merkleRoot_) {
        humanDAONFT = HumanDaoGenesisNFT(humanDAOGenesisNFT_);
    }

     function distribute(address account, uint256 amount) internal override returns (uint256) {
        uint256 distributionAmount = calculateMaxDistribution(account, amount);
        require(IERC20(token).transfer(account, distributionAmount), 'MerkleDistributor: Transfer failed.');
        return distributionAmount;
    }

    function mintNft(address account_) internal override {
        humanDAONFT.mint(account_);
    }

    function transferRemainingTokens(address _token) external onlyOwner {
        IERC20 erc20 = IERC20(_token);
        uint256 balance = erc20.balanceOf(address(this));
        erc20.transfer(owner(), balance);
    }

    function transferNftOwnership(address beneficiary_) external onlyOwner {
        humanDAONFT.transferOwnership(beneficiary_);
    }

    //Returns the amount a user would receive. Either 20% of the user's current balance or the distribution amount
    //whichever is the lowest.
    function calculateMaxDistribution(address account_, uint256 amount_) public view returns (uint256){
        IERC20 erc20 = IERC20(token);
        uint256 currentBalance = erc20.balanceOf(account_);
        uint256 bonusOnCurrentBalance = currentBalance / 5;
        if (bonusOnCurrentBalance >= amount_) {
            return amount_;
        } else {
            return bonusOnCurrentBalance;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
