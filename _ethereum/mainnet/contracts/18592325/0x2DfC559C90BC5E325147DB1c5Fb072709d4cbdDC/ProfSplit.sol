// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
}

interface IGovernorAlpha {
    function state(uint256 proposalId) external view returns (ProposalState);
}

contract ProfSplit {
    IGovernorAlpha governor = IGovernorAlpha(0x95129751769f99CC39824a0793eF4933DD8Bb74B);
    address public refundAddress;
    address public owner;
    bool public init;
    uint public constant EXPIRED = 1700820415; // approx Friday 24 November 2023 GMT

    constructor() {
        owner = msg.sender;
    }

    /// (from NDX pool) 6k + 1.8k = 7.8k
    /// (high slippage so half) ~($5000 NFT, $6000 OMG )* 0.5 = ~$5500
    /// ~ $20k SUSHI,~$22k ZRX, ~$36k DAI 
    /// Total = $91300
    function split() external payable { // split profit
        require(!init, "already paid");
        refundAddress = msg.sender;
        init = true;
    }

    function collect() external {
        require(governor.state(24) == ProposalState.Executed, 'Not executed');
        payable(owner).transfer(address(this).balance);
    }

    function refund() external {
        require(block.timestamp > EXPIRED, 'not expired'); // in case proposal failed
        payable(refundAddress).transfer(address(this).balance);
    }

    receive() external payable {}
}

/**
//Test File
import "./Test.sol";
import "./console.sol";
import "./ProfSplit.sol";
import "./IERC20.sol";

interface IGovernorTest is IGovernorAlpha {
    function queue(uint256 proposalId) external;
    function execute(uint256 proposalId) external payable;
}

contract ProfSplitTest is Test {
    IGovernorTest governor = IGovernorTest(0x95129751769f99CC39824a0793eF4933DD8Bb74B);
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address them = 0xdf0b30404Ecbf0Fd6905D7722f76B0a9D3DA6E14;
    ProfSplit splitter;
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        splitter = new ProfSplit();
    }

    function testSplitProf() public {
        _split();
        vm.expectRevert();
        splitter.refund();
    }

    function testGetSplitProf() public {
        _split();
        vm.roll(block.number + 17800);
        governor.queue(24);
        vm.warp(block.timestamp + 172801);
        governor.execute(24);
        console.log("Them DAI: %d", dai.balanceOf(them));
        splitter.collect();
        console.log("My ETH: %d", address(this).balance);
    }

    function testRefund() public {
        _split();
        vm.warp(block.timestamp + 604800);
        splitter.refund();
        console.log("Them ETH: %d", them.balance);
    }

    function _split() internal {
        vm.deal(them, 50 ether);
        vm.prank(them);
        splitter.split{value: 18.26 ether}();
    }

    receive() external payable {}
}
 */