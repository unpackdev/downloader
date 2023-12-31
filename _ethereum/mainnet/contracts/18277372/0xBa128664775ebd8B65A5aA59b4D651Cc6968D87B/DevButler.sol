pragma solidity >= 0.8.21;

contract DevButler {

    address immutable private owner;
    uint8 private version;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller must be owner");
        _;
    }

    function getVersion() public view virtual returns (uint8) {
        return version;
    }

    function setVersion(uint8 _version) public virtual onlyOwner {
        version = _version;
    }

}