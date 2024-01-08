// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./interface.sol";
import "./helpers.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract GraphProtocolStaking is Helpers {
    string public name = "GraphProtocol-v1";

    using SafeMath for uint256;

    function delegateMultiple(
        address[] memory indexers,
        uint256 amount,
        uint256[] memory portions,
        uint256 getId
    ) external payable {
        require(
            portions.length == indexers.length,
            "Indexer and Portion length doesnt match"
        );
        uint256 delegationAmount = getUint(getId, amount);
        uint256 totalPortions = 0;

        uint256[] memory indexersAmount = new uint256[](indexers.length);

        for (uint256 position = 0; position < portions.length; position++) {
            indexersAmount[position] = portions[position]
                .mul(delegationAmount)
                .div(PORTIONS_SUM);
            totalPortions = totalPortions + portions[position];
        }

        require(totalPortions == PORTIONS_SUM, "Portion Mismatch");

        grtTokenAddress.approve(address(graphProxy), delegationAmount);

        for (uint256 i = 0; i < indexers.length; i++) {
            graphProxy.delegate(indexers[i], indexersAmount[i]);
        }
    }

    function undelegate(address _indexer, uint256 _shares) external payable {
        require(_indexer != address(0), "!Invalid Address");
        graphProxy.undelegate(_indexer, _shares);
    }

    function undelegateMultiple(
        address[] memory _indexers,
        uint256[] memory _shares
    ) external payable {
        require(
            _indexers.length == _shares.length,
            "Indexers & shares mismatch"
        );
        for (uint256 i = 0; i < _indexers.length; i++) {
            graphProxy.undelegate(_indexers[i], _shares[i]);
        }
    }

    function withdrawDelegated(address _indexer, address _delegateToIndexer)
        external
        payable
    {
        graphProxy.withdrawDelegated(_indexer, _delegateToIndexer);
    }

    function withdrawMultipleDelegate(
        address[] memory _indexers,
        address[] memory _delegateToIndexers
    ) external payable {
        for (uint256 i = 0; i < _indexers.length; i++) {
            graphProxy.withdrawDelegated(_indexers[i], _delegateToIndexers[i]);
        }
    }
}
