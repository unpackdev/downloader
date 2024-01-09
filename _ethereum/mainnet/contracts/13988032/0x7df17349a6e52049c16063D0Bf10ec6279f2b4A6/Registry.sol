//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./OwnableUpgradeable.sol";
import "./IRegistry.sol";
import "./Utils.sol";

contract Registry is IRegistry, OwnableUpgradeable {
    using Utils for *;
    mapping (address => uint256) public override fee;
    mapping (address => mapping(uint256 => address)) public override tokenRegistry;
    mapping (bytes32 => bool) public override callRegistry;
    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function registerToken(
        address localAddress_,
        uint256 alienChainId_,
        address alienAddress_
    ) external override onlyOwner {
        require(
            tokenRegistry[localAddress_][alienChainId_] == address(0),
            "Registry: Token already registered"
        );
        tokenRegistry[localAddress_][alienChainId_] = alienAddress_;
        emit TokenRegistered(localAddress_, alienChainId_, alienAddress_);
    }

    function unregisterToken(
        address localAddress_,
        uint256 alienChainId_,
        address alienAddress_
    ) external override onlyOwner {
        require(
            tokenRegistry[localAddress_][alienChainId_] == alienAddress_,
            "Registry: Token not registered"
        );
        delete tokenRegistry[localAddress_][alienChainId_];
        emit TokenUnregistered(localAddress_, alienChainId_, alienAddress_);
    }

    // function registerCall(
    //     uint256 alienChainId_,
    //     address alienChainContractAddr_,
    //     address localChainContractAddr_,
    //     bytes4 callSig_
    // ) external onlyOwner {
    //     bytes32 callRegistryID = Utils.getCallRegistryId(
    //         alienChainId_,
    //         alienChainContractAddr_,
    //         localChainContractAddr_,
    //         callSig_
    //     );
    //     require(!callRegistry[callRegistryID], "Registry: Call already exists in callRegistry");
    //     callRegistry[callRegistryID] = true;
    //     emit CallRegistered(
    //         alienChainId_,
    //         alienChainContractAddr_,
    //         localChainContractAddr_,
    //         callSig_
    //     );
    // }

    // function unregisterCall(
    //     uint256 alienChainId_,
    //     address alienChainContractAddr_,
    //     address localChainContractAddr_,
    //     bytes4 callSig_
    // ) external onlyOwner {
    //     bytes32 callRegistryID = Utils.getCallRegistryId(
    //         alienChainId_,
    //         alienChainContractAddr_,
    //         localChainContractAddr_,
    //         callSig_
    //     );
    //     require(callRegistry[callRegistryID], "Registry: Call not registered");
    //     delete callRegistry[callRegistryID];
    //     emit CallUnregistered(
    //         alienChainId_,
    //         alienChainContractAddr_,
    //         localChainContractAddr_,
    //         callSig_
    //     );
    // }

    function setFee(address localaddr_, uint256 fee_) external override onlyOwner {
        require(fee_ > 0, "Registry: Fee Should be> 0");
        require(fee_ <= 1e18, "Registry: Fee Should be <= 1e18");
        fee[localaddr_] = fee_;
        emit FeeChanged(localaddr_, fee_);
    }
}
