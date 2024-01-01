// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./Strings.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./IERC20.sol";

contract SoulProfileWithdrawRel is Ownable, Pausable {
    using Strings for uint256;
    using Strings for address;

    using ECDSA for bytes;
    using ECDSA for bytes32;

    string public name;
    mapping(address => bool) public minters;
    mapping(address => uint256) public totalWithdrawn;

    IERC20 public REL;

    event SetMinter(address indexed addr, bool isMinter);
    event Withdraw(address indexed addr, uint256 value);

    modifier onlyMinter() {
        require(minters[msg.sender], "RelationWithdraw: must be minter");
        _;
    }

    constructor(address minter, string memory _name, address _rel) {
        setMinter(msg.sender, true);
        setMinter(minter, true);
        name = _name;
        REL = IERC20(_rel);
    }

    function setMinter(address addr, bool _isMinter) public onlyOwner {
        minters[addr] = _isMinter;
        emit SetMinter(addr, _isMinter);
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {}


    function withdraw(address addr) public onlyOwner {
        // payable(addr).transfer(address(this).balance);
        REL.transfer(addr, REL.balanceOf(address(this)));
    }

    function withdraw(uint256 deadline, uint256 _withdrawAmount, uint256 _totalWithdrawnAmount, bytes memory signature) public whenNotPaused {
        require(totalWithdrawn[msg.sender] + _withdrawAmount == _totalWithdrawnAmount, "Please don't initiate a withdrawal request repeatedly.");
        require(minters[recoverAddress(msg.sender, deadline, _withdrawAmount, _totalWithdrawnAmount, signature)], "Invalid signature, please retry.");
        totalWithdrawn[msg.sender] = _totalWithdrawnAmount;
        REL.transfer(msg.sender, _withdrawAmount);
        emit Withdraw(msg.sender, _withdrawAmount);
    }


    function recoverAddress(address caller, uint256 deadline, uint256 _withdrawAmount, uint256 _totalWithdrawnAmount, bytes memory signature) internal view returns (address) {
        require(deadline > block.timestamp, "Signature expired, please retry.");
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                caller,
                deadline,
                _withdrawAmount,
                _totalWithdrawnAmount
            )
        ).toEthSignedMessageHash();
        return hash.recover(signature);
    }
}