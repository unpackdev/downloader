// Verified using https://dapp.tools

// hevm: flattened sources of src/root.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.7.6;

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/root.sol
/* pragma solidity >=0.7.6; */

/* import "./auth.sol"; */

interface AuthLike_4 {
    function rely(address) external;
    function deny(address) external;
}

interface DependLike_4 {
    function depend(bytes32, address) external;
}

interface BorrowerDeployerLike {
    function feed() external returns (address);
    function shelf() external returns (address);
    function title() external returns (address);
}

interface LenderDeployerLike_2 {
    function assessor() external returns (address);
    function reserve() external returns (address);
    function poolAdmin() external returns (address);
}

interface AdapterDeployerLike_1 {
    function mgr() external returns (address);
    function wireAdapter() external;
}

interface PoolAdminLike_3 {
    function setAdminLevel(address, uint) external;
}

contract TinlakeRoot is Auth {
    BorrowerDeployerLike public borrowerDeployer;
    LenderDeployerLike_2 public  lenderDeployer;
    AdapterDeployerLike_1 public  adapterDeployer;

    bool public             deployed;
    address public          deployUsr;
    address public immutable governance;

    address public          oracle;
    address[] public        level1Admins;
    address public          level3Admin;

    constructor (address deployUsr_, address governance_) {
        deployUsr = deployUsr_;
        governance = governance_;
        wards[governance_] = 1;
        emit Rely(governance_);
    }

    // --- Prepare ---
    // Sets the two deployer dependencies. This needs to be called by the deployUsr
    function prepare(address lender_, address borrower_, address adapter_, address oracle_, address[] memory level1Admins_, address level3Admin_) public {
        require(deployUsr == msg.sender);

        borrowerDeployer = BorrowerDeployerLike(borrower_);
        lenderDeployer = LenderDeployerLike_2(lender_);
        if (adapter_ != address(0)) adapterDeployer = AdapterDeployerLike_1(adapter_);
        oracle = oracle_;
        level1Admins = level1Admins_;
        level3Admin = level3Admin_;

        deployUsr = address(0); // disallow the deploy user to call this more than once.
    }

    function prepare(address lender_, address borrower_, address adapter_) public {
        prepare(lender_, borrower_, adapter_, address(0), new address[](0), address(0));
    }

    function prepare(address lender_, address borrower_) public {
        prepare(lender_, borrower_, address(0), address(0), new address[](0), address(0));
    }

    // --- Deploy ---
    // After going through the deploy process on the lender and borrower method, this method is called to connect
    // lender and borrower contracts.
    function deploy() public {
        require(address(borrowerDeployer) != address(0) && address(lenderDeployer) != address(0) && deployed == false);
        deployed = true;
        address reserve_ = lenderDeployer.reserve();
        address shelf_ = borrowerDeployer.shelf();
        address assessor_ = lenderDeployer.assessor();

        // Borrower depends
        DependLike_4(borrowerDeployer.shelf()).depend("reserve", reserve_);
        DependLike_4(borrowerDeployer.shelf()).depend("assessor", assessor_);

        // Lender depends
        address navFeed = borrowerDeployer.feed();

        // shelf can deposit and payout from reserve
        AuthLike_4(reserve_).rely(shelf_);
        DependLike_4(assessor_).depend("navFeed", navFeed);


        // Lender wards
        if (oracle != address(0)) AuthLike_4(navFeed).rely(oracle);

        DependLike_4(lenderDeployer.poolAdmin()).depend("navFeed", navFeed);
        AuthLike_4(navFeed).rely(lenderDeployer.poolAdmin());

        PoolAdminLike_3 poolAdmin = PoolAdminLike_3(lenderDeployer.poolAdmin());
        poolAdmin.setAdminLevel(governance, 3);
        poolAdmin.setAdminLevel(level3Admin, 3);

        for (uint i = 0; i < level1Admins.length; i++) {
            poolAdmin.setAdminLevel(level1Admins[i], 1);
        }
    }

    // --- Governance Functions ---
    // `relyContract` & `denyContract` can be called by any ward on the TinlakeRoot
    // contract to make an arbitrary address a ward on any contract the TinlakeRoot
    // is a ward on.
    function relyContract(address target, address usr) public auth {
        AuthLike_4(target).rely(usr);
    }

    function denyContract(address target, address usr) public auth {
        AuthLike_4(target).deny(usr);
    }

}
