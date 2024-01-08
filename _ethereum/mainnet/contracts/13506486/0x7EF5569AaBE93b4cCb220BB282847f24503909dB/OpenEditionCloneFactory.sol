// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "./Clones.sol";
import "./IOpenEdition.sol";

contract OpenEditionCloneFactory {

    event OpenEditionCloneDeployed(address indexed cloneAddress);

    address public referenceOpenEdition;
    address public cloner;

    constructor(address _referenceOpenEdition) public {
        referenceOpenEdition = _referenceOpenEdition;
        cloner = msg.sender;
    }

    modifier onlyCloner {
        require(msg.sender == cloner);
        _;
    }

    function changeCloner(address _newCloner) external onlyCloner {
        cloner = _newCloner;
    }

    function newOpenEditionClone(
        address _hausAddress,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _priceWei,
        uint256 _limitPerOrder,
        uint256 _stakingRewardPercentageBasisPoints,
        address _stakingSwapContract
    ) external onlyCloner returns (address) {
        // Create new OpenEditionClone
        address newOpenEditionCloneAddress = Clones.clone(referenceOpenEdition);
        IOpenEdition openEdition = IOpenEdition(newOpenEditionCloneAddress);
        openEdition.initialize(
            _hausAddress,
            _startTime,
            _endTime,
            _tokenAddress,
            _tokenId,
            _priceWei,
            _limitPerOrder,
            _stakingRewardPercentageBasisPoints,
            _stakingSwapContract,
            msg.sender
        );
        emit OpenEditionCloneDeployed(newOpenEditionCloneAddress);
        return newOpenEditionCloneAddress;
    }

}