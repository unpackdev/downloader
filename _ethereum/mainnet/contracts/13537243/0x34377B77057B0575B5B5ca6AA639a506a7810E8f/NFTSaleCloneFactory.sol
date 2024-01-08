// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "./Clones.sol";
import "./INFTSale.sol";

contract NFTSaleCloneFactory {

    event SaleCloneDeployed(address indexed cloneAddress);

    address public referenceSale;
    address public cloner;

    constructor(address _referenceSale) public {
        referenceSale = _referenceSale;
        cloner = msg.sender;
    }

    modifier onlyCloner {
        require(msg.sender == cloner);
        _;
    }

    function changeCloner(address _newCloner) external onlyCloner {
        cloner = _newCloner;
    }

    function newSaleClone(
        address _hausAddress,
        uint256 _startTime,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _priceWei,
        uint256 _limitPerOrder,
        uint256 _stakingRewardPercentageBasisPoints,
        address _stakingSwapContract
    ) external onlyCloner returns (address) {
      // Create new SaleClone
      address newSaleCloneAddress = Clones.clone(referenceSale);
      INFTSale saleClone = INFTSale(newSaleCloneAddress);
      saleClone.initialize(
        _hausAddress,
        _startTime,
        _tokenAddress,
        _tokenId,
        _priceWei,
        _limitPerOrder,
        _stakingRewardPercentageBasisPoints,
        _stakingSwapContract,
        msg.sender
      );
      emit SaleCloneDeployed(newSaleCloneAddress);
      return newSaleCloneAddress;
    }

}