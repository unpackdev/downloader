// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IBettingFactory.sol";
import "./Ownable.sol";

contract Factory is Ownable {
    mapping(PrizeBetting => address) public typeToAddress;

    enum PrizeBetting {
        GuaranteedPrizeFactory,
        StandardPrizeFactory,
        CommunityFactory,
        FreeFactory
    }

    constructor(
        address _guaranteed,
        address _standard,
        address _community,
        address _free
    ) {
        typeToAddress[PrizeBetting.GuaranteedPrizeFactory] = _guaranteed;
        typeToAddress[PrizeBetting.StandardPrizeFactory] = _standard;
        typeToAddress[PrizeBetting.CommunityFactory] = _community;
        typeToAddress[PrizeBetting.FreeFactory] = _free;
    }

    function setPrizeBettingAddress(
        address _guaranteed,
        address _standard,
        address _community,
        address _free
    ) external onlyOwner {
        typeToAddress[PrizeBetting.GuaranteedPrizeFactory] = _guaranteed;
        typeToAddress[PrizeBetting.StandardPrizeFactory] = _standard;
        typeToAddress[PrizeBetting.CommunityFactory] = _community;
        typeToAddress[PrizeBetting.FreeFactory] = _free;
    }

    function setTypeToAddress(PrizeBetting _type, address _newAddr)
        public
        onlyOwner
    {
        typeToAddress[_type] = _newAddr;
    }

    function createNewFreeBettingContract(
        address payable _ownerPool,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.FreeFactory])
                .createNewBettingContract(_ownerPool, _creator, _tokenPool, _fee);
    }

    function createNewCommunityBettingContract(
        address payable _ownerPool,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.CommunityFactory])
                .createNewBettingContract(_ownerPool, _creator, _tokenPool, _fee);
    }

    function createNewStandardBettingContract(
        address payable _ownerPool,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.StandardPrizeFactory])
                .createNewBettingContract(
                    _ownerPool,
                    _creater,
                    _tokenPool,
                    _rewardForWinner,
                    _rewardForCreator,
                    _decimal,
                    _fee
                );
    }

    function createNewGuaranteedBettingContract(
        address payable _ownerPool,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.GuaranteedPrizeFactory])
                .createNewBettingContract(
                    _ownerPool,
                    _creater,
                    _tokenPool,
                    _rewardForWinner,
                    _rewardForCreator,
                    _decimal,
                    _fee
                );
    }
}
