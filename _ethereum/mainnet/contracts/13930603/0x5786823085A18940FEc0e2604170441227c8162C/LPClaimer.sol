// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract LPClaimer{

    uint256 public constant MAX_SUPPLY = uint248(1111111 ether);
    mapping(address => bool) private _minted;

    IERC20 private TWO; //mainnet 0xB711Bac062F74c5C6d4a2cb55639a270881a12EE

    constructor(address _signer, address _two) {
        cSigner = _signer;
        TWO = IERC20(_two);
    }

    address public immutable cSigner;

     function minted(address account) public view returns (bool) {
        return _minted[account];
    }

    function claim(uint248 amount, uint8 v, bytes32 r, bytes32 s) external {
        require(minted(msg.sender) == false, "LP Reward: Already Claimed");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        amount,msg.sender
                    )
                )
            )
        );
        require(ecrecover(digest, v, r, s) == cSigner, "LP Reward: Invalid signer");
        _minted[msg.sender] = true;
        TWO.transfer(msg.sender, amount);
    }
}