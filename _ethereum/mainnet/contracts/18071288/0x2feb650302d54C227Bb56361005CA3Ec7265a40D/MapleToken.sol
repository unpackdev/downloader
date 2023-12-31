// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC20Proxied.sol";

import "./Interfaces.sol";
import { IMapleToken }  from "./interfaces/IMapleToken.sol";

contract MapleToken is IMapleToken, ERC20Proxied {

    bytes32 internal constant GLOBALS_SLOT        = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    mapping(address => bool) public isModule;

    modifier onlyGovernor {
        require(msg.sender == governor(), "MT:NOT_GOVERNOR");
        _;
    }

    modifier onlyScheduled(bytes32 functionId_) {
        IGlobalsLike globals_         = IGlobalsLike(globals());
        bool         isScheduledCall_ = globals_.isValidScheduledCall(msg.sender, address(this), functionId_, msg.data);

        require(isScheduledCall_, "MT:NOT_SCHEDULED");

        globals_.unscheduleCall(msg.sender, functionId_, msg.data);

        _;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function addModule(address module_) external onlyGovernor onlyScheduled("MT:ADD_MODULE") {
        isModule[module_] = true;

        emit ModuleAdded(module_);
    }

    function removeModule(address module_) external onlyGovernor onlyScheduled("MT:REMOVE_MODULE") {
        delete isModule[module_];

        emit ModuleRemoved(module_);
    }

    function burn(address from_, uint256 amount_) external {
        require(isModule[msg.sender], "MT:B:NOT_MODULE");
        _burn(from_, amount_);

        emit Burn(from_, amount_);
    }

    function mint(address to_, uint256 amount_) external  {
        require(isModule[msg.sender], "MT:M:NOT_MODULE");
        _mint(to_, amount_);

        emit Mint(to_, amount_);
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function implementation() external view returns (address implementation_) {
        implementation_ = _getAddress(IMPLEMENTATION_SLOT);
    }

    function governor() public view returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function globals() public view returns (address globals_) {
        globals_ = _getAddress(GLOBALS_SLOT);
    }

    /**************************************************************************************************************************************/
    /*** Utility Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

    function _getAddress(bytes32 slot_) internal view returns (address value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

}
