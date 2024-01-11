pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./Ownable.sol";

contract Airdropper is Ownable {
    mapping(address => bool) public allowedAirdropper;
    event AirdropSent(address _to, uint _tokenId);

    constructor(){
        allowedAirdropper[msg.sender] = true;
    }

    function updateAllowed(address _address, bool _state) external onlyOwner {
        allowedAirdropper[_address] = _state;
    }

    function Airdrop(
        IERC721 _assets,
        uint[] calldata tokenIds,
        address[] calldata recipients
    ) external {
        require(allowedAirdropper[msg.sender], "you are not allowed to use this contract");
        require(tokenIds.length == recipients.length, "must be equal");
        for (uint i = 0; i < tokenIds.length; i++) {
            _assets.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
            emit AirdropSent(recipients[i], tokenIds[i]);
        }
    }
}