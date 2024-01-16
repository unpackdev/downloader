pragma solidity ^0.8.17;
import "./Erc721ItemAsset.sol";
import "./ContractData.sol";
import "./IPositionsController.sol";
import "./AssetFactoryBase.sol";
import "./IErc721ItemAsset.sol";
import "./IErc721ItemAssetFactory.sol";

contract Erc721ItemAssetFactory is AssetFactoryBase, IErc721ItemAssetFactory {
    constructor(address positionsController_)
        AssetFactoryBase(positionsController_)
    {}

    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress,
        uint256 tokenId
    ) external {
        _setAsset(positionId, assetCode, createAsset(contractAddress, tokenId));
    }

    function createAsset(address contractAddress, uint256 tokenId)
        internal
        returns (ContractData memory)
    {
        ContractData memory data;
        data.factory = address(this);
        data.contractAddr = address(
            new Erc721ItemAsset(
                address(positionsController),
                this,
                contractAddress,
                tokenId
            )
        );
        return data;
    }

    function _clone(address asset, address owner)
        internal
        override
        returns (IAsset)
    {
        return
            new Erc721ItemAsset(
                owner,
                this,
                IErc721ItemAsset(asset).getContractAddress(),
                IErc721ItemAsset(asset).getTokenId()
            );
    }
}
