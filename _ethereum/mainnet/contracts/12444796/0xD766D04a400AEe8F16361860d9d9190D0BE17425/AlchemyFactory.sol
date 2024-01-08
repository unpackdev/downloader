// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./IERC721.sol";
import "./CloneLibrary.sol";


/// @author Alchemy Team
/// @title AlchemyFactory
/// @notice Factory contract to create new instances of Alchemy
contract AlchemyFactory {
    using CloneLibrary for address;

    // event that is emitted when a new Alchemy Contract was minted
    event NewAlchemy(address alchemy, address governor, address timelock);

    // the factory owner
    address payable public factoryOwner;
    address payable public alchemyRouter;
    address public alchemyImplementation;
    address public governorAlphaImplementation;
    address public timelockImplementation;

    constructor(
        address _alchemyImplementation,
        address _governorAlphaImplementation,
        address _timelockImplementation,
        address payable _alchemyRouter
    )
    {
        factoryOwner = msg.sender;
        alchemyImplementation = _alchemyImplementation;
        governorAlphaImplementation = _governorAlphaImplementation;
        timelockImplementation = _timelockImplementation;
        alchemyRouter =_alchemyRouter;
    }

    /**
     * @dev mints a new Alchemy Contract
     *
     * @param nftAddresses_ the nft addresses array to add to the contract
     * @param owner_ the owner of the contract
     * @param tokenIds_ the token id array of the nft to be added
     * @param totalSupply_ the total supply of the erc20
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param buyoutPrice_ the buyout price to buyout the dao
     * @param votingPeriod_ the voting period for the DAO in blocks
     * @param timelockDelay_ the timelock delay in seconds
     * @return alchemy - the address of the newly generated alchemy contract
     * governor - the address of the new governor alpha
     * timelock - the address of the new timelock
    */
    function NFTDAOMint(
        IERC721[] memory nftAddresses_,
        address owner_,
        uint256[] memory tokenIds_,
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        uint256 buyoutPrice_,
        uint256 votingPeriod_,
        uint256 timelockDelay_
    ) external returns (address alchemy, address governor, address timelock) {
        alchemy = alchemyImplementation.createClone();
        governor = governorAlphaImplementation.createClone();
        timelock = timelockImplementation.createClone();

        emit NewAlchemy(alchemy, governor, timelock);

        // transfer the nfts
        for (uint i = 0; i < nftAddresses_.length; i++) {
            nftAddresses_[i].transferFrom(msg.sender, alchemy, tokenIds_[i]);
        }

        IGovernorAlpha(governor).initialize(
            alchemy,
            timelock,
            totalSupply_,
            votingPeriod_
        );

        ITimelock(timelock).initialize(governor, timelockDelay_);

        IAlchemy(alchemy).initialize(
            nftAddresses_,
            owner_,
            tokenIds_,
            totalSupply_,
            name_,
            symbol_,
            buyoutPrice_,
            address(this),
            governor,
            timelock
        );
    }

    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) external {
        require(msg.sender == factoryOwner, "Only owner");
        factoryOwner = newOwner;
    }

    /**
     * @dev lets the owner change the address to another address
     *
     * @param newAlchemyImplementation_ the new address
    */
    function newAlchemyImplementation(address newAlchemyImplementation_) external {
        require(msg.sender == factoryOwner, "Only owner");
        alchemyImplementation = newAlchemyImplementation_;
    }

    /**
     * @dev lets the owner change the address to another address
     *
     * @param newGovernorAlphaImplementation_ the new address
    */
    function newGovernorAlphaImplementation(address newGovernorAlphaImplementation_) external {
        require(msg.sender == factoryOwner, "Only owner");
        governorAlphaImplementation = newGovernorAlphaImplementation_;
    }

    /**
     * @dev lets the owner change the address to another address
     *
     * @param newTimelockImplementation_ the new address
    */
    function newTimelockImplementation(address newTimelockImplementation_) external {
        require(msg.sender == factoryOwner, "Only owner");
        timelockImplementation = newTimelockImplementation_;
    }

    /**
     * @dev lets the owner change the address to another address
     *
     * @param newRouter the address of the new router
    */
    function newAlchemyRouter(address payable newRouter) external {
        require(msg.sender == factoryOwner, "Only owner");
        alchemyRouter = newRouter;
    }

    /**
     * @dev gets the address of the current alchemy router
     *
     * @return the address of the alchemy router
    */
    function getAlchemyRouter() public view returns (address payable) {
        return alchemyRouter;
    }
}


interface IAlchemy {
    function initialize(
        IERC721[] memory nftAddresses_,
        address owner_,
        uint256[] memory tokenIds_,
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        uint256 buyoutPrice_,
        address factoryContract,
        address governor_,
        address timelock_
    ) external;
}


interface IGovernorAlpha {
    function initialize(
        address nft_,
        address timelock_,
        uint supply_,
        uint votingPeriod_
    ) external;
}


interface ITimelock {
    function initialize(address admin_, uint delay_) external;
}
