// SPDX-License-Identifier: MIT
// A Hypnoduckz Project - BREAD IS A UTILITY TOKEN FOR THE HYPNODUCKZ ECOSYSTEM.
// $BREAD is NOT an investment and has NO economic value.

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract Bread is ERC20, Ownable {
    using SafeMath for uint256;

    bool claimPaused = false;

    address private signer;

    mapping(address => bool) public allowedMinter;
    mapping(address => bool) public allowedBurner;
    mapping(address => uint256) public voucherId;

    constructor() ERC20("Bread", "BREAD") {
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function claim(uint256 _voucherId, address _address, uint256 _amount, bytes calldata _voucher) external {
        require(!claimPaused, "Claiming has been paused");
        require(voucherId[_address] == _voucherId, "Incorrect voucherId");
        require(msg.sender == _address, "Not your voucher");

        bytes32 hash = keccak256(
            abi.encodePacked(_voucherId, _address, _amount)
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        voucherId[_address]++;
        _mint(_address, _amount);
    }

    function redeem(address _address, uint256 _amount) external {
        require(!claimPaused, "Claiming has been paused");
        require(msg.sender == _address, "Bad Address");
        _burn(_address, _amount);
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function mint(address user, uint256 amount) external {
        require(allowedMinter[msg.sender], "Address does not have permission to mint");
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) external {
        require(allowedBurner[msg.sender], "Address does not have permission to burn");
        _burn(user, amount);
    }

    function setAllowedMinter(address _address, bool _access) public onlyOwner {
        allowedMinter[_address] = _access;
    }

    function setAllowedBurner(address _address, bool _access) public onlyOwner {
        allowedBurner[_address] = _access;
    }

    function toggleClaiming() public onlyOwner {
        claimPaused = !claimPaused;
    }
}