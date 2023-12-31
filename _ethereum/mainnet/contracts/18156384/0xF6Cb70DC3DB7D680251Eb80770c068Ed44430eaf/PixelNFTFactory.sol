// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./PixelNFTMinter.sol";
import "./PixelNFT.sol";

contract PixelNFTFactory is AccessControl {

    bytes32 constant public ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address public vrfAddress;
    event RaffleCreated(address owner, uint256 time, address collectionAddress, address minterAddress);

    constructor(
        address _vrf
    ){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        vrfAddress = _vrf;
    }

    function createRaffle(
        address _owner,
        string calldata _name,
        string calldata _symbol,
        uint256 _maxSupply,
        uint256 _unitPrice,
        uint8 _maxPerUser,
        uint8 _adminFeePercent,
        uint256 _preSaleStartTime,
        uint256 _publicSaleStartTime
        ) public onlyRole(ADMIN_ROLE) returns(
        address collection,
        address minter
    ){
        collection = address(new PixelNFT(
            _owner,
            _name,
            _symbol,
            _maxSupply
        ));
        minter = address(new PixelNFTMinter(
            _owner,
            collection,
            vrfAddress,
            _unitPrice,
            _maxPerUser,
            _adminFeePercent,
            _preSaleStartTime,
            _publicSaleStartTime
        ));
        emit RaffleCreated(_owner, block.timestamp, collection, minter);
    }

    function updateVRFAddress(address _vrf) public onlyRole(ADMIN_ROLE){
        vrfAddress = _vrf;
    }

    function adminWithdraw(uint256 amount, address _to, address _token) public onlyRole(ADMIN_ROLE) {
        require(_to != address(0));
        if(_token == address(0)){
          payable(_to).transfer(amount);
        } else {
          IERC20(_token).transfer(_to, amount);
        }
    }
}
