pragma solidity 0.5.11;

contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface NTSCD {
    function mint(address customerAddress, uint256 value) external;
    function boss3() external view returns(address);
}

contract Distribution is Ownable {

    NTSCD public target;

    constructor(address targetAddr, address initialOwner) public Ownable(initialOwner) {
        require(targetAddr != address(0));

        target = NTSCD(targetAddr);
    }

    function setTarget(address newTarget) public onlyOwner {
        require(newTarget != address(0));

        target = NTSCD(newTarget);
    }

    function distribute(address[] memory holders, uint256[] memory balances, uint256 startIndex) public onlyOwner returns(uint256) {
        require(address(this) == target.boss3(), 'Contract is not the boss3 at target');
        require(holders.length == balances.length, 'Arrays are not equal');

        uint256 i;
        for (i = startIndex; i < holders.length; i++) {
            require(holders[i] != address(0), 'Zero address was met');
            require(balances[i] > 0, 'Zero balance was met');

            target.mint(holders[i], balances[i]);

            if (gasleft() < 100000) {
                break;
            }
        }

        return i;
    }

}