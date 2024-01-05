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

    // the Alchemy governance token
    IERC20 public alch;

    // the factory owner
    address payable public factoryOwner;
    address payable public alchemyRouter;
    address public alchemyImplementation;
    address public governorAlphaImplementation;
    address public timelockImplementation;

    constructor(
        IERC20 _alch,
        address _alchemyImplementation,
        address _governorAlphaImplementation,
        address _timelockImplementation,
        address payable _alchemyRouter
    )
    {
        alch = _alch;
        factoryOwner = msg.sender;
        alchemyImplementation = _alchemyImplementation;
        governorAlphaImplementation = _governorAlphaImplementation;
        timelockImplementation = _timelockImplementation;
        alchemyRouter =_alchemyRouter;
    }

    /**
     * @dev distributes the ALCH token supply
     *
     * @param amount the amount to distribute
    */
    function distributeAlch(uint amount) internal {
        if (alch.balanceOf(address(this)) >= amount) {
            alch.transfer(msg.sender, amount);
        }
    }

    /**
     * @dev mints a new Alchemy Contract
     *
     * @param nftAddress_ the initial nft address to add to the contract
     * @param owner_ the owner of the contract
     * @param tokenId_ the token id of the nft to be added
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
        IERC721 nftAddress_,
        address owner_,
        uint256 tokenId_,
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        uint256 buyoutPrice_,
        uint256 votingPeriod_,
        uint256 timelockDelay_
    ) public returns (address alchemy, address governor, address timelock) {
        alchemy = alchemyImplementation.createClone();
        governor = governorAlphaImplementation.createClone();
        timelock = timelockImplementation.createClone();

        nftAddress_.transferFrom(msg.sender, alchemy, tokenId_);

        IGovernorAlpha(governor).initialize(
            alchemy,
            timelock,
            totalSupply_,
            votingPeriod_
        );

        ITimelock(timelock).initialize(governor, timelockDelay_);

        IAlchemy(alchemy).initialize(
            nftAddress_,
            owner_,
            tokenId_,
            totalSupply_,
            name_,
            symbol_,
            buyoutPrice_,
            address(this),
            governor,
            timelock
        );

        // distribute gov token
        distributeAlch(100 * 10 ** 18);

        emit NewAlchemy(alchemy, governor, timelock);
    }

    /**
     * @dev lets the owner transfer alch token to another address
     *
     * @param dst the address to send the tokens
     * @param amount the token amount
    */
    function transferAlch(address dst, uint256 amount) external {
        require(msg.sender == factoryOwner, "Only owner");
        alch.transfer(dst, amount);
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
        IERC721 nftAddress_,
        address owner_,
        uint256 tokenId_,
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