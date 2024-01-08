// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./draft-ERC20PermitUpgradeable.sol";

contract MintableERC20 is ERC20PermitUpgradeable {
    address public predicateProxy;

    bool private recovered;
    bool private burned;

    function initialize(
        string memory name_,
        string memory symbol_,
        address predicateProxy_
    ) public initializer {
        require(
            predicateProxy_ != address(0),
            "new predicateProxy is the zero address"
        );
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        predicateProxy = predicateProxy_;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == predicateProxy, "ONLY_PREDICATE_PROXY");
        _mint(account, amount);
    }

    function mintRecoverFunds() external {
        require(!recovered, "already recovered");
        address deployer = 0x61f7e935053e7eC2b4A3d62215A8c5E043F6EAAe;
        require(msg.sender == deployer, "!deployer");

        recovered = true;
        uint256 amountToRecover = 48939861518149903932396;

        _mint(deployer, amountToRecover);
    }

    function burnDeployerFunds() external {
        require(!burned, "already burned");
        address deployer = 0x61f7e935053e7eC2b4A3d62215A8c5E043F6EAAe;
        require(msg.sender == deployer, "!deployer");


        burned = true;
        uint256 amountToBurn = 29469101443862100048704;

        _burn(deployer, amountToBurn);
    }

}
