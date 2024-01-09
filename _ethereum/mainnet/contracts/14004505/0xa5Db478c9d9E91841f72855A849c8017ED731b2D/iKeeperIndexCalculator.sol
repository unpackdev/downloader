// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";


contract iKeeperIndexCalculator is Ownable {

    using SafeMath for uint;

    event AssetIndexAdded( uint indexed deposit, uint indexed price, address indexed token );
    event IndexUpdated( uint indexed fromIndex, uint indexed toIndex, uint oldPrice, uint newPrice );
    event DepositUpdated( uint indexed fromDeposit, uint indexed toDeposit );
    event AssetIndexWithdrawn( uint indexed deposit, uint price, uint indexed index, address indexed token );

    struct AssetIndex {
        uint deposit;   // In USD
        uint price;     // 6 decimals, in USD
        uint index;     // 9 decimals, starts with 1000000000
        address token;   // Token address of the asset
    }
    AssetIndex[] public indices;
    uint public netIndex;


    constructor(uint _netIndex) {
        require( _netIndex != 0, "Index cannot be 0" );
        netIndex = _netIndex;
    }


    function calculateIndex() public {
        uint indexProduct = 0;
        uint totalDeposit = 0;
        for (uint i=0; i < indices.length; i++) {
            uint deposit = indices[i].deposit;
            totalDeposit = totalDeposit.add(deposit);
            indexProduct = indexProduct.add( indices[i].index.mul( deposit ) );
        }
        netIndex = indexProduct.div(totalDeposit);
    }


    function addAssetIndex(uint _deposit, uint _price, address _token) external onlyOwner() {
        indices.push( AssetIndex({
            deposit: _deposit,
            price: _price,
            index: 1e9,
            token: _token
        }));
    }


    function updateIndex(uint _index, address _token, uint _newPrice) external onlyOwner() {
        AssetIndex storage assetIndex = indices[ _index ];
        require(assetIndex.token == _token, "Wrong index.");
        uint changeIndex = _newPrice.mul(1e9).div(assetIndex.price);
        uint fromIndex = assetIndex.index;
        uint oldPrice = assetIndex.price;
        assetIndex.index = fromIndex.mul(changeIndex).div(1e9);
        assetIndex.deposit = assetIndex.deposit.mul(changeIndex).div(1e9);
        assetIndex.price = _newPrice;
        emit IndexUpdated(fromIndex, assetIndex.index, oldPrice, _newPrice);
    }


    function updateDeposit(uint _index, address _token, uint _amount, bool _add) external onlyOwner() {
        require(_token == indices[ _index ].token, "Wrong index.");
        uint oldDeposit = indices[ _index ].deposit;
        require(_add || oldDeposit >= _amount, "Cannot withdraw more than deposit");
        if (!_add) {
            indices[ _index ].deposit = oldDeposit.sub(_amount);
        } else {
            indices[ _index ].deposit = oldDeposit.add(_amount);
        }
        emit DepositUpdated(oldDeposit, indices[ _index ].deposit);
    }


    function withdrawAsset(uint _index, address _token) external onlyOwner() {
        AssetIndex memory assetIndex = indices[ _index ];
        require(_token == assetIndex.token, "Wrong index.");
        indices[ _index ] = indices[indices.length-1];
        indices.pop();
        emit AssetIndexWithdrawn(assetIndex.deposit, assetIndex.price, assetIndex.index, assetIndex.token);
    }

}