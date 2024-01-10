// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./SafeMath.sol";
import "./ERC1155Holder.sol";
import "./Address.sol";
import "./IFancyBears.sol";
import "./IFancyBearTraits.sol";
import "./IFancyBearHoneyConsumption.sol";

contract FancyTraitStaking is ERC1155Holder {
    
    using SafeMath for uint256;
    using Address for address;

    IFancyBears fancyBearsContract;
    IFancyBearTraits fancyTraitContract;
    IFancyBearHoneyConsumption fancyBearHoneyConsumptionContract;

    mapping(uint256 => mapping(string => uint256))
        public stakedTraitsByCategoryByFancyBear;

    event TraitStaked(
        uint256 indexed _fancyBear,
        uint256 _traitId,
        string category,
        address _address
    );
    event TraitUnstaked(
        uint256 indexed _fancyBear,
        uint256 _traitId,
        string category,
        address _address
    );
    event TraitSwapped(
        uint256 indexed _fancyBear,
        string category,
        uint256 _oldTrait,
        uint256 _newTriat
    );

    constructor(
        IFancyBears _fancyBearsContract,
        IFancyBearTraits _fancyTraitContract,
        IFancyBearHoneyConsumption _fancyBearHoneyConsumptionContract
    ) {
        fancyBearsContract = _fancyBearsContract;
        fancyTraitContract = _fancyTraitContract;
        fancyBearHoneyConsumptionContract = _fancyBearHoneyConsumptionContract;
    }

    function stakeTraits(uint256 _fancyBear, uint256[] calldata _traitIds) public {

        require(
            fancyBearsContract.ownerOf(_fancyBear) == msg.sender,
            "stakeTraits: caller does not own fancy bear"
        );

        string memory category;
        uint256 honeyConsumptionRequirement;

        for (uint256 i = 0; i < _traitIds.length; i++) {

            require(
                fancyTraitContract.balanceOf(msg.sender, _traitIds[i]) > 0,
                "stakeTraits: caller does not own trait"
            );

            (, category, honeyConsumptionRequirement) = fancyTraitContract.getTrait(_traitIds[i]);

            require(
                fancyBearHoneyConsumptionContract.honeyConsumed(_fancyBear) >=
                    honeyConsumptionRequirement,
                "stakeTraits: fancy bear has not consumed enough honey"
            );

            uint256 currentTrait = stakedTraitsByCategoryByFancyBear[_fancyBear][category];

            if (currentTrait != 0) {

                fancyTraitContract.safeTransferFrom(
                    address(this),
                    msg.sender,
                    stakedTraitsByCategoryByFancyBear[_fancyBear][category],
                    1,
                    ""
                );
                
                delete (
                    stakedTraitsByCategoryByFancyBear[_fancyBear][category]
                );
            }

            fancyTraitContract.safeTransferFrom(
                msg.sender,
                address(this),
                _traitIds[i],
                1,
                ""
            );

            stakedTraitsByCategoryByFancyBear[_fancyBear][category] = _traitIds[i];

            if (currentTrait == 0) {
                emit TraitStaked(_fancyBear, _traitIds[i], category, msg.sender);
            }
            else {
                emit TraitSwapped(
                    _fancyBear,
                    category,
                    currentTrait,
                    _traitIds[i]
                );
            }
        }
    }

    function unstakeTraits(
        uint256 _fancyBear,
        string[] calldata _categoriesToUnstake
    ) public {
        require(
            fancyBearsContract.ownerOf(_fancyBear) == msg.sender,
            "unstakeTraits: caller does not own fancy bear"
        );

        uint256 trait;

        for (uint256 i = 0; i < _categoriesToUnstake.length; i++) {
            require(
                fancyTraitContract.categoryValidation(_categoriesToUnstake[i]),
                "unstakeTraits: invalid trait category"
            );

            trait = stakedTraitsByCategoryByFancyBear[_fancyBear][_categoriesToUnstake[i]];

            require(trait != 0, "unstakeTraits: no trait staked in category");

            fancyTraitContract.safeTransferFrom(
                address(this),
                msg.sender,
                trait,
                1,
                ""
            );
            delete (stakedTraitsByCategoryByFancyBear[_fancyBear][_categoriesToUnstake[i]]);

            emit TraitUnstaked(
                _fancyBear,
                trait,
                _categoriesToUnstake[i],
                msg.sender
            );
        }
    }

    function getStakedTraits(uint256 _fancyBear)
        public
        view
        returns (uint256[] memory, string[] memory)
    {
        uint256[] memory traitArray = new uint256[](fancyTraitContract.categoryPointer());
        string[] memory categories = new string[](fancyTraitContract.categoryPointer());

        for (uint256 i = 0; i < traitArray.length; i++) {
            categories[i] = fancyTraitContract.categories(i);
            traitArray[i] = stakedTraitsByCategoryByFancyBear[_fancyBear][categories[i]];
        }
        return (traitArray, categories);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
