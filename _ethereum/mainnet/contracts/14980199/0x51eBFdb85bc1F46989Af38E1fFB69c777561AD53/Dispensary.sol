// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

contract Dispensary is IERC1155Receiver {
    address public YON;
    IERC1155 public strain;
    mapping(address => mapping(uint256 => mapping(address => bool))) public hasBeenDispensed;
    constructor(address _strain, address _yon) {
        strain = IERC1155(_strain);
        YON = _yon;
    }

    modifier onlyYon() {
        require(msg.sender == YON, "not yon >:|");
        _;
    }

    function newYon(address _yon) public onlyYon {
        YON = _yon;
    }

    function setStrainForDispense(address _strain) public onlyYon {
        strain = IERC1155(_strain); 
    }

    function dispense(uint256 _bud) public {
        require(
            !hasBeenDispensed[address(strain)][_bud][msg.sender],
            "already dispensed bud :("
        );
        hasBeenDispensed[address(strain)][_bud][msg.sender] = true;
        strain.safeTransferFrom(address(this), msg.sender, _bud, 1, "");
    }

    function emptyJar(uint256 tokenId) public onlyYon {
        uint256 balance  = strain.balanceOf(address(this), tokenId);
        strain.safeTransferFrom(address(this), YON, tokenId, balance, "");
    }

    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    ) external view override returns (bytes4) {
        require(msg.sender == address(strain), "strain not accepted");
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        uint256[] calldata, /* values */
        bytes calldata /* data */
    ) external view override returns (bytes4) {
        require(msg.sender == address(strain), "strain not accepted");
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(
        bytes4 /*interfaceId*/
    ) external pure override returns (bool) {
        return false;
    }
}