// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Strings.sol";

import "./TheProxy.sol";
import "./CommunityList.sol";
import "./CommunityRegistry.sol";

import "./IRegistryConsumer.sol";

import "./Marketplace.sol";
import "./Splitter.sol";


import "./console.sol";

contract MarketplaceFactory is Ownable {
   function version() public view virtual returns (uint256) {
        return 20230807;
    }

    address public constant REGISTRY_ADDRESS = 0x1e8150050A7a4715aad42b905C08df76883f396F;
    IRegistryConsumer constant _registry = IRegistryConsumer(REGISTRY_ADDRESS);

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN_ROLE = keccak256("COMMUNITY_REGISTRY_ADMIN");

    string public constant MARKETPLACE_FACTORY = "MARKETPLACE_FACTORY";
    string constant COMMUNITY_LIST      = "COMMUNITY_LIST";
    //string constant GOLDEN_SPLITTER     = "GOLDEN_SPLITTER";
    string constant GOLDEN_MARKETPLACE  = "GOLDEN_MARKETPLACE";
    //string constant GALAXIS_WALLET      = "GALAXIS_WALLET";
    //string constant GALAXIS_ROYALTY_SPLIT = "GALAXIS_ROYALTY_SPLIT";


    event MarketplaceProxyDeployed(address _address);

    constructor() {
        require(_registry.getRegistryAddress(GOLDEN_MARKETPLACE) != address(0),"MarketplaceFactory: GOLDEN MARKETPLACE not deployed");
    }

    function deploy(
        uint32 _communityId,
        uint32 _tokenNum
    ) external {
        // validate this contract is the current version to be used, else fail
        address factoryAddress = _registry.getRegistryAddress(MARKETPLACE_FACTORY);
        require(factoryAddress == address(this), "MarketplaceFactory: Not current project factory");

        CommunityRegistry myCommunityRegistry = _getCommunityRegistry(_communityId);
        address tokenContractAddress = myCommunityRegistry.getRegistryAddress(
            string.concat("TOKEN_", Strings.toString(_tokenNum))
        );

        require(tokenContractAddress != address(0), "MarketplaceFactory: Invalid token ID");
        address lookup = _registry.getRegistryAddress("LOOKUP");
        // instantiate marketplace proxy
        // instantiate marketplace proxy
        Marketplace marketplaceProxy = Marketplace(address(new TheProxy(GOLDEN_MARKETPLACE,lookup)));
        marketplaceProxy.init(
            tokenContractAddress,
            _communityId,
            msg.sender // deployer account becomes owner  of marketplace
        );
        emit MarketplaceProxyDeployed(address(marketplaceProxy));

        if(!myCommunityRegistry.hasRole(COMMUNITY_REGISTRY_ADMIN_ROLE, address(this))) {
            myCommunityRegistry.grantRole(COMMUNITY_REGISTRY_ADMIN_ROLE, address(this));
        }

        // set marketplace address in community's registry
        myCommunityRegistry.setRegistryAddress(
            string(abi.encodePacked("MARKETPLACE_", Strings.toString(_tokenNum))),
            address(marketplaceProxy)
        );
    }

    function _getCommunityRegistry(uint32 _communityId) internal view returns (CommunityRegistry) {
        CommunityList communityList = CommunityList(_registry.getRegistryAddress(COMMUNITY_LIST));
        (, address crAddr, ) = communityList.communities(_communityId);
        require(crAddr != address(0), "MarketplaceFactory: Invalid community ID");
        return CommunityRegistry(crAddr);
    } 

}
