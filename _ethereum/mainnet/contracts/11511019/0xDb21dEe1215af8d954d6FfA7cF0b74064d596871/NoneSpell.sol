pragma solidity ^0.5.12;

contract PauseLike {
    function delay() public returns (uint);
    function exec(address, bytes32, bytes memory, uint256) public;
    function plot(address, bytes32, bytes memory, uint256) public;
}

contract NoneDeployer {
    function deploy() external {

    }
}

contract NoneSpell {
    bool      public done;
    address   public pause;

    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;

    constructor(address pause_) public {
        pause = pause_;
        address deployer = address(new NoneDeployer());
        sig = abi.encodeWithSignature("deploy()");
        bytes32 _tag; assembly { _tag := extcodehash(deployer) }
        action = deployer;
        tag = _tag;
    }

    function schedule() external {
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        PauseLike(pause).plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        PauseLike(pause).exec(action, tag, sig, eta);
    }
}