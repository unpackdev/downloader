// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

interface ISettlersAllied {
//    function isDarkAge() external view returns(bool);

    function reinforce(uint32 _tokenId, bool[4] memory _resources) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;

    function miningState() external view returns(bytes32 _lastHash, uint32 _settled, uint32 _abandoned, uint32 _lastSettleBlock, uint32 _collapseBlock, uint80 _mintFee, uint256 _blockNumber);
    function currentState() external view returns(bool _itIsTheDawnOfANewAge, uint32 _firstSettlement, uint16 _age, uint80 _creatorEarnings, uint80 _relics, uint80 _supplies, address _creator, uint256 _blockNumber);

//    struct Settlement{
//        uint32 settleBlock;
//        uint24 supplyAtMint;
//        uint16 age;
//        uint8 settlementType;
//        uint80 relics;
//        uint80 supplies;
//    }
    function settlements(uint32 _tokenId) external view returns(
        uint32 settleBlock,
        uint24 supplyAtMint,
        uint16 age,
        uint8 settlementType,
        uint80 relics,
        uint80 supplies
    );

    function abandon(uint32[] calldata _tokenIds, uint32 _data) external;
    function confirmDisaster(uint32 _tokenId, uint32 _data) external;

    function ownerOf(uint256 _tokenId) external view returns (address);
}