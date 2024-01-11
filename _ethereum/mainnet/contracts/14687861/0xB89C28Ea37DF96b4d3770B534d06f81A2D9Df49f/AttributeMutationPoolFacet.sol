// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
pragma solidity ^0.8.0;

import "./LibAppStorage.sol";
import "./IERC1155.sol";
import "./IPower.sol";

import "./console.sol";

interface ITokenAttributeSetter {
    function setAttribute(
        uint256 _tokenId,
        string memory key,
        uint256 value
    ) external;
}

/**
 * @dev Implements an NFT staking pool
 */
contract AttributeMutationPoolFacet is Modifiers, IPower {

    event AttributeMutationPoolValuesSet(string attributeKey, uint256 updateValuePerPeriod, uint256 blocksPerPeriod, uint256 totalValueThreshold);
    event TokenDeposited(address indexed staker, uint256 indexed tokenId);
    event TokenWithdrawn(address indexed staker, uint256 indexed tokenId, uint256 totalAccrued);
    event TokenValueThresholdReached(address indexed staker, uint256 indexed tokenId, uint256 totalAccrued);

    /// @notice set the attribute mutation pool settings
    function setAttributeMutationSettings(string memory attributeKey, uint256 updateValuePerPeriod, uint256 blocksPerPeriod, uint256 totalValueThreshold) public onlyOwner {
        require(bytes(attributeKey).length > 0, "attribute key cannot be empty");
        require(updateValuePerPeriod > 0, "attribute value per block must be greater than 0");
        s.attributeMutationPoolStorage._attributeKey = attributeKey;
        s.attributeMutationPoolStorage._attributeValuePerPeriod = updateValuePerPeriod;
        s.attributeMutationPoolStorage._attributeBlocksPerPeriod = blocksPerPeriod;
        s.attributeMutationPoolStorage._totalValueThreshold = totalValueThreshold;
        emit AttributeMutationPoolValuesSet(attributeKey, updateValuePerPeriod, blocksPerPeriod, totalValueThreshold);
    }

    /// @notice deposit the token into the pool
    function stake(uint256 tokenId) public {
        // require that this be a valid token with the correct attribute set to at least 1
        uint256 currentAccruedValue = s.tokenAttributeStorage.attributes[tokenId][s.attributeMutationPoolStorage._attributeKey];
        require(currentAccruedValue > 0, "token must have accrued value");

        console.log("token id", tokenId);

        // require that this token not be already deposited
        uint256 tdHeight = s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId];
        require(tdHeight == 0, "token has already been deposited");

        console.log("token height", tdHeight);

        console.log("token", s.tokenMinterStorage.token);

        // require that the user have a quantity of the tokenId they specify
        require(IERC1155(s.tokenMinterStorage.token).balanceOf(msg.sender, tokenId) >= 1, "insufficient funds");

        console.log("passed balance check");

        // record the deposit in the variables to track it
        s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId] = block.number;
        IERC1155(s.tokenMinterStorage.token).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

        console.log("transferred token");

        console.log(s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId]);

        // emit a token deposited event
        emit TokenDeposited(msg.sender, tokenId);
    }

    /// @notice withdraw the accrued value for a token
    function unstake(uint256 tokenId) public {

        console.log(s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId]);
        // require(
        //     s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId] > 0 && s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId] <= block.number, "token has not been deposited");
        require(IERC1155(s.tokenMinterStorage.token).balanceOf(address(this), tokenId) >= 1, "insufficient funds");
        uint256 currentAccruedValue = getAccruedValue(tokenId);
        s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId] = 0;

        // set the attribute to the value, or the total value if value > total value
        ITokenAttributeSetter(address(this)).setAttribute(
            tokenId,
            s.attributeMutationPoolStorage._attributeKey,
            currentAccruedValue > s.attributeMutationPoolStorage._totalValueThreshold ? s.attributeMutationPoolStorage._totalValueThreshold : currentAccruedValue
        );
        emit PowerUpdated(tokenId, currentAccruedValue);
        
        // send the token back to the user
        IERC1155(s.tokenMinterStorage.token).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");


        // emit a token withdrawn event
        emit TokenWithdrawn(msg.sender, tokenId, currentAccruedValue);

        // emit a token value threshold reached event if threshold reached
        if(currentAccruedValue >= s.attributeMutationPoolStorage._totalValueThreshold) {
            emit TokenValueThresholdReached(msg.sender, tokenId, currentAccruedValue);
        }

    }

    /// @notice get the accrued value for a token
    function getAccruedValue(uint256 tokenId) public view returns (uint256 _currentAccruedValue) {

        uint256 depositBlockHeight =  s.attributeMutationPoolStorage._tokenDepositHeight[msg.sender][tokenId];
        require(depositBlockHeight > 0 && depositBlockHeight <= block.number, "token has not been deposited");

        uint256 blocksDeposited = block.number - depositBlockHeight;
        uint256 accruedValue = blocksDeposited * s.attributeMutationPoolStorage._attributeValuePerPeriod / s.attributeMutationPoolStorage._attributeBlocksPerPeriod;

        _currentAccruedValue = accruedValue + s.tokenAttributeStorage.attributes[tokenId][s.attributeMutationPoolStorage._attributeKey];

    }
}
