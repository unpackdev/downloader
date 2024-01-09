// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "./Clones.sol";
import "./IVRFNFTSale.sol";

contract VRFNFTSaleCloneFactory {

    event VRFNFTSaleCloneDeployed(address indexed cloneAddress);

    address public referenceVRFNFTSale;
    address public cloner;

    constructor(address _referenceVRFNFTSale) public {
        referenceVRFNFTSale = _referenceVRFNFTSale;
        cloner = msg.sender;
    }

    modifier onlyCloner {
        require(msg.sender == cloner);
        _;
    }

    function changeCloner(address _newCloner) external onlyCloner {
        cloner = _newCloner;
    }

    function newVRFNFTSale(
        address _hausAddress,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress,
        uint256[] memory _tokenIds,
        uint256 _priceWei,
        uint256 _limitPerOrder,
        uint256 _stakingRewardPercentageBasisPoints,
        address _stakingSwapContract,
        address _vrfProvider
    ) external onlyCloner returns (address) {
        // Create new OpenEditionClone
        address newVRFNFTSaleCloneAddress = Clones.clone(referenceVRFNFTSale);
        IVRFNFTSale saleContract = IVRFNFTSale(newVRFNFTSaleCloneAddress);
        saleContract.initialize(
          _hausAddress,
          _startTime,
          _endTime,
          _tokenAddress,
          _tokenIds,
          _priceWei,
          _limitPerOrder,
          _stakingRewardPercentageBasisPoints,
          _stakingSwapContract,
          _vrfProvider,
          msg.sender
        );
        emit VRFNFTSaleCloneDeployed(newVRFNFTSaleCloneAddress);
        return newVRFNFTSaleCloneAddress;
    }

}