//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

import "./IRandomizer.sol";
import "./AdminableUpgradeable.sol";
import "./IGP.sol";
import "./IWnD.sol";
import "./ISacrificialAlter.sol";
import "./IConsumables.sol";
import "./IMessageHandler.sol";
import "./IRootTunnel.sol";
import "./IRiftRoot.sol";
import "./IOldTrainingGrounds.sol";

abstract contract RiftRootState is Initializable, IRiftRoot, IMessageHandler, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, AdminableUpgradeable {

    IGP public gp;
    IWnDRoot public wnd;
    ISacrificialAlter public sacrificialAlter;
    IConsumables public consumables;
    IRootTunnel public rootTunnel;
    IOldTrainingGrounds public oldTrainingGrounds;

    EnumerableSetUpgradeable.AddressSet internal addressesStaked;
    mapping(address => uint256) public addressToGPStaked;
    uint256 public amountNeededToOpenPortal;
    uint256 public amountCurrentlyStaked;

    function __RiftRootState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();

        amountNeededToOpenPortal = 42_000_000 ether;
    }
}