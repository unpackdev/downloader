// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Testable.sol";

import "./TellerV2.sol";
import "./MarketRegistry.sol";
import "./ReputationManager.sol";

import "./TellerV2Storage.sol";

import "./IMarketRegistry.sol";
import "./IReputationManager.sol";

import "./TellerAS.sol";

import "./WethMock.sol";
import "./IWETH.sol";

contract TellerV2_Test is Testable, TellerV2 {
    User private marketOwner;
    User private borrower;
    User private lender;

    WethMock wethMock;

    constructor() TellerV2(address(address(0))) {}

    function setup_beforeAll() public {
        wethMock = new WethMock();

        marketOwner = new User(this, wethMock);
        borrower = new User(this, wethMock);
        lender = new User(this, wethMock);

        lenderCommitmentForwarder = address(0);
        marketRegistry = IMarketRegistry(new MarketRegistry());
        reputationManager = IReputationManager(new ReputationManager());
    }
}

contract User {
    TellerV2 public immutable tellerV2;
    WethMock public immutable wethMock;

    constructor(TellerV2 _tellerV2, WethMock _wethMock) {
        tellerV2 = _tellerV2;
        wethMock = _wethMock;
    }

    function depositToWeth(uint256 amount) public {
        wethMock.deposit{ value: amount }();
    }
}
